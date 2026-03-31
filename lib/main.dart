import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notemefy/data/repositories/note_repository.dart';
import 'package:notemefy/presentation/screens/capture_screen.dart';
import 'package:notemefy/presentation/screens/review_screen.dart';
import 'package:notemefy/services/quick_action_service.dart';
import 'package:notemefy/services/notification_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:native_geofence/native_geofence.dart';
import 'package:notemefy/services/geofence_service.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enforce zero-distraction UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.dark, // hide nav bar icons basically
    ),
  );

  // TUTORIAL: Zero-asynchronous-blocking storage.
  // Hive stores data as pure Key-Value pairs that load synchronously into memory
  // upon opening the box. This is why NoteMeFy can launch in <0.5s without a loading spinner.
  final noteRepo = NoteRepository();
  await noteRepo.init();
  await Hive.openBox('settingsBox');

  // Initialize native background geofencing OS listeners
  try {
    await NativeGeofenceManager.instance.initialize();
  } catch (e) {
    debugPrint('native_geofence setup error: $e');
  }

  // Cleanup orphaned geofences using AppGeofenceService
  final geofenceService = AppGeofenceService();
  await geofenceService.syncGeofencesWithNotes(noteRepo.getActiveNotes());

  // Extract the launch payload BEFORE initialize() is ever called.
  // On iOS, if we wait until the app builds to check this, the delegate event is natively dropped.
  String? initialPayload;
  try {
    final details = await FlutterLocalNotificationsPlugin().getNotificationAppLaunchDetails();
    if (details != null && details.didNotificationLaunchApp && details.notificationResponse != null) {
      initialPayload = details.notificationResponse?.payload;
    }
  } catch (e) {
    debugPrint('NoteMeFy: Failed to get launch details early: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        noteRepositoryProvider.overrideWithValue(noteRepo),
      ],
      child: MyApp(initialPayload: initialPayload),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  final String? initialPayload;
  const MyApp({super.key, this.initialPayload});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    QuickActionService().init(navigatorKey);
    // Initialize synchronously so iOS does not drop the native cold-start notification event.
    ref.read(notificationServiceProvider).init();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Prioritize the payload retrieved from main() before anything else!
      // If none, check if the stream somehow caught one during synchronous init.
      final payload = widget.initialPayload ?? ref.read(notificationServiceProvider).payloadStream.valueOrNull;

      if (payload != null) {
        if (navigatorKey.currentState != null) {
          navigatorKey.currentState!.push(
            MaterialPageRoute(
              settings: const RouteSettings(name: '/review'),
              builder: (context) => ReviewScreen(initialNoteId: payload),
            ),
          );
          // Clear it so ReviewScreen doesn't process it a second time via stream listener
          ref.read(notificationServiceProvider).payloadStream.add(null);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'NoteMeFy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        // TUTORIAL: Pure AMOLED Black (Colors.black / #000000) turns off individual pixels on OLED screens.
        // This saves significant battery life for an app designed to be opened hundreds of times a day.
        scaffoldBackgroundColor: Colors.black, // True AMOLED Black
        useMaterial3: true,
        fontFamily: 'Roboto', // Default fast-loading font
      ),
      home: const CaptureScreen(),
    );
  }
}
