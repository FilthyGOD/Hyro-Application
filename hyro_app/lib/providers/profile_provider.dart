import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reactive state for the user's gamification profile (nivel, xp, monedas)
/// backed by the `perfiles` table in Supabase.
class ProfileProvider extends ChangeNotifier {
  int nivel = 1;
  int experiencia = 0;
  int monedas = 0;
  bool isLoading = false;
  String? _error;

  String? get error => _error;

  final _supabase = Supabase.instance.client;

  /// Loads the profile from Supabase for the given [userId].
  Future<void> loadProfile(String userId) async {
    // 1. Blindaje: Envolvemos el aviso inicial en un microtask
    Future.microtask(() {
      isLoading = true;
      _error = null;
      notifyListeners();
    });

    try {
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

  /// Calls the `otorgar_experiencia` RPC and refreshes the local state.
  Future<void> grantXP(String userId, int xp) async {
    try {
      await _supabase.rpc(
        'otorgar_experiencia',
        params: {'usuario_id': userId, 'xp_ganada': xp},
      );

      // Re-read the profile to get updated nivel/experiencia/monedas
      await loadProfile(userId);
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
