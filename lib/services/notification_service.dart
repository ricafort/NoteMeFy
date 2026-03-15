import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notemefy/domain/models/note.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    
    // Request permissions for iOS/Android 13+
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> scheduleTonightTrigger(Note note) async {
    // Schedule for 8:00 PM today, or tomorrow if it's already past 8:00 PM
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, 20, 0); // 8:00 PM
    if (now.isAfter(scheduledDate)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _scheduleNotification(note, scheduledDate);
  }

  Future<void> scheduleCustomTrigger(Note note, DateTime scheduledDate) async {
    await _scheduleNotification(note, scheduledDate);
  }

  Future<void> _scheduleNotification(Note note, DateTime scheduledDate) async {
    // We use the ID hashcode as the notification ID
    final int notificationId = note.id.hashCode;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      'NoteMeFy Reminder',
      note.content,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'notemefy_channel',
          'NoteMeFy Reminders',
          channelDescription: 'Reminders for your notes',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelNotification(String noteId) async {
    await flutterLocalNotificationsPlugin.cancel(noteId.hashCode);
  }

  Future<void> showNotification({required int id, required String title, required String body}) async {
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'notemefy_geofence',
          'NoteMeFy Location Alerts',
          channelDescription: 'Alerts when you arrive at Home or Work',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
