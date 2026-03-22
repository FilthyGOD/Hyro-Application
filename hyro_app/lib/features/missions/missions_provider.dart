import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'models/daily_mission.dart';
import '../../providers/profile_provider.dart';

/// Manages daily missions: generation, progress tracking, and claiming.
class MissionsProvider extends ChangeNotifier {
  final ProfileProvider profileProvider;
  List<DailyMission> missions = [];
  bool isLoading = false;

  static const String _boxName = 'missionsBox';
  static const String _keyDate = 'lastMissionDate';
  static const String _keyMissions = 'dailyMissions';

  MissionsProvider({required this.profileProvider});

  // ─── Pool of Possible Missions ─────────────────────────────────────

  static final List<DailyMission> _missionPool = [
    DailyMission(
      id: 'complete_2_pomodoros',
      title: 'Completar 2 Pomodoros',
      description: 'Termina 2 sesiones de enfoque hoy',
      type: 'pomodoro_completed',
      targetValue: 2,
    ),
    DailyMission(
      id: 'complete_4_pomodoros',
      title: 'Completar 4 Pomodoros',
      description: 'Termina 4 sesiones de enfoque hoy',
      type: 'pomodoro_completed',
      targetValue: 4,
    ),
    DailyMission(
      id: 'study_30_min',
      title: 'Estudiar 30 minutos',
      description: 'Acumula 30 minutos de enfoque',
      type: 'minutes_studied',
      targetValue: 30,
    ),
    DailyMission(
      id: 'study_60_min',
      title: 'Estudiar 60 minutos',
      description: 'Acumula 1 hora de enfoque',
      type: 'minutes_studied',
      targetValue: 60,
    ),
    DailyMission(
      id: 'complete_1_task',
      title: 'Completar 1 tarea',
      description: 'Marca una tarea como completada',
      type: 'task_completed',
      targetValue: 1,
    ),
    DailyMission(
      id: 'complete_3_tasks',
      title: 'Completar 3 tareas',
      description: 'Marca 3 tareas como completadas',
      type: 'task_completed',
      targetValue: 3,
    ),
    DailyMission(
      id: 'complete_1_pomodoro',
      title: 'Completar 1 Pomodoro',
      description: 'Termina al menos 1 sesión de enfoque',
      type: 'pomodoro_completed',
      targetValue: 1,
    ),
    DailyMission(
      id: 'study_15_min',
      title: 'Estudiar 15 minutos',
      description: 'Acumula 15 minutos de enfoque',
      type: 'minutes_studied',
      targetValue: 15,
    ),
    DailyMission(
      id: 'complete_6_pomodoros',
      title: 'Maratón: 6 Pomodoros',
      description: 'Completa 6 sesiones de enfoque en un día',
      type: 'pomodoro_completed',
      targetValue: 6,
    ),
    DailyMission(
      id: 'study_90_min',
      title: 'Estudiar 90 minutos',
      description: 'Acumula 1.5 horas de enfoque',
      type: 'minutes_studied',
      targetValue: 90,
    ),
  ];

  // ─── Initialization ────────────────────────────────────────────────

  /// Call this on app start to load or generate daily missions.
  Future<void> initialize() async {
    isLoading = true;
    Future.microtask(() => notifyListeners());

    final box = await Hive.openBox(_boxName);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final savedDate = box.get(_keyDate) as String?;

    if (savedDate == today) {
      // Same day → load saved missions
      final savedJson = box.get(_keyMissions) as String?;
      if (savedJson != null) {
        final List decoded = jsonDecode(savedJson);
        missions = decoded
            .map((e) => DailyMission.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } else {
        _generateNewMissions(box, today);
      }
    } else {
      // New day → generate fresh missions
      _generateNewMissions(box, today);
    }

    isLoading = false;
    Future.microtask(() => notifyListeners());
  }

  void _generateNewMissions(Box box, String today) {
    final random = Random();
    final shuffled = List<DailyMission>.from(_missionPool)..shuffle(random);
    missions = shuffled.take(3).map((m) => DailyMission(
          id: m.id,
          title: m.title,
          description: m.description,
          type: m.type,
          targetValue: m.targetValue,
          currentProgress: 0,
          isClaimed: false,
          xpReward: m.xpReward,
        )).toList();

    _saveMissions(box, today);
  }

  Future<void> _saveMissions(Box box, String today) async {
    await box.put(_keyDate, today);
    final jsonList = missions.map((m) => m.toJson()).toList();
    await box.put(_keyMissions, jsonEncode(jsonList));
  }

  Future<void> _persistMissions() async {
    final box = await Hive.openBox(_boxName);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await _saveMissions(box, today);
  }

  // ─── Progress Tracking ─────────────────────────────────────────────

  /// Called by TimerCubit or other systems when a relevant event occurs.
  /// [type] matches DailyMission.type, e.g. 'pomodoro_completed'.
  /// [value] is the amount to add (e.g. 1 for a completed pomodoro).
  void updateProgress(String type, int value) {
    bool changed = false;

    for (final mission in missions) {
      if (mission.type == type && !mission.isClaimed) {
        mission.currentProgress += value;
        changed = true;
      }
    }

    if (changed) {
      _persistMissions();
      Future.microtask(() => notifyListeners());
    }
  }

  // ─── Claiming ──────────────────────────────────────────────────────

  /// Claims a completed mission, granting XP via ProfileProvider.
  Future<bool> claimMission(String missionId, String? userId) async {
    final mission = missions.firstWhere(
      (m) => m.id == missionId,
      orElse: () => throw Exception('Misión no encontrada: $missionId'),
    );

    if (!mission.isCompleted || mission.isClaimed) {
      return false;
    }

    mission.isClaimed = true;
    await _persistMissions();
    Future.microtask(() => notifyListeners());

    // Grant the XP reward
    await profileProvider.grantXP(userId, mission.xpReward);
    return true;
  }

  /// How many missions can still be claimed today.
  int get claimableMissions =>
      missions.where((m) => m.isCompleted && !m.isClaimed).length;
}
