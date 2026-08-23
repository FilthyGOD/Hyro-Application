import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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

  // ─── Rangos de ID de notificaciones ──────────────────────────────
  // 0-2     = Notificaciones de prueba (botones de depuración)
  // 100     = Temporizador Pomodoro
  // 200     = Diaria de la mañana
  // 201     = Diaria de la tarde
  // 202     = Diaria de la noche
  // 300-399 = Recordatorios de vencimiento de tareas
  // ─────────────────────────────────────────────────────────────────

  // ═══════════════════════════════════════════════════════════════════
  // BANCOS DE MENSAJES
  // ═══════════════════════════════════════════════════════════════════

  /// Mensajes matutinos (8:00 AM) — motivadores, enérgicos
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

  /// Mensajes de la tarde (2:00 PM) — recordatorios, empujón
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

  /// Mensajes vespertinos (8:00 PM) — urgencia amigable, cierre del día
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

  /// Mensajes de riesgo de racha (racha > 0 pero sin sesión hoy)
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

  /// Mensajes de inactividad (2+ días sin sesión) — para uso futuro
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
  // INICIALIZACIÓN
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
        // Asegúrate de usar el ID correcto para pruebas (por ejemplo, id = 0, 1 o 2);
      },
    );
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return;
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
  // NOTIFICACIONES DIARIAS PROGRAMADAS
  // ═══════════════════════════════════════════════════════════════════

  /// Programa las 3 notificaciones diarias (mañana, tarde, noche).
  /// Utiliza datos reales para llenar los marcadores de posición.
  /// Llama a esto después de cargar tareas/estadísticas al inicio y al cambiar de usuario.
  Future<void> scheduleDailyNotifications({
    required int pendingTaskCount,
    required int currentStreak,
    bool hadSessionToday = false,
  }) async {
    // Cancela notificaciones diarias anteriores antes de reprogramar
    await _cancelDailyNotifications();

    // Decide la variante del mensaje según el contexto
    final bool streakAtRisk = currentStreak > 0 && !hadSessionToday;

    // =========================================================================
    // 💡 NOTA PARA CAMBIAR EL HORARIO DE LAS NOTIFICACIONES:
    // Puedes elegir la hora a la que se mandan modificando el parámetro 'hour'
    // en los recuadros de abajo (ej. hour: 8 para las 8:00 AM).
    // =========================================================================

    // ── Mañana 8:00 AM ──
    if (streakAtRisk && currentStreak >= 3) {
      // Usa mensajes de riesgo de racha en la mañana si la racha está en riesgo
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

    // ── Tarde 2:00 PM ──
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

    // ── Noche 8:00 PM ──
    if (streakAtRisk) {
      // Si aún no hay sesión para la noche, presiona un poco más
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

  /// Programa una notificación que se repite diariamente a la [hour]:[minute] especificada.
  Future<void> _scheduleDailyAtTime({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final now = DateTime.now();
    var targetDate = DateTime(now.year, now.month, now.day, hour, minute);

    // Si la hora ya pasó hoy, programar para mañana
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
          DateTimeComponents.time, // Repetir diariamente a la misma hora
    );
  }

  Future<void> _cancelDailyNotifications() async {
    await flutterLocalNotificationsPlugin.cancel(id: 200);
    await flutterLocalNotificationsPlugin.cancel(id: 201);
    await flutterLocalNotificationsPlugin.cancel(id: 202);
  }

  // ═══════════════════════════════════════════════════════════════════
  // RECORDATORIOS DE VENCIMIENTO DE TAREAS
  // ═══════════════════════════════════════════════════════════════════

  /// Programa notificaciones de recordatorio para tareas que vencen en 1 o 2 días.
  /// [tasks] es una lista de mapas con claves: 'id' (String), 'title' (String), 'dueDate' (DateTime).
  Future<void> scheduleTaskDueReminders(
    List<Map<String, dynamic>> tasks,
  ) async {
    // Cancela los recordatorios anteriores de tareas (rango 300-399)
    for (int i = 300; i < 400; i++) {
      await flutterLocalNotificationsPlugin.cancel(id: i);
    }

    final now = DateTime.now();
    int slotIndex = 0;

    for (final task in tasks) {
      if (slotIndex >= 100) break; // Máximo 100 recordatorios de tareas

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

      // Elige uno de dos estilos de mensaje aleatoriamente
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

      // Programar para mañana
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
  // CANCELAR TODAS
  // ═══════════════════════════════════════════════════════════════════

  /// Cancela todas las notificaciones programadas (diarias + recordatorios de tareas).
  /// Útil al cerrar sesión o cambiar de usuario.
  Future<void> cancelAllScheduledNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    debugPrint('🗑️ Todas las notificaciones programadas canceladas');
  }

  // ═══════════════════════════════════════════════════════════════════
  // FUNCIONES AUXILIARES
  // ═══════════════════════════════════════════════════════════════════

  /// Reemplaza {n} y {streak} con valores reales.
  String _fillPlaceholders(String template, int taskCount, int streak) {
    return template
        .replaceAll('{n}', taskCount.toString())
        .replaceAll('{streak}', streak.toString());
  }

  // ═══════════════════════════════════════════════════════════════════
  // MÉTODOS DE PRUEBA / DEPURACIÓN — usan bancos de mensajes reales + datos reales
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

  /// Muestra una notificación inmediata de prueba con un título, cuerpo y payload fijos.
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

  /// Prueba la notificación de la tarde con banco de mensajes reales y datos reales.
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

  /// Prueba la notificación de la noche con banco de mensajes reales y datos reales.
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

  /// Prueba de finalización de pomodoro con mensajes reales.
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

    // Elige aleatoriamente un mensaje de fin de pomodoro o de descanso
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
  // NOTIFICACIONES DEL TEMPORIZADOR POMODORO (existente)
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
  // RECORDATORIOS INDIVIDUALES DE TAREAS (existente — 30min antes del vencimiento)
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

    // Verificar si la fecha de vencimiento ya pasó
    if (dueDate.isBefore(DateTime.now())) return;

    DateTime targetTime = dueDate.subtract(const Duration(minutes: 30));
    if (targetTime.isBefore(DateTime.now())) {
      targetTime = dueDate; // intentar hora exacta
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
