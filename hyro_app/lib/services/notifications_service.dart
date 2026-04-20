import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:timezone/timezone.dart' as tz;

class NotificationsService {
  static final NotificationsService _instance = NotificationsService._();
  static NotificationsService get instance => _instance;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static final _random = Random();

  NotificationsService._();

  // ─── Notification ID Ranges ──────────────────────────────────────
  // 0-2     = Test notifications (debug buttons)
  // 100     = Pomodoro timer
  // 200     = Morning daily
  // 201     = Afternoon daily
  // 202     = Evening daily
  // 300-399 = Task due reminders
  // ─────────────────────────────────────────────────────────────────

  // ═══════════════════════════════════════════════════════════════════
  // MESSAGE BANKS
  // ═══════════════════════════════════════════════════════════════════

  /// Morning messages (8:00 AM) — motivational, energetic
  static const List<String> _morningTitles = [
    '🌅 ¡Buenos días!',
    '☀️ ¡Arriba!',
    '🚀 ¡A por el día!',
    '🎯 ¿Listo para romperla?',
    '💪 ¡Nuevo día, nueva oportunidad!',
  ];

  static const List<String> _morningBodies = [
    'Tienes {n} tareas pendientes. ¡Hoy es un gran día para avanzar!',
    'Tu racha de {streak} días te espera. ¡No la dejes caer!',
    '¡Es hora de ponerse al día! {n} tareas esperan tu atención.',
    'Tienes {n} pendientes. ¡Vamos con todo!',
    'Cada sesión cuenta. ¡Empieza tu día con un Pomodoro!',
  ];

  /// Afternoon messages (2:00 PM) — reminder, push
  static const List<String> _afternoonTitles = [
    '⏰ ¡No lo dejes para después!',
    '📚 ¡Es hora de estudiar!',
    '🔥 ¡Tu racha está en juego!',
    '💡 ¿Un Pomodoro rápido?',
    '⚡ ¡Media tarde perfecta!',
  ];

  static const List<String> _afternoonBodies = [
    'Aún tienes {n} tareas pendientes. ¡Una sesión rápida y avanzas!',
    'Una sesión de enfoque puede marcar la diferencia. ¡Ánimo!',
    'Tu racha de {streak} días necesita un Pomodoro hoy. ¡Dale!',
    '25 minutos de enfoque y listo. ¿Te animas?',
    'Es el momento ideal para avanzar con tus {n} pendientes.',
  ];

  /// Evening messages (8:00 PM) — friendly urgency, day closure
  static const List<String> _eveningTitles = [
    '🌙 Último chance del día',
    '😴 Antes de dormir...',
    '🌟 ¡No pierdas tu racha!',
    '📖 Cierra el día con broche de oro',
    'Hyro se pregunta...',
  ];

  static const List<String> _eveningBodies = [
    '¿Hiciste tu sesión para mantener tu racha de {streak} días?',
    '¿Completaste al menos un Pomodoro hoy? Aún hay tiempo.',
    'Aún hay tiempo para una sesión rápida y proteger tu racha de {streak} días.',
    'Una sesión de enfoque rápida y ¡día ganado!',
    '¿Hoy sí vas a estudiar? ¡No lo decepciones!',
  ];

  /// Streak at risk messages (streak > 0 but no session today)
  static const List<String> _streakRiskTitles = [
    '🔥 ¡Racha en peligro!',
    '😰 ¡No la pierdas!',
    '⚠️ ¡Tu racha te necesita!',
  ];

  static const List<String> _streakRiskBodies = [
    '¡No pierdas tu racha de {streak} días! Haz una sesión ahora para protegerla.',
    'Tu racha de {streak} días está a punto de romperse. ¡Solo necesitas un Pomodoro!',
    'Llevas {streak} días seguidos. ¡No dejes que se pierda por hoy! ',
  ];

  /// Inactivity messages (2+ days without session) — for future use
  // ignore: unused_field
  static const List<String> _inactivityTitles = [
    '😞 Te extrañamos...',
    '👀 ¿Sigues ahí?',
    '🥺 Hyro te extraña',
  ];

  // ignore: unused_field
  static const List<String> _inactivityBodies = [
    'Parece que estas notificaciones no están funcionando. Dejaremos de enviarlas por ahora 😞',
    'Veo que no te importa la racha. ¡Demuéstranos lo contrario!',
    '¿Cuándo vuelves a estudiar? ¡Te estamos esperando!',
  ];

  // ═══════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const WindowsInitializationSettings initializationSettingsWindows =
        WindowsInitializationSettings(
          appName: 'Hyro',
          appUserModelId: 'com.phyrus.hyro',
          guid: 'a1234567-89ab-cdef-0123-456789abcdef',
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
          windows: initializationSettingsWindows,
        );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Manejar el tap en la notificación
      },
    );
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      await [
        Permission.notification,
        Permission.scheduleExactAlarm,
        Permission.ignoreBatteryOptimizations,
      ].request();
    } else if (Platform.isIOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // DAILY SCHEDULED NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════════

  /// Schedules the 3 daily notifications (morning, afternoon, evening).
  /// Uses real data to fill in placeholders.
  /// Call this after loading tasks/stats on app startup and on user change.
  Future<void> scheduleDailyNotifications({
    required int pendingTaskCount,
    required int currentStreak,
    bool hadSessionToday = false,
  }) async {
    // Cancel previous daily notifications before rescheduling
    await _cancelDailyNotifications();

    // Decide message variant based on context
    final bool streakAtRisk = currentStreak > 0 && !hadSessionToday;

    // =========================================================================
    // 💡 NOTA PARA CAMBIAR EL HORARIO DE LAS NOTIFICACIONES:
    // Puedes elegir la hora a la que se mandan modificando el parámetro 'hour'
    // en los recuadros de abajo (ej. hour: 8 para las 8:00 AM).
    // =========================================================================

    // ── Morning 8:00 AM ──
    if (streakAtRisk && currentStreak >= 3) {
      // Use streak risk messages in the morning if streak is at risk
      final idx = _random.nextInt(_streakRiskTitles.length);
      await _scheduleDailyAtTime(
        id: 200,
        hour: 8,
        minute: 0,
        title: _streakRiskTitles[idx],
        body: _fillPlaceholders(
          _streakRiskBodies[idx],
          pendingTaskCount,
          currentStreak,
        ),
      );
    } else {
      final idx = _random.nextInt(_morningTitles.length);
      await _scheduleDailyAtTime(
        id: 200,
        hour: 8,
        minute: 0,
        title: _morningTitles[idx],
        body: _fillPlaceholders(
          _morningBodies[idx],
          pendingTaskCount,
          currentStreak,
        ),
      );
    }

    // ── Afternoon 2:00 PM ──
    {
      final idx = _random.nextInt(_afternoonTitles.length);
      await _scheduleDailyAtTime(
        id: 201,
        hour: 14,
        minute: 0,
        title: _afternoonTitles[idx],
        body: _fillPlaceholders(
          _afternoonBodies[idx],
          pendingTaskCount,
          currentStreak,
        ),
      );
    }

    // ── Evening 8:00 PM ──
    if (streakAtRisk) {
      // If still no session by evening, nudge harder
      final idx = _random.nextInt(_streakRiskTitles.length);
      await _scheduleDailyAtTime(
        id: 202,
        hour: 20,
        minute: 20,
        title: _streakRiskTitles[idx],
        body: _fillPlaceholders(
          _streakRiskBodies[idx],
          pendingTaskCount,
          currentStreak,
        ),
      );
    } else {
      final idx = _random.nextInt(_eveningTitles.length);
      await _scheduleDailyAtTime(
        id: 202,
        hour: 20,
        minute: 0,
        title: _eveningTitles[idx],
        body: _fillPlaceholders(
          _eveningBodies[idx],
          pendingTaskCount,
          currentStreak,
        ),
      );
    }

    debugPrint(
      '📬 Notificaciones diarias programadas (tareas: $pendingTaskCount, racha: $currentStreak)',
    );
  }

  /// Schedules a notification that repeats daily at the given [hour]:[minute].
  Future<void> _scheduleDailyAtTime({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final now = DateTime.now();
    var targetDate = DateTime(now.year, now.month, now.day, hour, minute);

    // If the time has already passed today, schedule for tomorrow
    if (targetDate.isBefore(now)) {
      targetDate = targetDate.add(const Duration(days: 1));
    }

    final scheduledDate = tz.TZDateTime.from(targetDate, tz.local);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'daily_motivation',
          'Motivación Diaria',
          channelDescription:
              'Notificaciones motivacionales a lo largo del día',
          importance: Importance.high,
          priority: Priority.high,
        );
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents:
          DateTimeComponents.time, // Repeat daily at same time
    );
  }

  Future<void> _cancelDailyNotifications() async {
    await flutterLocalNotificationsPlugin.cancel(id: 200);
    await flutterLocalNotificationsPlugin.cancel(id: 201);
    await flutterLocalNotificationsPlugin.cancel(id: 202);
  }

  // ═══════════════════════════════════════════════════════════════════
  // TASK DUE DATE REMINDERS
  // ═══════════════════════════════════════════════════════════════════

  /// Schedules reminder notifications for tasks due in 1 or 2 days.
  /// [tasks] is a list of maps with keys: 'id' (String), 'title' (String), 'dueDate' (DateTime).
  Future<void> scheduleTaskDueReminders(
    List<Map<String, dynamic>> tasks,
  ) async {
    // Cancel all previous task due reminders (range 300-399)
    for (int i = 300; i < 400; i++) {
      await flutterLocalNotificationsPlugin.cancel(id: i);
    }

    final now = DateTime.now();
    int slotIndex = 0;

    for (final task in tasks) {
      if (slotIndex >= 100) break; // Max 100 task reminders

      final dueDate = task['dueDate'] as DateTime?;
      if (dueDate == null) continue;

      final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
      final todayDay = DateTime(now.year, now.month, now.day);

      final daysLeft = dueDay.difference(todayDay).inDays;
      if (daysLeft < 1 || daysLeft > 2) continue;

      final taskTitle = task['title'] as String;
      final notificationId = 300 + slotIndex;
      slotIndex++;

      final String timeLabel = daysLeft == 1 ? 'mañana' : 'en 2 días';
      final String dayLabel = daysLeft == 1 ? '1 día' : '2 días';

      // Pick one of two message styles randomly
      final String title;
      final String body;
      if (_random.nextBool()) {
        title = '⏱️ ¡Se acaba el tiempo!';
        body = 'Tu tarea "$taskTitle" vence en $dayLabel.';
      } else {
        title = '🚨 ¡Atención!';
        body =
            '"$taskTitle" se vence $timeLabel. ¡No la dejes para el último momento!';
      }

      // Schedule at 9:00 AM of today (or tomorrow if passed)
      var targetDate = DateTime(now.year, now.month, now.day, 9, 0);
      if (targetDate.isBefore(now)) {
        targetDate = targetDate.add(const Duration(days: 1));
      }
      final scheduledDate = tz.TZDateTime.from(targetDate, tz.local);

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'task_due_reminders',
            'Tareas por Vencer',
            channelDescription:
                'Alertas para tareas que están por vencer en 1-2 días',
            importance: Importance.max,
            priority: Priority.high,
          );
      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: notificationId,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }

    if (slotIndex > 0) {
      debugPrint(
        '📬 $slotIndex recordatorios de tareas por vencer programados',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // CANCEL ALL
  // ═══════════════════════════════════════════════════════════════════

  /// Cancels all scheduled notifications (daily + task reminders).
  /// Useful on logout or user switch.
  Future<void> cancelAllScheduledNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    debugPrint('🗑️ Todas las notificaciones programadas canceladas');
  }

  // ═══════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════

  /// Replace {n} and {streak} placeholders in message templates.
  String _fillPlaceholders(String template, int taskCount, int streak) {
    return template
        .replaceAll('{n}', taskCount.toString())
        .replaceAll('{streak}', streak.toString());
  }

  // ═══════════════════════════════════════════════════════════════════
  // TEST / DEBUG METHODS — use real message banks + real data
  // ═══════════════════════════════════════════════════════════════════

  Future<void> testTaskReminderDay(String taskName, int daysLeft) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'task_due_reminders',
          'Tareas por Vencer',
          channelDescription:
              'Alertas para tareas que están por vencer en 1-2 días',
          importance: Importance.max,
          priority: Priority.high,
        );
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    final String timeLabel = daysLeft == 1 ? 'mañana' : 'en $daysLeft días';
    final String dayLabel = daysLeft == 1 ? '1 día' : '$daysLeft días';

    final String title;
    final String body;
    if (_random.nextBool()) {
      title = '⏱️ ¡Se acaba el tiempo!';
      body = 'Tu tarea "$taskName" vence en $dayLabel.';
    } else {
      title = '🚨 ¡Atención!';
      body =
          '"$taskName" se vence $timeLabel. ¡No la dejes para el último momento!';
    }

    await flutterLocalNotificationsPlugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: platformDetails,
    );
  }

  /// Test morning notification with real message bank and real data.
  Future<void> testMorningMotivation({
    int pendingTasks = 3,
    int streak = 0,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'daily_motivation',
          'Motivación Diaria',
          channelDescription:
              'Notificaciones motivacionales a lo largo del día',
          importance: Importance.high,
          priority: Priority.high,
        );
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    final idx = _random.nextInt(_morningTitles.length);
    await flutterLocalNotificationsPlugin.show(
      id: 1,
      title: _morningTitles[idx],
      body: _fillPlaceholders(_morningBodies[idx], pendingTasks, streak),
      notificationDetails: platformDetails,
    );
  }

  /// Test afternoon notification with real message bank and real data.
  Future<void> testAfternoonMotivation({
    int pendingTasks = 3,
    int streak = 0,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'daily_motivation',
          'Motivación Diaria',
          channelDescription:
              'Notificaciones motivacionales a lo largo del día',
          importance: Importance.high,
          priority: Priority.high,
        );
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    final idx = _random.nextInt(_afternoonTitles.length);
    await flutterLocalNotificationsPlugin.show(
      id: 1,
      title: _afternoonTitles[idx],
      body: _fillPlaceholders(_afternoonBodies[idx], pendingTasks, streak),
      notificationDetails: platformDetails,
    );
  }

  /// Test evening notification with real message bank and real data.
  Future<void> testEveningMotivation({
    int pendingTasks = 3,
    int streak = 0,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'daily_motivation',
          'Motivación Diaria',
          channelDescription:
              'Notificaciones motivacionales a lo largo del día',
          importance: Importance.high,
          priority: Priority.high,
        );
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    final idx = _random.nextInt(_eveningTitles.length);
    await flutterLocalNotificationsPlugin.show(
      id: 1,
      title: _eveningTitles[idx],
      body: _fillPlaceholders(_eveningBodies[idx], pendingTasks, streak),
      notificationDetails: platformDetails,
    );
  }

  /// Test pomodoro end with real messages.
  Future<void> testPomodoroEnd() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'pomodoro_timer',
          'Temporizador Pomodoro',
          channelDescription:
              'Notificaciones sobre los descansos y bloques de estudio',
          importance: Importance.max,
          priority: Priority.high,
        );
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    // Randomly pick pomodoro or break end message
    final isPomodoro = _random.nextBool();
    final title =
        isPomodoro ? '🎯 ¡Pomodoro completado!' : '🔔 ¡Se acabó el descanso!';
    final body =
        isPomodoro
            ? 'Buen trabajo. ¡Es hora de un merecido descanso!'
            : 'Es hora de volver al ruedo y seguir rompiéndola.';

    await flutterLocalNotificationsPlugin.show(
      id: 2,
      title: title,
      body: body,
      notificationDetails: platformDetails,
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // POMODORO TIMER NOTIFICATIONS (existing)
  // ═══════════════════════════════════════════════════════════════════

  Future<void> schedulePomodoroEndNotification(
    bool isPomodoro,
    int secondsRemaining,
  ) async {
    const int notificationId = 100;
    String title =
        isPomodoro ? '🎯 ¡Pomodoro completado!' : '🔔 ¡Se acabó el descanso!';
    String body =
        isPomodoro
            ? 'Buen trabajo. ¡Es hora de un merecido descanso!'
            : 'Es hora de volver al ruedo y seguir rompiéndola.';

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'pomodoro_timer',
          'Temporizador Pomodoro',
          channelDescription:
              'Notificaciones sobre los descansos y bloques de estudio',
          importance: Importance.max,
          priority: Priority.high,
        );
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    final targetTime = DateTime.now().add(Duration(seconds: secondsRemaining));
    final scheduledDate = tz.TZDateTime.from(targetTime, tz.local);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: notificationId,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelPomodoroNotification() async {
    await flutterLocalNotificationsPlugin.cancel(id: 100);
  }

  // ═══════════════════════════════════════════════════════════════════
  // INDIVIDUAL TASK REMINDERS (existing — for 30min before dueDate)
  // ═══════════════════════════════════════════════════════════════════

  Future<void> scheduleTaskReminder(
    String taskId,
    String taskTitle,
    DateTime? dueDate,
    bool isCompleted,
  ) async {
    if (dueDate == null || isCompleted) {
      await cancelTaskReminder(taskId);
      return;
    }

    // Check if dueDate is in the past
    if (dueDate.isBefore(DateTime.now())) return;

    DateTime targetTime = dueDate.subtract(const Duration(minutes: 30));
    if (targetTime.isBefore(DateTime.now())) {
      targetTime = dueDate; // try exact time
      if (targetTime.isBefore(DateTime.now())) return;
    }

    final int notificationId = taskId.hashCode;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'task_reminders',
          'Recordatorios de Tareas',
          channelDescription: 'Alertas para tareas que están por vencer',
          importance: Importance.max,
          priority: Priority.high,
        );
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    final scheduledDate = tz.TZDateTime.from(targetTime, tz.local);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: notificationId,
      title: '⏱️ ¡Se acaba el tiempo!',
      body: 'Tu tarea "$taskTitle" está por vencer.',
      scheduledDate: scheduledDate,
      notificationDetails: platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelTaskReminder(String taskId) async {
    await flutterLocalNotificationsPlugin.cancel(id: taskId.hashCode);
  }
}
