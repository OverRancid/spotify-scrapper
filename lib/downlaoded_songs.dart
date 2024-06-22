import 'package:flutter/material.dart';
import 'package:spotify/song.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
class DownloadedSongsScreen extends StatefulWidget {
  final List<Song> downloadedSongs;

  DownloadedSongsScreen({required this.downloadedSongs});

  @override
  _DownloadedSongsScreenState createState() => _DownloadedSongsScreenState();
}

class _DownloadedSongsScreenState extends State<DownloadedSongsScreen> {
  AudioPlayer _audioPlayer = AudioPlayer();

   void _playSong(String filePath) async {
    try {
      await _audioPlayer.play(DeviceFileSource(filePath));
    } catch (e) {
      print('Error playing song: $e');
    }
  }

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
            title: Text('${track.name}'),
            subtitle: Text('${track.artists.join(', ')}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteSong(index),
            ),
            onTap: () async {
              final directory = await getApplicationDocumentsDirectory();
              final filePath = path.join(directory.path, '${track.name}.mp3');
              _playSong(filePath);
            },
          );
        },
      ),
    );
  }
}
