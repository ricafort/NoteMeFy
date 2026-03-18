import 'package:hive_flutter/hive_flutter.dart';
import 'package:notemefy/domain/models/note.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:native_geofence/native_geofence.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

// TUTORIAL: We use Riverpod's Provider to inject our bare repository class.
// This decouples the UI from the database implementation, allowing us to swap
// it out for a mock version during testing without changing UI code.
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepository();
});

// TUTORIAL: StreamProvider is the secret to reactive UIs. Instead of writing
// complex listeners, this provider automatically transforms a Stream from Hive
// into an AsyncValue (data, loading, or error) that the UI can easily handle.
final notesStreamProvider = StreamProvider<List<Note>>((ref) {
  final repo = ref.watch(noteRepositoryProvider);
  return repo.watchAllNotes();
});

class NoteRepository {
  static const String _boxName = 'notes';

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(NoteAdapter());
    await Hive.openBox<Note>(_boxName);
  }

  Box<Note> get _box => Hive.box<Note>(_boxName);

  Future<void> addNote(Note note) async {
    await _box.put(note.id, note);
  }

  Future<void> updateNote(Note note) async {
    await _box.put(note.id, note);
    
    // Clear out any background OS geofences if disabled so we don't get ghost notifications
    if (!note.isActive) {
      try {
        await NativeGeofenceManager.instance.removeGeofenceById(note.id);
      } catch (e) {
        debugPrint('Error cleaning up geofence for updated inactive note: $e');
      }
    }
  }

  Future<void> deleteNote(String id) async {
    // 1. Delete from simple local storage
    await _box.delete(id);
    
    // 2. Clear out any background OS geofences so we don't get ghost notifications
    try {
      await NativeGeofenceManager.instance.removeGeofenceById(id);
      
      // Cleanup the background string as well
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('note_$id');
    } catch (e) {
      debugPrint('Error cleaning up geofence for deleted note: $e');
    }
  }

  List<Note> getAllNotes() {
    return _box.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // TUTORIAL: async* and yield are used to create a Stream generator in Dart.
  // We first yield the current state, and then continuously watch the Hive box.
  // Every time a note is added, updated, or deleted, the box emits an event,
  // causing us to yield a fresh, sorted list to the UI instantly.
  Stream<List<Note>> watchAllNotes() async* {
    yield getAllNotes();
    await for (final _ in _box.watch()) {
      yield getAllNotes();
    }
  }

  List<Note> getActiveNotes() {
    return _box.values.where((note) => note.isActive).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}
