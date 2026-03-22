import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:isar/isar.dart';
import 'package:hyro_app/models/user_profile.dart';

/// Reactive state for the user's gamification profile (nivel, xp, monedas)
/// backed by the `perfiles` table in Supabase or locally via Isar for guests.
class ProfileProvider extends ChangeNotifier {
  final Isar isar;

  ProfileProvider(this.isar);
  int nivel = 1;
  int experiencia = 0;
  int monedas = 0;
  bool isLoading = false;
  String? _error;

  String? get error => _error;

  final _supabase = Supabase.instance.client;

  /// Loads the profile from Supabase or locally if [userId] is null.
  Future<void> loadProfile(String? userId) async {
    // 1. Blindaje: Envolvemos el aviso inicial en un microtask
    Future.microtask(() {
      isLoading = true;
      _error = null;
      notifyListeners();
    });

    try {
      if (userId == null) {
        final activeUser = await isar.userProfiles.filter().isActivelyLoggedInEqualTo(true).findFirst();
        if (activeUser != null) {
          nivel = activeUser.nivel;
          experiencia = activeUser.experiencia;
          monedas = activeUser.monedas;
        }
      } else {
        final response =
            await _supabase
                .from('perfiles')
                .select('nivel, experiencia, monedas')
                .eq('id', userId)
                .maybeSingle();

        if (response != null) {
          nivel = (response['nivel'] as num?)?.toInt() ?? 1;
          experiencia = (response['experiencia'] as num?)?.toInt() ?? 0;
          monedas = (response['monedas'] as num?)?.toInt() ?? 0;
        }
      }
    } catch (e) {
      _error = 'Error cargando perfil: $e';
      debugPrint(_error);
    } finally {
      // 2. Blindaje: Aseguramos la salida también
      Future.microtask(() {
        isLoading = false;
        notifyListeners();
      });
    }
  }

  /// Calls the `otorgar_experiencia` RPC or updates locally.
  Future<void> grantXP(String? userId, int xp) async {
    try {
      if (userId == null) {
        final activeUser = await isar.userProfiles.filter().isActivelyLoggedInEqualTo(true).findFirst();
        if (activeUser != null) {
          await isar.writeTxn(() async {
            activeUser.experiencia += xp;
            while (true) {
              final nextLvlXp = activeUser.nivel * 100;
              if (activeUser.experiencia >= nextLvlXp) {
                 activeUser.experiencia -= nextLvlXp;
                 activeUser.nivel += 1;
              } else {
                 break;
              }
            }
            await isar.userProfiles.put(activeUser);
          });
          nivel = activeUser.nivel;
          experiencia = activeUser.experiencia;
          notifyListeners();
        }
      } else {
        await _supabase.rpc(
          'otorgar_experiencia',
          params: {'usuario_id': userId, 'xp_ganada': xp},
        );
        await loadProfile(userId);
      }
    } catch (e) {
      Future.microtask(() {
        _error = 'Error otorgando XP: $e';
        debugPrint(_error);
        notifyListeners();
      });
    }
  }

  /// XP required to reach the next level: nivel × 100.
  int get xpForNextLevel => nivel * 100;

  /// Progress fraction (0.0 – 1.0) toward the next level.
  double get levelProgress {
    final required = xpForNextLevel;
    if (required <= 0) return 0.0;
    return (experiencia / required).clamp(0.0, 1.0);
  }
}
