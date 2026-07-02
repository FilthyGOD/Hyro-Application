import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'spotify_auth_service.dart';

class SpotifyTrack {
  final String name;
  final String artist;
  final String imageUrl;
  final bool isPlaying;

  SpotifyTrack({
    required this.name,
    required this.artist,
    required this.imageUrl,
    required this.isPlaying,
  });

  factory SpotifyTrack.fromJson(Map<String, dynamic> json, bool isPlaying) {
    var item = json['item'];
    var artistName = 'Unknown Artist';
    if (item['artists'] != null && item['artists'].isNotEmpty) {
      artistName = item['artists'][0]['name'];
    }

    var imageUrl = '';
    if (item['album'] != null &&
        item['album']['images'] != null &&
        item['album']['images'].isNotEmpty) {
      imageUrl = item['album']['images'][0]['url'];
    }

    return SpotifyTrack(
      name: item['name'] ?? 'Unknown Track',
      artist: artistName,
      imageUrl: imageUrl,
      isPlaying: isPlaying,
    );
  }
}

class SpotifyPlayerService extends ChangeNotifier {
  final SpotifyAuthService authService;
  SpotifyTrack? currentTrack;
  Timer? _pollingTimer;

  SpotifyPlayerService({required this.authService}) {
    authService.addListener(_onAuthChanged);
    if (authService.isAuthenticated) {
      startPolling();
    }
  }

  void _onAuthChanged() {
    if (authService.isAuthenticated) {
      startPolling();
    } else {
      stopPolling();
      currentTrack = null;
      notifyListeners();
    }
  }

  void startPolling() {
    _pollingTimer?.cancel();
    _fetchCurrentTrack();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchCurrentTrack();
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
  }

  Future<void> _fetchCurrentTrack() async {
    if (authService.accessToken == null) return;

    try {
      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/me/player/currently-playing'),
        headers: {'Authorization': 'Bearer ${authService.accessToken}'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['item'] != null) {
          final isPlaying = data['is_playing'] ?? false;
          currentTrack = SpotifyTrack.fromJson(data, isPlaying);
          notifyListeners();
        }
      } else if (response.statusCode == 204) {
        // No se está reproduciendo nada
        if (currentTrack != null) {
          currentTrack = null;
          notifyListeners();
        }
      } else if (response.statusCode == 401) {
        // Token expirado
        authService.logout();
      }
    } catch (e) {
      debugPrint('Error fetching Spotify track: $e');
    }
  }

  Future<void> play() async {
    if (authService.accessToken == null) return;
    await http.put(
      Uri.parse('https://api.spotify.com/v1/me/player/play'),
      headers: {'Authorization': 'Bearer ${authService.accessToken}'},
    );
    _fetchCurrentTrack();
  }

  Future<void> pause() async {
    if (authService.accessToken == null) return;
    await http.put(
      Uri.parse('https://api.spotify.com/v1/me/player/pause'),
      headers: {'Authorization': 'Bearer ${authService.accessToken}'},
    );
    _fetchCurrentTrack();
  }

  Future<void> skipNext() async {
    if (authService.accessToken == null) return;
    await http.post(
      Uri.parse('https://api.spotify.com/v1/me/player/next'),
      headers: {'Authorization': 'Bearer ${authService.accessToken}'},
    );
    Future.delayed(const Duration(milliseconds: 500), _fetchCurrentTrack);
  }

  Future<void> skipPrevious() async {
    if (authService.accessToken == null) return;
    await http.post(
      Uri.parse('https://api.spotify.com/v1/me/player/previous'),
      headers: {'Authorization': 'Bearer ${authService.accessToken}'},
    );
    Future.delayed(const Duration(milliseconds: 500), _fetchCurrentTrack);
  }

  @override
  void dispose() {
    authService.removeListener(_onAuthChanged);
    stopPolling();
    super.dispose();
  }
}
