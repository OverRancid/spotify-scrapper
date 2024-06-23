import 'dart:io';
import 'dart:convert';
import 'package:spotify/song.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:spotify/database_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class PlaylistScreen extends StatefulWidget {
  final String playlistName;
  final List<Song> tracks;

  const PlaylistScreen({
    super.key,
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
      } else {
        throw json.decode(response.body)['error']['message'];
      }
    } catch (e) {
      // print('Error in youtubeAPI: $e');
      rethrow;
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
      // print('Error in ytExplode: $e');
      rethrow;
    }
    setState(() {
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
              style: TextStyle(color: Colors.white),
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
          return ListTile(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(track.name),
                SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(
                      track.artists.join(', '),
                      maxLines: 1,
                      style: TextStyle(
                        color:
                            Colors.grey[600], // Lighter color for artist names
                        fontSize: 12.0, // Smaller font size for artist names
                      ),
                    )),
              ],
            ),
            trailing: isDownloaded
                ? const Icon(Icons.check, color: Colors.green)
                : IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () => _downloadSong(track),
                  ),
          );
        },
      ),
    );
  }
}
