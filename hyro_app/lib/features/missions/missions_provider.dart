import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'models/daily_mission.dart';
import '../profile/providers/profile_provider.dart';

/// Manages daily missions: generation, progress tracking, and claiming.
class MissionsProvider extends ChangeNotifier {
  final ProfileProvider profileProvider;
  List<DailyMission> missions = [];
  bool isLoading = false;

  static const String _boxName = 'missionsBox';
  static const String _keyDate = 'lastMissionDate';
  static const String _keyMissions = 'dailyMissions';

  MissionsProvider({required this.profileProvider});

  // ─── Pools of Possible Missions by Difficulty ──────────────────────

  static final List<DailyMission> _easyMissions = [
    DailyMission(
      id: 'easy_complete_2_pomodoros',
      title: 'Completar 2 Pomodoros',
      description: 'Termina 2 sesiones de enfoque hoy',
      type: 'pomodoro_completed',
      targetValue: 2,
      xpReward: 25,
      coinReward: 10,
    ),
  ];

  static final List<DailyMission> _mediumMissions = [
    DailyMission(
      id: 'medium_complete_2_tasks',
      title: 'Completar 2 tareas',
      description: 'Termina 2 tareas de tu lista de pendientes',
      type: 'task_completed',
      targetValue: 2,
      xpReward: 50,
      coinReward: 20,
    ),
    DailyMission(
      id: 'medium_complete_3_tasks',
      title: 'Completar 3 tareas',
      description: 'Termina 3 tareas de tu lista de pendientes',
      type: 'task_completed',
      targetValue: 3,
      xpReward: 50,
      coinReward: 20,
    ),
  ];

  static final List<DailyMission> _hardMissions = [
    DailyMission(
      id: 'hard_complete_1_cycle',
      title: 'Completar 1 ciclo',
      description: 'Completa un ciclo completo (4 pomodoros)',
      type: 'pomodoro_completed',
      targetValue: 4,
      xpReward: 100,
      coinReward: 40,
    ),
    DailyMission(
      id: 'hard_study_120_min',
      title: 'Estudiar 120 minutos',
      description: 'Acumula 120 minutos de enfoque hoy',
      type: 'minutes_studied',
      targetValue: 120,
      xpReward: 100,
      coinReward: 40,
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

    // Select 1 easy mission
    final easyShuffled = List<DailyMission>.from(_easyMissions)..shuffle(random);
    final easy = easyShuffled.first;

    // Select 1 medium mission
    final mediumShuffled = List<DailyMission>.from(_mediumMissions)..shuffle(random);
    final medium = mediumShuffled.first;

    // Select 1 hard mission
    final hardShuffled = List<DailyMission>.from(_hardMissions)..shuffle(random);
    final hard = hardShuffled.first;

    missions = [
      DailyMission(
        id: easy.id,
        title: easy.title,
        description: easy.description,
        type: easy.type,
        targetValue: easy.targetValue,
        currentProgress: 0,
        isClaimed: false,
        xpReward: easy.xpReward,
        coinReward: easy.coinReward,
      ),
      DailyMission(
        id: medium.id,
        title: medium.title,
        description: medium.description,
        type: medium.type,
        targetValue: medium.targetValue,
        currentProgress: 0,
        isClaimed: false,
        xpReward: medium.xpReward,
        coinReward: medium.coinReward,
      ),
      DailyMission(
        id: hard.id,
        title: hard.title,
        description: hard.description,
        type: hard.type,
        targetValue: hard.targetValue,
        currentProgress: 0,
        isClaimed: false,
        xpReward: hard.xpReward,
        coinReward: hard.coinReward,
      ),
    ];

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

  /// Called by FocusProvider or other systems when a relevant event occurs.
  /// [type] matches DailyMission.type, e.g. 'pomodoro_completed'.
  /// [value] is the amount to add (e.g. 1 for a completed pomodoro).
  void updateProgress(String type, int value) {
    bool changed = false;

    for (final mission in missions) {
      if (mission.type == type && !mission.isClaimed) {
        mission.currentProgress += value;
        if (mission.currentProgress < 0) {
          mission.currentProgress = 0;
        }
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
    // Grant the coin reward
    if (mission.coinReward > 0) {
      await profileProvider.modificarMonedas(userId, mission.coinReward);
    }
    return true;
  }

  /// How many missions can still be claimed today.
  int get claimableMissions =>
      missions.where((m) => m.isCompleted && !m.isClaimed).length;
}
