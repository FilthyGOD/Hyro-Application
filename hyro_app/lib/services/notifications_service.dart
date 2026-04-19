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

  NotificationsService._();

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

    const InitializationSettings initializationSettings = InitializationSettings(
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
      ].request();
    } else if (Platform.isIOS) {
       await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  Future<void> testTaskReminderDay(String taskName, int daysLeft) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
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

    String tiempoTermino = daysLeft == 1 ? '1 día' : '$daysLeft días';

    await flutterLocalNotificationsPlugin.show(
      id: 0,
      title: '⏱️ ¡Se acaba el tiempo!',
      body: 'Tu tarea "$taskName" está por vencer en $tiempoTermino.',
      notificationDetails: platformDetails,
    );
  }

  Future<void> testMorningMotivation() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'motivation',
      'Motivación Diaria',
      channelDescription: 'Mensajes motivacionales matutinos',
      importance: Importance.high,
      priority: Priority.high,
    );
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await flutterLocalNotificationsPlugin.show(
      id: 1,
      title: '🌅 ¡Buenos días!',
      body: 'Tienes 3 tareas para hoy. ¡Es un buen día para avanzar!',
      notificationDetails: platformDetails,
    );
  }

  Future<void> testPomodoroEnd() async {
     const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pomodoro_timer',
      'Temporizador Pomodoro',
      channelDescription: 'Notificaciones sobre los descansos y bloques de estudio',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await flutterLocalNotificationsPlugin.show(
      id: 2,
      title: '🎯 ¡Pomodoro completado!',
      body: 'Gran trabajo. Tómate un merecido descanso de 5 minutos.',
      notificationDetails: platformDetails,
    );
  }

  Future<void> schedulePomodoroEndNotification(bool isPomodoro, int secondsRemaining) async {
    const int notificationId = 100;
    String title = isPomodoro ? '🎯 ¡Pomodoro completado!' : '🔔 ¡Se acabó el descanso!';
    String body = isPomodoro 
        ? 'Buen trabajo. ¡Es hora de un merecido descanso!' 
        : 'Es hora de volver al ruedo y seguir rompiéndola.';

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pomodoro_timer',
      'Temporizador Pomodoro',
      channelDescription: 'Notificaciones sobre los descansos y bloques de estudio',
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

  Future<void> scheduleTaskReminder(String taskId, String taskTitle, DateTime? dueDate, bool isCompleted) async {
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

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
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
