import 'dart:io';
import 'package:flutter/material.dart';
import 'package:spotify/song.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:spotify/database_helper.dart';

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
  bool _isMounted = false; // Flag to track whether the widget is mounted

  @override
  void initState() {
    super.initState();
    _isMounted = true; // Set _isMounted to true when widget is mounted
    _loadDownloadedSongs();

    // Listen for the state change event to play the next song when the current one finishes
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (_isMounted) {
        // Check _isMounted before calling setState
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
      }
    });
  }

  Future<void> _loadDownloadedSongs() async {
    final songs = await DatabaseHelper().getSongs();
    if (_isMounted) {
      // Check _isMounted before calling setState
      setState(() {
        downloadedSongs = songs;
        downloadedSongIds = songs.map((track) => _createSongId(track)).toSet();
      });
    }
  }

  String _createSongId(Song song) {
    return '${song.name}_${song.artists.join(', ')}';
  }

  Future<void> _playSong(String filePath, int index) async {
    try {
      if (_isMounted) {
        // Check _isMounted before calling setState
        if (currentlyPlayingIndex != null) {
          await _audioPlayer.stop();
        }
        await _audioPlayer.play(DeviceFileSource(filePath));
        setState(() {
          currentlyPlayingIndex = index;
          isPlaying = true;
        });
      }
    } catch (e) {
      print('Error playing song: $e');
    }
  }

  void _playNextSong() {
    if (_isMounted) {
      // Check _isMounted before calling setState
      if (currentlyPlayingIndex != null &&
          currentlyPlayingIndex! < downloadedSongs.length - 1) {
        final nextIndex = currentlyPlayingIndex! + 1;
        final track = downloadedSongs[nextIndex];
        _playSongFromIndex(nextIndex, track);
      }
    }
  }

  Future<void> _playSongFromIndex(int index, Song track) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = path.join(directory.path, _createSongId(track) + '.mp3');
    if (_isMounted) {
      // Check _isMounted before calling setState
      if (await File(filePath).exists()) {
        await _playSong(filePath, index);
      } else {
        print('File not found: $filePath');
      }
    }
  }

  void _deleteSong(int index) async {
    if (_isMounted) {
      // Check _isMounted before calling setState
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
          isPlaying = false; // Stop playing when deleting the current song
        } else if (currentlyPlayingIndex != null &&
            currentlyPlayingIndex! > index) {
          currentlyPlayingIndex = currentlyPlayingIndex! - 1;
        }
      });

      await DatabaseHelper().deleteSongByIndex(index);
    }
  }

  Future<void> _pauseResumeSong() async {
    if (_isMounted) {
      // Check _isMounted before calling setState
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
  }

  void _rewindSong() async {
    final currentPosition = await _audioPlayer.getCurrentPosition();
    final seekTo = currentPosition! - Duration(seconds: 10);
    await _audioPlayer.seek(seekTo < Duration.zero ? Duration.zero : seekTo);
  }

  void _forwardSong() async {
    final currentPosition = await _audioPlayer.getCurrentPosition();
    final totalDuration = await _audioPlayer.getDuration();
    final seekTo = currentPosition! + Duration(seconds: 10);
    await _audioPlayer.seek(seekTo > totalDuration! ? totalDuration : seekTo);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _isMounted = false; // Set _isMounted to false when disposing the widget
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloaded Songs'),
      ),
      body: downloadedSongs.isEmpty && _isMounted
          ? Center(
              child: Text('Download songs to play'),
            )
          : ListView.builder(
              itemCount: downloadedSongs.length,
              itemBuilder: (context, index) {
                final track = downloadedSongs[index];
                final isPlayingTrack = index == currentlyPlayingIndex;
                return Dismissible(
                  key: Key(_createSongId(track)),
                  direction: DismissDirection.horizontal,
                  background:
                      Container(), // Empty Container to remove background
                  secondaryBackground:
                      Container(), // Empty Container to remove secondary background
                  onDismissed: (direction) {
                    if (direction == DismissDirection.endToStart) {
                      _deleteSong(index);
                      // Swiped from right to left (checkmark), handle accordingly
                      // For example, mark song as completed or handle completion logic
                    } else if (direction == DismissDirection.startToEnd) {
                      // Swiped from left to right (delete), handle deletion
                      _deleteSong(index);
                    }
                  },
                  child: ListTile(
                    title: Text(
                      track.name,
                      style: TextStyle(
                        fontWeight: isPlayingTrack
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isPlayingTrack
                            ? Theme.of(context)
                                .colorScheme
                                .primary // Use primary color for isPlayingTrack
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      track.artists.join(', '),
                      style: TextStyle(
                        color: isPlayingTrack
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isPlayingTrack)
                          IconButton(
                            icon: Icon(Icons.replay_10),
                            iconSize: 36,
                            onPressed: _rewindSong,
                          ),
                        if (isPlayingTrack)
                          IconButton(
                            icon: Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow),
                            iconSize: 36,
                            onPressed: _pauseResumeSong,
                          ),
                        if (isPlayingTrack)
                          IconButton(
                            icon: Icon(Icons.forward_10),
                            iconSize: 36,
                            onPressed: _forwardSong,
                          ),
                      ],
                    ),
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
