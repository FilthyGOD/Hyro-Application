import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:hyro_app/models/user_profile.dart';

class AuthProvider extends ChangeNotifier {
  final Isar isar;
  UserProfile? _currentUser;
  bool _isLoading = true;

  AuthProvider(this.isar) {
    _loadUserSession();
  }

  UserProfile? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated =>
      _currentUser != null && _currentUser!.isActivelyLoggedIn;

  Future<void> _loadUserSession() async {
    _isLoading = true;
    notifyListeners();

    // Check if there is a primary user logged in
    final activeUser =
        await isar.userProfiles
            .filter()
            .isActivelyLoggedInEqualTo(true)
            .findFirst();

    // Añadir un retardo artificial para apreciar la pantalla de carga (Splash Screen)
    await Future.delayed(const Duration(seconds: 5));

    _currentUser = activeUser;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loginPersonal(String email, String name) async {
    // Basic mock logic for now. We create or update the user.
    _isLoading = true;
    notifyListeners();

    final existingUser =
        await isar.userProfiles
            .filter()
            .usernameOrEmailEqualTo(email)
            .findFirst();

    final user =
        existingUser ?? UserProfile()
          ..usernameOrEmail = email
          ..name = name
          ..type = UserType.personal
          ..isActivelyLoggedIn = true;

    if (existingUser != null) {
      user.isActivelyLoggedIn = true;
    }

    await isar.writeTxn(() async {
      // Logout any other active users
      final activeUsers =
          await isar.userProfiles
              .filter()
              .isActivelyLoggedInEqualTo(true)
              .findAll();

      for (var u in activeUsers) {
        u.isActivelyLoggedIn = false;
        await isar.userProfiles.put(u);
      }

      await isar.userProfiles.put(user);
    });

    _currentUser = user;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    if (_currentUser != null) {
      await isar.writeTxn(() async {
        _currentUser!.isActivelyLoggedIn = false;
        await isar.userProfiles.put(_currentUser!);
      });
      _currentUser = null;
      notifyListeners();
    }
  }
}
