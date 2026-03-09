import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SpotifyAuthService extends ChangeNotifier {
  static const String clientId = '7c4f675a9b74435280a5af17eadf17c3';
  static const String redirectUri = 'http://127.0.0.1:8080/callback';
  static const String _tokenKey = 'spotify_access_token';
  static const String _refreshKey = 'spotify_refresh_token';

  String? _accessToken;
  String? _refreshToken;
  bool _isAuthenticated = false;
  HttpServer? _server;
  String? _codeVerifier;

  String? get accessToken => _accessToken;
  bool get isAuthenticated => _isAuthenticated;

  SpotifyAuthService() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_tokenKey);
    _refreshToken = prefs.getString(_refreshKey);
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      _isAuthenticated = true;
      notifyListeners();
    }
  }

  String _generateRandomString(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(
      length,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  Future<void> authenticate() async {
    _codeVerifier = _generateRandomString(64);
    final codeChallenge = _generateCodeChallenge(_codeVerifier!);

    await _startLocalServer();

    final String authUrl =
        'https://accounts.spotify.com/authorize'
        '?client_id=$clientId'
        '&response_type=code'
        '&redirect_uri=${Uri.encodeComponent(redirectUri)}'
        '&code_challenge_method=S256'
        '&code_challenge=$codeChallenge'
        '&scope=user-read-playback-state user-modify-playback-state user-read-currently-playing';

    final Uri url = Uri.parse(authUrl);

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $authUrl');
    }
  }

  Future<void> _startLocalServer() async {
    await _server?.close(force: true);

    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);
      debugPrint('Listening on localhost:8080');

      _server!.listen((HttpRequest request) async {
        if (request.uri.path == '/callback') {
          final params = request.uri.queryParameters;

          if (params.containsKey('code')) {
            final code = params['code']!;

            // Show successful message first
            request.response
              ..statusCode = HttpStatus.ok
              ..headers.contentType = ContentType.html
              ..write(
                '<h2>Conectado con éxito! Puedes cerrar esta ventana y volver a Hyro.</h2>',
              )
              ..close();

            // Try to exchange code for token
            await _exchangeCodeForToken(code);

            _server?.close(force: true);
            _server = null;
          } else {
            request.response
              ..statusCode = HttpStatus.badRequest
              ..write('Error de Autorización: ${params['error']}')
              ..close();
          }
        } else {
          request.response
            ..statusCode = HttpStatus.notFound
            ..close();
        }
      });
    } catch (e) {
      debugPrint('Error starting server: $e');
    }
  }

  Future<void> _exchangeCodeForToken(String code) async {
    if (_codeVerifier == null) return;

    try {
      final response = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': clientId,
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': redirectUri,
          'code_verifier': _codeVerifier!,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];
        _refreshToken = data['refresh_token'];
        _isAuthenticated = true;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, _accessToken!);
        if (_refreshToken != null) {
          await prefs.setString(_refreshKey, _refreshToken!);
        }

        notifyListeners();
      } else {
        debugPrint('Spotify Token Error: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error en el exchange: $e');
    }
  }

  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _isAuthenticated = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshKey);
    notifyListeners();
  }
}
