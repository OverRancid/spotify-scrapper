import 'package:flutter/material.dart';
import 'package:spotify/fetch_songs.dart';
import 'package:spotify/playlist_screen.dart';
import 'package:spotify/downloaded_songs_screen.dart';
class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _playlistUrlController = TextEditingController();
  final FetchSongs _fetchSongs = FetchSongs(
    clientId: '50353b321b5746e4a13c0a6611e33ebd',  // Replace with your client ID
    clientSecret: 'dbfa000a0932445e88b99ab639b879c5',  // Replace with your client secret
  );

  List<Map<String, String>> downloadedSongs = [];

  @override
  void dispose() {
    _playlistUrlController.dispose();
    super.dispose();
  }

  void _fetchTracks() async {
    final playlistUrl = _playlistUrlController.text;
    try {
      final playlistDetails = await _fetchSongs.fetchPlaylistDetails(playlistUrl);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlaylistScreen(
            playlistName: playlistDetails['playlistName'],
            tracks: List<Map<String, String>>.from(playlistDetails['tracks']),
            downloadedSongs: downloadedSongs,
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
        builder: (context) => DownloadedSongsScreen(downloadedSongs: downloadedSongs),
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
            icon: Icon(Icons.download),
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
                hintText: 'Please input the Spotify playlist URL',
              ),
            ),
            const SizedBox(height: 20), // Space between TextField and Button
            ElevatedButton(
              onPressed: _fetchTracks,
              child: const Text("Generate"),
            ),
          ],
        ),
      ),
    );
  }
}