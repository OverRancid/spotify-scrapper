import 'package:flutter/material.dart';
import 'package:spotify/song.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'database_helper.dart';
import 'dart:io';

class DownloadedSongsScreen extends StatefulWidget {
  @override
  _DownloadedSongsScreenState createState() => _DownloadedSongsScreenState();
}

class _DownloadedSongsScreenState extends State<DownloadedSongsScreen> {
  AudioPlayer _audioPlayer = AudioPlayer();
  List<Song> downloadedSongs = [];

  @override
  void initState() {
    super.initState();
    _loadDownloadedSongs();
  }

  Future<void> _loadDownloadedSongs() async {
    final songs = await DatabaseHelper().getSongs();
    setState(() {
      downloadedSongs = songs;
    });
  }

  void _playSong(String filePath) async {
    try {
      await _audioPlayer.play(DeviceFileSource(filePath));
    } catch (e) {
      print('Error playing song: $e');
    }
  }

  void _deleteSong(int index) async {
    final song = downloadedSongs[index];
    final directory = await getApplicationDocumentsDirectory();
    final filePath = path.join(directory.path, '${song.name}.mp3');
    final file = File(filePath);

    if (await file.exists()) {
      await file.delete();
    }

    setState(() {
      downloadedSongs.removeAt(index);
    });

    await DatabaseHelper().deleteSong(song.name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloaded Songs'),
      ),
      body: ListView.builder(
        itemCount: downloadedSongs.length,
        itemBuilder: (context, index) {
          final track = downloadedSongs[index];
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
