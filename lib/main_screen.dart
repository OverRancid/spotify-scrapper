import 'package:flutter/material.dart';
import 'package:spotify/fetch_songs.dart';
import 'package:spotify/playlist_screen.dart';
import 'package:spotify/downlaoded_songs.dart';
import 'package:spotify/song.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _playlistUrlController = TextEditingController();
  final FetchSongs _fetchSongs = FetchSongs();

  List<Song> downloadedSongs = [];

  @override
  void dispose() {
    _playlistUrlController.dispose();
    super.dispose();
  }

  void _fetchTracks() async {
    final playlistUrl = _playlistUrlController.text;
    try {
      final playlistDetails =
          await _fetchSongs.fetchPlaylistDetails(playlistUrl);
      Navigator.push(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(
          builder: (context) => PlaylistScreen(
            playlistName: playlistDetails['playlistName'],
            tracks: List<Song>.from(playlistDetails['tracks']),
            //downloadedSongs: downloadedSongs,
          ),
        ),
      );
    } catch (e) {
      print('Error fetching tracks: $e');
    }
  }

  void _navigateToDownloadedSongs() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DownloadedSongsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spotify Playlist Reader'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _navigateToDownloadedSongs,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _playlistUrlController,
              decoration: const InputDecoration(
                hintText: 'Please Enter the Spotify Playlist URL',
              ),
            ),
            const SizedBox(height: 20), // Space between TextField and Button
            ElevatedButton(
              onPressed: _fetchTracks,
              child: const Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }
}
