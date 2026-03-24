import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notemefy/data/repositories/note_repository.dart';
import 'package:notemefy/domain/models/note.dart';
import 'package:notemefy/presentation/widgets/smart_trigger_bar.dart';
import 'package:notemefy/services/audio_service.dart';
import 'package:notemefy/services/haptic_service.dart';
import 'package:notemefy/services/geofence_service.dart';
import 'package:notemefy/services/notification_service.dart';

class ThrowActionArea extends ConsumerStatefulWidget {
  final TextEditingController textController;
  final VoidCallback onThrowComplete;

  const ThrowActionArea({
    super.key,
    required this.textController,
    required this.onThrowComplete,
  });

  @override
  ConsumerState<ThrowActionArea> createState() => _ThrowActionAreaState();
}

class _ThrowActionAreaState extends ConsumerState<ThrowActionArea> {

  void _handleThrow() async {
    final text = widget.textController.text.trim();
    if (text.isEmpty) return;

    // Visual feedback

    // Hardware feedback Core Loop
    ref.read(hapticServiceProvider).snapThrow();
    ref.read(audioServiceProvider).playWhoosh();

    // Data layer
    final triggerType = ref.read(selectedTriggerProvider);
    final tag = ref.read(selectedTagProvider);
    
    final note = Note(
      content: text,
      triggerType: triggerType,
      category: tag,
    );

    await ref.read(noteRepositoryProvider).addNote(note);

    DateTime? scheduledFor;

    // Schedule notification if Tonight
    if (triggerType == TriggerType.tonight) {
      scheduledFor = await ref.read(notificationServiceProvider).scheduleTonightTrigger(note);
    } else if (triggerType == TriggerType.custom) {
      final customTime = ref.read(selectedCustomTimeProvider);
      if (customTime != null) {
        final now = DateTime.now();
        var scheduledDate = DateTime(now.year, now.month, now.day, customTime.hour, customTime.minute);
        if (now.isAfter(scheduledDate)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }
        scheduledFor = await ref.read(notificationServiceProvider).scheduleCustomTrigger(note, scheduledDate);
      }
    } else if (triggerType == TriggerType.home || triggerType == TriggerType.work) {
      // Register OS-level geofence
      bool success = await ref.read(geofenceServiceProvider).registerLocationTrigger(note);
      if (!success) {
         await ref.read(noteRepositoryProvider).deleteNote(note.id);
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed. Ensure App Settings has your Home/Work Location and "Allow all the time" permission granted.', style: TextStyle(color: Colors.white)),
                backgroundColor: Colors.redAccent,
                duration: Duration(seconds: 4),
              )
            );
         }
         return;
      }
    }

    if (scheduledFor != null) {
      final updatedNote = note.copyWith(triggerValue: scheduledFor.toIso8601String());
      await ref.read(noteRepositoryProvider).updateNote(updatedNote);
    }

    // Reset UI
    widget.onThrowComplete();
    
    String message = 'Note caught for ${triggerType.name}';
    if (scheduledFor != null) {
      final h = scheduledFor.hour;
      final m = scheduledFor.minute;
      final isPm = h >= 12;
      final displayH = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      final displayM = m.toString().padLeft(2, '0');
      message = 'Note caught! Scheduled for $displayH:$displayM ${isPm ? 'PM' : 'AM'}';
    }

    if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text(message, style: const TextStyle(color: Colors.white)),
           backgroundColor: Colors.grey[900],
           duration: const Duration(milliseconds: 2500),
           behavior: SnackBarBehavior.floating,
         )
       );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SmartTriggerBar(),
        const SizedBox(height: 16),
        
        // The Save Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _handleThrow,
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text(
                'Save Note',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8), // Padding for bottom edge
      ],
    );
  }
}
