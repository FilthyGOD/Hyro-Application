import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

// Importación condicional para Isar y Hive
import 'package:hyro/features/profile/providers/profile_native.dart'
    if (dart.library.html) 'package:hyro/features/profile/providers/profile_web.dart'
    as profile_platform;

/// Estado reactivo para el perfil de gamificación del usuario (nivel, xp, monedas)
/// respaldado por la tabla `perfiles` en Supabase o localmente vía Isar para invitados.
class ProfileProvider extends ChangeNotifier {
  final dynamic isar; // Isar en nativo, null en web

  ProfileProvider(this.isar);
  int nivel = 1;
  int experiencia = 0;
  int monedas = 0;
  
  // Variables para priorizar offline (Offline-first)
  int rachaActual = 0;
  int rachaMaxima = 0;
  int minutosEnfoqueTotal = 0;
  int tareasCompletadas = 0;
  int sesionesMes = 0;

  // Identificador único del usuario (nombre_usuario + codigo_amigo)
  String? nombreUsuario;
  int? codigoAmigo;

  // Buffs activos
  int protectoresRachaActivos = 0;
  int sesionesXPDobleRestantes = 0;

  /// Formato completo: NombreUsuario#Código (o null si no se ha cargado).
  String? get displayTag {
    if (nombreUsuario == null || codigoAmigo == null) return null;
    return '$nombreUsuario#$codigoAmigo';
  }
  
  bool isLoading = false;
  String? _error;

  String? get error => _error;

  final _supabase = Supabase.instance.client;
  StreamSubscription<List<Map<String, dynamic>>>? _profileSubscription;

  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }

  /// Carga el perfil desde Supabase o localmente si [userId] es nulo.
  Future<void> loadProfile(String? userId) async {
    // 1. Blindaje: Envolvemos el aviso inicial en un microtask
    Future.microtask(() {
      isLoading = true;
      _error = null;
      notifyListeners();
    });

    try {
      // Siempre leemos de local (Isar) primero para Offline-First (solo nativo)
      if (!kIsWeb && isar != null) {
        final localData = await profile_platform.loadLocalProfile(isar);
        if (localData != null) {
          nivel = localData['nivel'] as int;
          experiencia = localData['experiencia'] as int;
          monedas = localData['monedas'] as int;
          rachaActual = localData['rachaActual'] as int;
          rachaMaxima = localData['rachaMaxima'] as int;
          minutosEnfoqueTotal = localData['minutosEnfoqueTotal'] as int;
          tareasCompletadas = localData['tareasCompletadas'] as int;
          sesionesMes = localData['sesionesMes'] as int;
          notifyListeners();
        }
      }

      // Si hay sesión online, intentamos sincronizar desde Supabase
      if (userId != null) {
        try {
          final response = await _supabase
              .from('perfiles')
              .select('nivel, experiencia, monedas, racha_actual, racha_maxima, minutos_enfoque_total, tareas_completadas_total, nombre_usuario, codigo_amigo, protectores_racha_activos, sesiones_xp_doble_restantes')
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

          final countVal = sessionsCount.count;

          if (response != null) {
            // Actualizar Isar localmente (solo nativo)
            if (!kIsWeb && isar != null) {
              await profile_platform.updateLocalProfile(isar, response, countVal);
            }
            
            // Actualizamos en memoria
            nivel = (response['nivel'] as num?)?.toInt() ?? 1;
            experiencia = (response['experiencia'] as num?)?.toInt() ?? 0;
            monedas = (response['monedas'] as num?)?.toInt() ?? 0;
            rachaActual = (response['racha_actual'] as num?)?.toInt() ?? 0;
            rachaMaxima = (response['racha_maxima'] as num?)?.toInt() ?? 0;
            minutosEnfoqueTotal = (response['minutos_enfoque_total'] as num?)?.toInt() ?? 0;
            tareasCompletadas = (response['tareas_completadas_total'] as num?)?.toInt() ?? 0;
            sesionesMes = countVal;

            // Cargar nombre_usuario y codigo_amigo para el identificador único
            nombreUsuario = response['nombre_usuario'] as String?;
            codigoAmigo = (response['codigo_amigo'] as num?)?.toInt();
            protectoresRachaActivos = (response['protectores_racha_activos'] as num?)?.toInt() ?? 0;
            sesionesXPDobleRestantes = (response['sesiones_xp_doble_restantes'] as num?)?.toInt() ?? 0;
          }
        } catch (syncError) {
          debugPrint('Error de sincronización con Supabase (ignorado por Offline-First): $syncError');
        }

        // Suscribirse a cambios en tiempo real (ej. monedas desde la RPC del Versus)
        _profileSubscription?.cancel();
        _profileSubscription = _supabase
            .from('perfiles')
            .stream(primaryKey: ['id'])
            .eq('id', userId)
            .listen((data) {
          if (data.isNotEmpty) {
            final row = data.first;
            final dbMonedas = (row['monedas'] as num?)?.toInt() ?? 0;
            if (dbMonedas != monedas) {
              monedas = dbMonedas;
              // También actualizamos en la DB local (Isar) — solo nativo
              if (!kIsWeb && isar != null) {
                profile_platform.updateLocalCoins(isar, dbMonedas);
              }
              notifyListeners();
            }
          }
        });
      }

      // 🚀 Juez de Rachas (verificación de racha estilo Duolingo) — solo nativo con Hive
      if (!kIsWeb) {
        final streakResult = await profile_platform.checkStreakJudge(isar, rachaActual, userId);
        if (streakResult != null) {
          rachaActual = streakResult;
          
          if (userId != null && rachaActual == 0) {
            try {
              await _supabase.from('perfiles').update({'racha_actual': 0}).eq('id', userId);
              debugPrint('🚨 Castigo reflejado en Supabase');
            } catch (e) {
              debugPrint('⚠️ No se pudo enviar el castigo de racha a Supabase: $e');
            }
          }
          notifyListeners();
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

  /// Llama a la RPC `otorgar_experiencia` o actualiza localmente.
  Future<void> grantXP(String? userId, int xp) async {
    try {
      if (userId == null) {
        if (!kIsWeb && isar != null) {
          final result = await profile_platform.grantXPLocally(isar, xp);
          if (result != null) {
            nivel = result['nivel'] as int;
            experiencia = result['experiencia'] as int;
            notifyListeners();
          }
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

  /// Sincroniza las métricas de gamificación offline-first recién calculadas localmente y en Supabase
  Future<void> syncDynamicStats(String? userId, int dynamicStreak, int newlyAddedMinutes) async {
    if (!kIsWeb && isar != null) {
      final result = await profile_platform.syncDynamicStatsLocally(isar, dynamicStreak, newlyAddedMinutes);
      if (result != null) {
        rachaActual = result['rachaActual'] as int;
        rachaMaxima = result['rachaMaxima'] as int;
        minutosEnfoqueTotal = result['minutosEnfoqueTotal'] as int;
        sesionesMes = result['sesionesMes'] as int;
        notifyListeners();
      }
    } else {
      // En web, solo actualizar en memoria
      rachaActual = dynamicStreak;
      if (dynamicStreak > rachaMaxima) rachaMaxima = dynamicStreak;
      minutosEnfoqueTotal += newlyAddedMinutes;
      sesionesMes += 1;
      notifyListeners();
    }

    if (userId != null) {
      try {
        await _supabase.from('perfiles').update({
          'racha_actual': rachaActual,
          'racha_maxima': rachaMaxima,
          'minutos_enfoque_total': minutosEnfoqueTotal,
        }).eq('id', userId);
      } catch (e) {
        debugPrint('⚠️ Sin conexión para sincronizar gamificación del perfil: $e');
      }
    }
  }

  /// Modifica las monedas del usuario (tanto Isar local como Supabase).
  Future<void> modificarMonedas(String? userId, int cantidad) async {
    try {
      if (!kIsWeb && isar != null) {
        final newCoins = await profile_platform.modifyCoinsLocally(isar, cantidad);
        if (newCoins != null) {
          monedas = newCoins;
          notifyListeners();
        }
      } else {
        // En web, solo actualizar en memoria
        monedas += cantidad;
        if (monedas < 0) monedas = 0;
        notifyListeners();
      }

      if (userId != null) {
        final response = await _supabase
            .from('perfiles')
            .select('monedas')
            .eq('id', userId)
            .maybeSingle();

        if (response != null) {
          final currentCoins = (response['monedas'] as num?)?.toInt() ?? 0;
          int newCoins = currentCoins + cantidad;
          if (newCoins < 0) newCoins = 0;
          await _supabase
              .from('perfiles')
              .update({'monedas': newCoins})
              .eq('id', userId);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error modificando monedas: $e');
    }
  }

  /// XP requerida para alcanzar el siguiente nivel.
  int get xpForNextLevel => (100 * math.pow(nivel - 1, 1.5) + 100).toInt();

  /// Fracción de progreso (0.0 – 1.0) hacia el siguiente nivel.
  double get levelProgress {
    final required = xpForNextLevel;
    if (required <= 0) return 0.0;
    return (experiencia / required).clamp(0.0, 1.0);
  }
}
