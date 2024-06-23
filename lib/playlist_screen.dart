import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:spotify/song.dart';
import 'package:spotify/database_helper.dart';

class PlaylistScreen extends StatefulWidget {
  final String playlistName;
  final List<Song> tracks;

  PlaylistScreen({
    required this.playlistName,
    required this.tracks,
  });

  @override
  _PlaylistScreenState createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  Set<String> downloadedTrackIds = {};
  List<Song> downloadedSongs = [];
  static String ytKey = dotenv.env['youtube_key']!;
  final String _baseURL = 'www.googleapis.com';
  Map<String, bool> downloadStatus = {}; // Track download status for each song

  @override
  void initState() {
    super.initState();
    _loadDownloadedSongs();
  }

  Future<void> _loadDownloadedSongs() async {
    final dbHelper = DatabaseHelper();
    final songs = await dbHelper.getSongs();
    setState(() {
      downloadedSongs = songs;
      downloadedTrackIds = songs.map((track) => _createSongId(track)).toSet();
    });
  }

  String _createSongId(Song song) {
    return '${song.name}_${song.artists.join(', ')}';
  }

  Future<void> _downloadSong(Song track) async {
    setState(() {
      downloadStatus[_createSongId(track)] = true; // Set download in progress
    });

    try {
      final String q = '${track.name} ${track.artists.first}';
      final Map<String, String> parameters = {
        'part': 'snippet',
        'q': q,
        'key': ytKey,
      };

      Uri uri = Uri.https(_baseURL, '/youtube/v3/search', parameters);

      var headers = {
        HttpHeaders.contentTypeHeader: 'application/json',
      };
      var response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        track.ytID = data['items'][0]['id']['videoId'];
        // print(track.ytID);
      } else {
        throw json.decode(response.body)['error']['message'];
      }
    } catch (e) {
      print('Error in youtubeAPI: $e');
      throw e;
    }

    try {
      var ytExplode = YoutubeExplode();
      var manifest =
          await ytExplode.videos.streamsClient.getManifest(track.ytID);
      var streamInfo = manifest.audioOnly.withHighestBitrate();
      var audioStream = ytExplode.videos.streamsClient.get(streamInfo);

      final directory = await getApplicationDocumentsDirectory();
      final filePath = path.join(directory.path, _createSongId(track) + '.mp3');
      final file = File(filePath);
      await file.create(recursive: true);
      final fileSink = file.openWrite();

      await audioStream.pipe(fileSink);
      await fileSink.flush();
      await fileSink.close();

      ytExplode.close();

      // Save song data to database
      final dbHelper = DatabaseHelper();
      await dbHelper.insertSong(track);
    } catch (e) {
      print('Error in ytExplode: $e');
      throw e;
    }

    setState(() {
      downloadStatus[_createSongId(track)] = false; // Set download complete
      downloadedTrackIds.add(_createSongId(track));
      downloadedSongs.add(track);
    });
  }

  Future<void> _downloadAllSongs() async {
    for (var track in widget.tracks) {
      if (!downloadedTrackIds.contains(_createSongId(track))) {
        await _downloadSong(track);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    dotenv.load(fileName: '.env');
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlistName),
        actions: [
          TextButton(
            onPressed: _downloadAllSongs,
            child: const Text(
              'Download All',
              //style: TextStyle(color: ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: widget.tracks.length,
        itemBuilder: (context, index) {
          final track = widget.tracks[index];
          final isDownloaded =
              downloadedTrackIds.contains(_createSongId(track));
          final bool isDownloading =
              downloadStatus[_createSongId(track)] ?? false;

          return ListTile(
            leading: Image(
              image: Image.network(track.image).image,
              height: 50,
              width: 50,
            ),
            title: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.name,
                    maxLines: 1,
                  ),
                  Text(
                    track.artists.join(', '),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14.0,
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            trailing: isDownloaded
                ? const Icon(Icons.check, color: Colors.green)
                : isDownloading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator())
                    : IconButton(
                        icon: Icon(Icons.download),
                        onPressed: () => _downloadSong(track),
                      ),
          );
        },
      ),
    );
  }
}
