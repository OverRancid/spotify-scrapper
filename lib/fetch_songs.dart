import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:spotify/song.dart';

class FetchSongs {
  static String clientId = dotenv.env['client_id']!;
  static String clientSecret = dotenv.env['client_secret']!;

  FetchSongs();

  Future<String> getAccessToken() async {
    await dotenv.load(fileName: ".env");
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
        print(
            'Failed to obtain access token: ${response.statusCode} ${response.reasonPhrase}');
        throw Exception('Failed to obtain access token');
      }
    } catch (e) {
      print('Exception during token request: $e');
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
        List<Song> trackDetails = [];
        for (var trackItem in tracks) {
          final String trackName = trackItem['track']['name'];
          final String trackImage =
              trackItem['track']['album']['images'][0]['url'];
          late List<String> artists = [];
          for (var artist in trackItem['track']['artists']) {
            artists.add(artist['name']);
          }
          trackDetails
              .add(Song(name: trackName, artists: artists, image: trackImage));
        }

        return {
          'playlistName': playlistName,
          'tracks': trackDetails,
        };
      } else {
        print('Error ${response.statusCode}: ${response.body}');
        throw Exception('Failed to fetch playlist details');
      }
    } catch (e) {
      print('Exception during playlist details fetch: $e');
      rethrow;
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
