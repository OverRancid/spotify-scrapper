import 'package:flutter/material.dart';
import 'package:spotify/song.dart';

class DownloadedSongsScreen extends StatefulWidget {
  final List<Song> downloadedSongs;

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
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(track.name),
                Text(
                  track.artists.join(', '),
                  style: TextStyle(
                    color: Colors.grey[600], // Lighter color for artist names
                    fontSize: 14.0,          // Smaller font size for artist names
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteSong(index),
            ),
          );
        },
      ),
    );
  }
}
