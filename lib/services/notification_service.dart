import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notemefy/domain/models/note.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:notemefy/presentation/screens/review_screen.dart';
import 'package:notemefy/main.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(navigatorKey: navigatorKey);
});

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // We need the navigatorKey to navigate when a notification is tapped
  final GlobalKey<NavigatorState>? navigatorKey;
  
  // Stream to allow UI components to listen to payload taps when already foregrounded
  final BehaviorSubject<String?> payloadStream = BehaviorSubject<String?>();

  NotificationService({this.navigatorKey});

  Future<void> init({bool isBackground = false}) async {
    tz.initializeTimeZones();
    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
    } catch (e) {
      debugPrint('Could not get local timezone: $e');
    }
    
    if (!isBackground) {
      // Request permissions for iOS/Android 13+
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // When user taps the notification
        debugPrint('NoteMeFy: Notification tapped with payload: ${response.payload}');
        if (response.payload != null) {
          debugPrint('NoteMeFy: Sink payload to stream: ${response.payload}');
          payloadStream.add(response.payload);
          
          if (navigatorKey != null && navigatorKey!.currentState != null) {
            bool isReviewScreenOpen = false;
            
            // Pop any extraneous bottom sheets or settings screens that might be active
            navigatorKey!.currentState?.popUntil((route) {
              if (route.settings.name == '/review') {
                isReviewScreenOpen = true;
              }
              return route.isFirst || route.settings.name == '/review';
            });

            if (isReviewScreenOpen) {
              // We are already on ReviewScreen. Just sink the payload to open the specific sheet.
              payloadStream.add(response.payload);
            } else {
              // We are on the CaptureScreen. Push a fresh ReviewScreen.
              navigatorKey!.currentState?.push(
                MaterialPageRoute(
                  settings: const RouteSettings(name: '/review'),
                  builder: (context) => ReviewScreen(initialNoteId: response.payload),
                ),
              );
            }
          }
        }
      },
    );
  }

  void dispose() {
    payloadStream.close();
  }

  Future<DateTime> scheduleTonightTrigger(Note note) async {
    // Read the user's preferred "Tonight" time
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('tonight_hour') ?? 20;   // Default 8:00 PM
    final minute = prefs.getInt('tonight_minute') ?? 0;

    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
    if (now.isAfter(scheduledDate)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _scheduleNotification(note, scheduledDate);
    return scheduledDate;
  }

  Future<DateTime> scheduleCustomTrigger(Note note, DateTime scheduledDate) async {
    await _scheduleNotification(note, scheduledDate);
    return scheduledDate;
  }

  Future<void> _scheduleNotification(Note note, DateTime scheduledDate) async {
    // We use the ID hashcode as the notification ID
    final int notificationId = note.id.hashCode.abs();

    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      'NoteMeFy Reminder',
      note.content,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'notemefy_channel_v2',
          'NoteMeFy Reminders',
          channelDescription: 'Reminders for your notes',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: note.id,
    );
  }

  Future<void> cancelNotification(String noteId) async {
    await flutterLocalNotificationsPlugin.cancel(noteId.hashCode);
  }

  Future<void> showNotification({required int id, required String title, required String body, String? payload}) async {
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
      payload: payload ?? id.toString(), // We can use note.id or a generic identifier
    );
  }
}
