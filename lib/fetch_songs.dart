import 'dart:convert';
import 'package:http/http.dart' as http;

class FetchSongs {
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
        print('Access token obtained successfully');
        return data['access_token'];
      } else {
        print('Failed to obtain access token: ${response.statusCode} ${response.reasonPhrase}');
        throw Exception('Failed to obtain access token');
      }
    } catch (e) {
      print('Error obtaining access token: $e');
      throw e;
    }
  }

  Future<void> fetchAndPrintTracks(String playlistUrl) async {
    try {
      final String playlistId = _extractPlaylistId(playlistUrl);
      final String accessToken = await getAccessToken();

      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/playlists/$playlistId/tracks'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> tracks = data['items'];

        for (var trackItem in tracks) {
          final String trackName = trackItem['track']['name'];
          print('Track: $trackName');
        }
      } else {
        print('Failed to fetch playlist tracks: ${response.statusCode} ${response.reasonPhrase}');
        throw Exception('Failed to fetch playlist tracks');
      }
    } catch (e) {
      print('Error fetching and printing tracks: $e');
      throw e;
    }
  }

  String _extractPlaylistId(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      final index = segments.indexOf('playlist');
      if (index != -1 && index + 1 < segments.length) {
        return segments[index + 1];
      } else {
        throw Exception('Invalid playlist URL');
      }
    } catch (e) {
      print('Error extracting playlist ID: $e');
      throw e;
    }
  }
}
