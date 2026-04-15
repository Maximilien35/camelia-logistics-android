import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();

    await _notificationsPlugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        macOS: DarwinInitializationSettings(),
      ),
    );
  }

  static Future<void> showReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    final tz.TZDateTime tzScheduled = tz.TZDateTime.from(
      scheduledTime,
      tz.local,
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel',
          'Rappels',
          channelDescription: 'Rappels temps',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  static Future<void> cancel(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
