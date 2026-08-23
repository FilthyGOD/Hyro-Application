import 'dart:async';
import 'package:hyro/data/models/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Stubs para web — no hay Isar, deep links nativos, ni Google Sign-In nativo.

StreamSubscription<dynamic>? listenForDeepLinksPC() => null;

Future<bool> hasInternet() async => true;

Future<void> syncSupabaseUserToIsar({
  required dynamic isar,
  required User supabaseUser,
  required String email,
  required String name,
  required void Function(UserProfile user) onUserReady,
  required void Function() onLoadingDone,
}) async {
  // No-op en web
  onLoadingDone();
}

Future<UserProfile?> findActiveUser(dynamic isar) async => null;

Future<UserProfile> loginAsGuest(dynamic isar) async {
  return UserProfile()
    ..usernameOrEmail = 'guest_local'
    ..name = 'Invitado'
    ..type = UserType.personal
    ..isActivelyLoggedIn = true;
}

Future<UserProfile> loginPersonal(dynamic isar, String email, String name) async {
  return UserProfile()
    ..usernameOrEmail = email
    ..name = name
    ..type = UserType.personal
    ..isActivelyLoggedIn = true;
}

Future<void> cleanupNativeLogout(dynamic isar) async {}

Future<void> clearIsarProfiles(dynamic isar) async {}
