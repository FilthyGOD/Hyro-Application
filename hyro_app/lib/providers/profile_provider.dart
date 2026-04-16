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
  
  // Offline-first variables
  int rachaActual = 0;
  int rachaMaxima = 0;
  int minutosEnfoqueTotal = 0;
  int tareasCompletadas = 0;
  int sesionesMes = 0;
  
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
      // Siempre leemos de local (Isar) primero para Offline-First
      final activeUser = await isar.userProfiles.filter().isActivelyLoggedInEqualTo(true).findFirst();
      if (activeUser != null) {
        nivel = activeUser.nivel;
        experiencia = activeUser.experiencia;
        monedas = activeUser.monedas;
        rachaActual = activeUser.rachaActual;
        rachaMaxima = activeUser.rachaMaxima;
        minutosEnfoqueTotal = activeUser.minutosEnfoqueTotal;
        tareasCompletadas = activeUser.tareasCompletadasTotal;
        sesionesMes = activeUser.sesionesMes;
        // Notificamos para que la UI se renderice inmediatamente con datos locales
        notifyListeners();
      }

      // Si hay sesión online, intentamos sincronizar desde Supabase
      if (userId != null) {
        try {
          final response = await _supabase
              .from('perfiles')
              .select('nivel, experiencia, monedas, racha_actual, racha_maxima, minutos_enfoque_total, tareas_completadas_total')
              .eq('id', userId)
              .maybeSingle();

          // Calculamos sesiones del mes
          final now = DateTime.now();
          final startOfMonth = DateTime(now.year, now.month, 1).toUtc().toIso8601String();
          final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59).toUtc().toIso8601String();
          final sessionsCount = await _supabase
              .from('sesiones_enfoque')
              .select('id')
              .gte('completada_en', startOfMonth)
              .lte('completada_en', endOfMonth)
              .count(CountOption.exact);

          final countVal = sessionsCount.count ?? 0;

          if (response != null && activeUser != null) {
            await isar.writeTxn(() async {
              activeUser.nivel = (response['nivel'] as num?)?.toInt() ?? 1;
              activeUser.experiencia = (response['experiencia'] as num?)?.toInt() ?? 0;
              activeUser.monedas = (response['monedas'] as num?)?.toInt() ?? 0;
              activeUser.rachaActual = (response['racha_actual'] as num?)?.toInt() ?? 0;
              activeUser.rachaMaxima = (response['racha_maxima'] as num?)?.toInt() ?? 0;
              activeUser.minutosEnfoqueTotal = (response['minutos_enfoque_total'] as num?)?.toInt() ?? 0;
              activeUser.tareasCompletadasTotal = (response['tareas_completadas_total'] as num?)?.toInt() ?? 0;
              activeUser.sesionesMes = countVal;
              await isar.userProfiles.put(activeUser);
            });
            
            // Actualizamos en memoria
            nivel = activeUser.nivel;
            experiencia = activeUser.experiencia;
            monedas = activeUser.monedas;
            rachaActual = activeUser.rachaActual;
            rachaMaxima = activeUser.rachaMaxima;
            minutosEnfoqueTotal = activeUser.minutosEnfoqueTotal;
            tareasCompletadas = activeUser.tareasCompletadasTotal;
            sesionesMes = activeUser.sesionesMes;
          }
        } catch (syncError) {
          debugPrint('Error de sincronización con Supabase (ignorado por Offline-First): $syncError');
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

  /// Syncs newly calculated offline-first gamification metrics locally and to Supabase
  Future<void> syncDynamicStats(String? userId, int dynamicStreak, int newlyAddedMinutes) async {
    final activeUser = await isar.userProfiles.filter().isActivelyLoggedInEqualTo(true).findFirst();
    if (activeUser != null) {
      await isar.writeTxn(() async {
        activeUser.rachaActual = dynamicStreak;
        if (dynamicStreak > activeUser.rachaMaxima) {
          activeUser.rachaMaxima = dynamicStreak;
        }
        activeUser.minutosEnfoqueTotal += newlyAddedMinutes;
        activeUser.sesionesMes += 1;
        await isar.userProfiles.put(activeUser);
      });

      rachaActual = activeUser.rachaActual;
      rachaMaxima = activeUser.rachaMaxima;
      minutosEnfoqueTotal = activeUser.minutosEnfoqueTotal;
      sesionesMes = activeUser.sesionesMes;
      notifyListeners();

      if (userId != null) {
        try {
          await _supabase.from('perfiles').update({
            'racha_actual': rachaActual,
            'racha_maxima': rachaMaxima,
            'minutos_enfoque_total': minutosEnfoqueTotal,
          }).eq('id', userId);
        } catch (e) {
          debugPrint('⚠️ Not online to sync profile gamification directly: $e');
        }
      }
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
