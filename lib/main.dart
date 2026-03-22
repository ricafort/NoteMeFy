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

  runApp(
    ProviderScope(
      overrides: [
        noteRepositoryProvider.overrideWithValue(noteRepo),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    QuickActionService().init(navigatorKey);
    // Initialize notifications to handle taps while the app is foregrounded or starting up
    ref.read(notificationServiceProvider).init();
    
    // Handle the case where the app was completely terminated and launched via a notification tap
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final details = await ref.read(notificationServiceProvider).flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
      if (details != null && details.didNotificationLaunchApp && details.notificationResponse != null) {
        final payload = details.notificationResponse?.payload;
        if (payload != null && navigatorKey.currentState != null) {
          navigatorKey.currentState!.push(
            MaterialPageRoute(
              settings: const RouteSettings(name: '/review'),
              builder: (context) => ReviewScreen(initialNoteId: payload),
            ),
          );
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
