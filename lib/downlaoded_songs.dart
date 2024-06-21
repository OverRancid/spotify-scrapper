// downloaded_songs_screen.dart

import 'package:flutter/material.dart';

class DownloadedSongsScreen extends StatefulWidget {
  final List<Map<String, String>> downloadedSongs;

  DownloadedSongsScreen({required this.downloadedSongs});

  @override
  _DownloadedSongsScreenState createState() => _DownloadedSongsScreenState();
}

class _DownloadedSongsScreenState extends State<DownloadedSongsScreen> {
  void _deleteSong(int index) {
    setState(() {
      widget.downloadedSongs.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloaded Songs'),
      ),
      body: ListView.builder(
        itemCount: widget.downloadedSongs.length,
        itemBuilder: (context, index) {
          final track = widget.downloadedSongs[index];
          return ListTile(
            title: Text('${track['trackName']} by ${track['artistName']}'),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _deleteSong(index),
            ),
          );
        },
      ),
    );
  }
}
