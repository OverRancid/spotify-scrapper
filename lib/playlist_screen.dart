import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:spotify/song.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class PlaylistScreen extends StatefulWidget {
  final String playlistName;
  final List<Song> tracks;
  final List<Song> downloadedSongs;

  PlaylistScreen({
    required this.playlistName,
    required this.tracks,
    required this.downloadedSongs,
  });

  @override
  _PlaylistScreenState createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  Set<String> downloadedTrackIds = {};
  static String ytKey = dotenv.env['youtube_key']!;
  final String _baseURL = 'www.googleapis.com';
  String token = '';

  @override
  void initState() {
    super.initState();
    // Initialize downloadedTrackIds with already downloaded songs
    downloadedTrackIds =
        widget.downloadedSongs.map((track) => track.name).toSet();
  }

  Future _downloadSong(Song track) async {
    String videoID = '';
    try {
      final String q = '${track.name} ${track.artists.first}';
      final Map<String, String> parameters = {
        'part': 'snippet',
        'q': q,
        'key': ytKey
      };

      Uri uri = Uri.https(_baseURL, '/youtube/v3/search', parameters);

      var headers = {
        HttpHeaders.contentTypeHeader: 'application/json',
      };
      var response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        videoID = data['items'][0]['id']['videoId'];
        print(videoID);
      } else {
        throw json.decode(response.body)['error']['message'];
      }
    } catch (e) {
      print('Error in youtubeAPI: $e');
      throw e;
    }
    try {
      var ytExplode = YoutubeExplode();
      // var video = await ytExplode.videos.get(videoID);
      var manifest = await ytExplode.videos.streamsClient.getManifest(videoID);
      var streamInfo = manifest.audioOnly.withHighestBitrate();
      var audioStream = ytExplode.videos.streamsClient.get(streamInfo);

      print("success");

      //implement file saving logic here
      //  await stream.pipe(audioStream);

      ytExplode.close();
    } catch (e) {
      print('Error in ytExplode: $e');
      throw e;
    }
    setState(() {
      downloadedTrackIds.add(track.name);
      widget.downloadedSongs.add(track);
    });
  }

  Future _downloadAllSongs() async {
    setState(() {
      for (var track in widget.tracks) {
        if (!downloadedTrackIds.contains(track.name)) {
          _downloadSong(track);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    dotenv.load(fileName: '.env');
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlistName),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadAllSongs,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: widget.tracks.length,
        itemBuilder: (context, index) {
          final track = widget.tracks[index];
          final isDownloaded = downloadedTrackIds.contains(track.name);
          return ListTile(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(track.name),
                Text(
                  track.artists.join(', '),
                  style: TextStyle(
                    color: Colors.grey[600], // Lighter color for artist names
                    fontSize: 14.0, // Smaller font size for artist names
                  ),
                ),
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
