import 'dart:io';
import 'package:flutter/material.dart';
import 'package:spotify/song.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
<<<<<<< HEAD

import 'database_helper.dart';
import 'dart:io';
=======
import 'package:spotify/database_helper.dart';
>>>>>>> 759d20291e9bb9bb7c3a16b2f708d3774dc9d0e8

class DownloadedSongsScreen extends StatefulWidget {
  @override
  _DownloadedSongsScreenState createState() => _DownloadedSongsScreenState();
}

class _DownloadedSongsScreenState extends State<DownloadedSongsScreen> {
  AudioPlayer _audioPlayer = AudioPlayer();
  List<Song> downloadedSongs = [];
  Set<String> downloadedSongIds = {};
  int? currentlyPlayingIndex;
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadDownloadedSongs();

    // Listen for the state change event to play the next song when the current one finishes
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed) {
        _playNextSong();
      } else if (state == PlayerState.playing) {
        setState(() {
          isPlaying = true;
        });
      } else {
        setState(() {
          isPlaying = false;
        });
      }
    });
  }

  Future<void> _loadDownloadedSongs() async {
    final songs = await DatabaseHelper().getSongs();
    setState(() {
      downloadedSongs = songs;
      downloadedSongIds = songs.map((song) => _createSongId(song)).toSet();
    });
  }

  String _createSongId(Song song) {
    return '${song.name}_${song.artists.join(', ')}';
  }

  Future<void> _playSong(String filePath, int index) async {
    try {
      if (currentlyPlayingIndex != null) {
        await _audioPlayer.stop();
      }
      await _audioPlayer.play(DeviceFileSource(filePath));
      setState(() {
        currentlyPlayingIndex = index;
        isPlaying = true;
      });
    } catch (e) {
      print('Error playing song: $e');
    }
  }

  void _playNextSong() {
    if (currentlyPlayingIndex != null &&
        currentlyPlayingIndex! < downloadedSongs.length - 1) {
      final nextIndex = currentlyPlayingIndex! + 1;
      final track = downloadedSongs[nextIndex];
      _playSongFromIndex(nextIndex, track);
    }
  }

  Future<void> _playSongFromIndex(int index, Song track) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = path.join(directory.path, _createSongId(track) + '.mp3');
    if (await File(filePath).exists()) {
      await _playSong(filePath, index);
    } else {
      print('File not found: $filePath');
    }
  }

  void _deleteSong(int index) async {
    final song = downloadedSongs[index];
    final directory = await getApplicationDocumentsDirectory();
    final filePath = path.join(directory.path, _createSongId(song) + '.mp3');
    final file = File(filePath);

    if (await file.exists()) {
      await file.delete();
    }

    setState(() {
      downloadedSongs.removeAt(index);
      downloadedSongIds.remove(_createSongId(song));
      if (currentlyPlayingIndex == index) {
        currentlyPlayingIndex = null;
        isPlaying = false; // Ensure playback stops if the current song is deleted
      } else if (currentlyPlayingIndex != null && currentlyPlayingIndex! > index) {
        currentlyPlayingIndex = currentlyPlayingIndex! - 1;
      }
    });

    await DatabaseHelper().deleteSong(_createSongId(song)); // Delete from the database using the song's unique ID
  }

  Future<void> _pauseResumeSong() async {
    if (isPlaying) {
      await _audioPlayer.pause();
      setState(() {
        isPlaying = false;
      });
    } else {
      await _audioPlayer.resume();
      setState(() {
        isPlaying = true;
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
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
          final isPlayingTrack = index == currentlyPlayingIndex;
          return Dismissible(
            key: Key(_createSongId(track)),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              _deleteSong(index);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${track.name} deleted')),
              );
            },
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Icon(Icons.delete, color: Colors.white),
            ),
            child: ListTile(
              title: Text(
                track.name,
                style: TextStyle(
                  fontWeight: isPlayingTrack ? FontWeight.bold : FontWeight.normal,
                  color: isPlayingTrack ? Colors.blue : Colors.black,
                ),
              ),
              subtitle: Text(
                track.artists.join(', '),
                style: TextStyle(
                  color: isPlayingTrack ? Colors.blue : Colors.black54,
                ),
              ),
              trailing: isPlayingTrack
                  ? IconButton(
                      icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                      onPressed: _pauseResumeSong,
                    )
                  : null,
              onTap: () async {
                await _playSongFromIndex(index, track);
              },
            ),
          );
        },
      ),
    );
  }
}
