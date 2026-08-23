// Barrel file: exports the IO implementation on native, stub on web.
// On web, Spotify auth is disabled entirely.
export 'spotify_auth_service_io.dart'
    if (dart.library.html) 'spotify_auth_service_web.dart';
