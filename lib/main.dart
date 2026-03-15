import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notemefy/data/repositories/note_repository.dart';
import 'package:notemefy/presentation/screens/capture_screen.dart';
import 'package:notemefy/services/quick_action_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:native_geofence/native_geofence.dart';

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

  // Initialize Local Hive Database
  final noteRepo = NoteRepository();
  await noteRepo.init();
  await Hive.openBox('settingsBox');

  // Initialize native background geofencing OS listeners
  try {
    await NativeGeofenceManager.instance.initialize();
  } catch (e) {
    debugPrint('native_geofence setup error: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        noteRepositoryProvider.overrideWithValue(noteRepo),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    QuickActionService().init(navigatorKey);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'NoteMeFy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black, // True AMOLED Black
        useMaterial3: true,
        fontFamily: 'Roboto', // Default fast-loading font
      ),
      home: const CaptureScreen(),
    );
  }
}
