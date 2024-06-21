// playlist_screen.dart

import 'package:flutter/material.dart';

class PlaylistScreen extends StatefulWidget {
  final String playlistName;
  final List<Map<String, String>> tracks;
  final List<Map<String, String>> downloadedSongs;

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

  @override
  void initState() {
    super.initState();
    // Initialize downloadedTrackIds with already downloaded songs
    downloadedTrackIds = widget.downloadedSongs.map((track) => track['trackName']!).toSet();
  }

  void _downloadSong(Map<String, String> track) {
    setState(() {
      downloadedTrackIds.add(track['trackName']!);
      widget.downloadedSongs.add(track);
    });
  }

  void _downloadAllSongs() {
    setState(() {
      for (var track in widget.tracks) {
        if (!downloadedTrackIds.contains(track['trackName']!)) {
          downloadedTrackIds.add(track['trackName']!);
          widget.downloadedSongs.add(track);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlistName),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: _downloadAllSongs,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: widget.tracks.length,
        itemBuilder: (context, index) {
          final track = widget.tracks[index];
          final isDownloaded = downloadedTrackIds.contains(track['trackName']);
          return ListTile(
            title: Text('${track['trackName']} by ${track['artistName']}'),
            trailing: isDownloaded
                ? Icon(Icons.check, color: Colors.green)
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
