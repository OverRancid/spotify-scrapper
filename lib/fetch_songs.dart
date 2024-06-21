// spotify_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class FetchSongs{
  final String clientId;
  final String clientSecret;

  FetchSongs({required this.clientId, required this.clientSecret});

  Future<String> getAccessToken() async {
    try {
      final String auth = base64Encode(utf8.encode('$clientId:$clientSecret'));
      final response = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {
          'Authorization': 'Basic $auth',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'client_credentials',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['access_token'];
      } else {
        throw Exception('Failed to obtain access token');
      }
    } catch (e) {
      throw e;
    }
  }

  Future<Map<String, dynamic>> fetchPlaylistDetails(String playlistUrl) async {
    try {
      final String playlistId = _extractPlaylistId(playlistUrl);
      final String accessToken = await getAccessToken();

      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/playlists/$playlistId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String playlistName = data['name'];
        final List<dynamic> tracks = data['tracks']['items'];

        List<Map<String, String>> trackDetails = [];
        for (var trackItem in tracks) {
          final String trackName = trackItem['track']['name'];
          final String artistName = trackItem['track']['artists'][0]['name'];
          trackDetails.add({'trackName': trackName, 'artistName': artistName});
        }

        return {
          'playlistName': playlistName,
          'tracks': trackDetails,
        };
      } else {
        throw Exception('Failed to fetch playlist details');
      }
    } catch (e) {
      throw e;
    }
  }

  String _extractPlaylistId(String url) {
    final uri = Uri.parse(url);
    final segments = uri.pathSegments;
    final index = segments.indexOf('playlist');
    if (index != -1 && index + 1 < segments.length) {
      return segments[index + 1];
    } else {
      throw Exception('Invalid playlist URL');
    }
  }
}
