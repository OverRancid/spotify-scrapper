import 'package:flutter/material.dart';
import 'package:spotify/fetch_songs.dart';
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  _MainScreen createState() => _MainScreen();
}

class _MainScreen extends State<MainScreen> {
  final TextEditingController _textEditingController = TextEditingController();
  final FetchSongs _fetchSongs = FetchSongs(
    clientId: '',  
    clientSecret: '',
  );

  @override
  void dispose() {
    _textEditingController.dispose(); 
    super.dispose();
  }

  void _fetchTracks() async {
    final playlistUrl = _textEditingController.text;
    try {
      await _fetchSongs.fetchAndPrintTracks(playlistUrl);
    } catch (e) {
      print(e);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spotifyyyyy')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _textEditingController,
                decoration: const InputDecoration(
                  hintText: 'Please enter the Spotify playlist link',
                ),
              ),
              const SizedBox(height: 50), 
              ElevatedButton(
                onPressed: _fetchTracks,
                child: const Text("Generate"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
