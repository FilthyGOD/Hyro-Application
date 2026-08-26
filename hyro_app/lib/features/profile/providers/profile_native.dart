import 'package:isar/isar.dart';
import 'dart:math' as math;
import 'package:hyro/data/models/user_profile.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hyro/data/models/daily_stats.dart';
import 'package:hyro/data/repositories/stats_repository.dart';
import 'package:flutter/material.dart';

/// Carga el perfil local desde Isar.
Future<Map<String, int>?> loadLocalProfile(dynamic isarDynamic) async {
  final isar = isarDynamic as Isar;
  final activeUser = await isar.userProfiles.filter().isActivelyLoggedInEqualTo(true).findFirst();
  if (activeUser == null) return null;
  return {
    'nivel': activeUser.nivel,
    'experiencia': activeUser.experiencia,
    'monedas': activeUser.monedas,
    'rachaActual': activeUser.rachaActual,
    'rachaMaxima': activeUser.rachaMaxima,
    'minutosEnfoqueTotal': activeUser.minutosEnfoqueTotal,
    'tareasCompletadas': activeUser.tareasCompletadasTotal,
    'sesionesMes': activeUser.sesionesMes,
  };
}

/// Actualiza el perfil local en Isar desde datos de Supabase.
Future<void> updateLocalProfile(dynamic isarDynamic, Map<String, dynamic> response, int countVal) async {
  final isar = isarDynamic as Isar;
  final activeUser = await isar.userProfiles.filter().isActivelyLoggedInEqualTo(true).findFirst();
  if (activeUser == null) return;
  
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
}

/// Actualiza monedas locales en Isar desde streaming en tiempo real.
void updateLocalCoins(dynamic isarDynamic, int dbMonedas) {
  final isar = isarDynamic as Isar;
  isar.writeTxnSync(() {
    final activeUser = isar.userProfiles.filter().isActivelyLoggedInEqualTo(true).findFirstSync();
    if (activeUser != null) {
      activeUser.monedas = dbMonedas;
      isar.userProfiles.putSync(activeUser);
    }
  });
}

/// Verifica la racha con el Juez de Rachas. Devuelve null si no hay cambio, o el nuevo valor.
Future<int?> checkStreakJudge(dynamic isarDynamic, int rachaActual, String? userId) async {
  if (!Hive.isBoxOpen('statsBox')) return null;
  
  final statsRepo = StatsRepository(Hive.box<DailyStats>('statsBox'));
  final trueStreak = statsRepo.getCurrentStreak();
  
  if (trueStreak == 0 && rachaActual > 0) {
    debugPrint('🚨 Juez de Rachas: ¡Racha perdida! (Tenías $rachaActual, bajado a 0)');
    
    final isar = isarDynamic as Isar;
    final usr = await isar.userProfiles.filter().isActivelyLoggedInEqualTo(true).findFirst();
    if (usr != null) {
      await isar.writeTxn(() async {
        usr.rachaActual = 0;
        await isar.userProfiles.put(usr);
      });
    }
    
    return 0; // Racha perdida
  }
  return null; // Sin cambios
}

/// Otorga XP localmente en Isar. Devuelve los nuevos valores o null.
Future<Map<String, int>?> grantXPLocally(dynamic isarDynamic, int xp) async {
  final isar = isarDynamic as Isar;
  final activeUser = await isar.userProfiles.filter().isActivelyLoggedInEqualTo(true).findFirst();
  if (activeUser == null) return null;
  
  await isar.writeTxn(() async {
    activeUser.experiencia += xp;
    while (true) {
      final nextLvlXp = (100 * math.pow(activeUser.nivel - 1, 1.5) + 100).toInt();
      if (activeUser.experiencia >= nextLvlXp) {
        activeUser.experiencia -= nextLvlXp;
        activeUser.nivel += 1;
      } else {
        break;
      }
    }
    await isar.userProfiles.put(activeUser);
  });
  
  return {
    'nivel': activeUser.nivel,
    'experiencia': activeUser.experiencia,
  };
}

/// Sincroniza stats dinámicos localmente en Isar.
Future<Map<String, int>?> syncDynamicStatsLocally(dynamic isarDynamic, int dynamicStreak, int newlyAddedMinutes) async {
  final isar = isarDynamic as Isar;
  final activeUser = await isar.userProfiles.filter().isActivelyLoggedInEqualTo(true).findFirst();
  if (activeUser == null) return null;
  
  await isar.writeTxn(() async {
    activeUser.rachaActual = dynamicStreak;
    if (dynamicStreak > activeUser.rachaMaxima) {
      activeUser.rachaMaxima = dynamicStreak;
    }
    activeUser.minutosEnfoqueTotal += newlyAddedMinutes;
    activeUser.sesionesMes += 1;
    await isar.userProfiles.put(activeUser);
  });
  
  return {
    'rachaActual': activeUser.rachaActual,
    'rachaMaxima': activeUser.rachaMaxima,
    'minutosEnfoqueTotal': activeUser.minutosEnfoqueTotal,
    'sesionesMes': activeUser.sesionesMes,
  };
}

/// Modifica monedas localmente en Isar. Devuelve el nuevo total o null.
Future<int?> modifyCoinsLocally(dynamic isarDynamic, int cantidad) async {
  final isar = isarDynamic as Isar;
  final activeUser = await isar.userProfiles.filter().isActivelyLoggedInEqualTo(true).findFirst();
  if (activeUser == null) return null;
  
  await isar.writeTxn(() async {
    activeUser.monedas += cantidad;
    if (activeUser.monedas < 0) activeUser.monedas = 0;
    await isar.userProfiles.put(activeUser);
  });
  
  return activeUser.monedas;
}
