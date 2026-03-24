import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notemefy/data/repositories/note_repository.dart';
import 'package:notemefy/domain/models/note.dart';
import 'package:notemefy/services/haptic_service.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:notemefy/services/pro_upgrade_service.dart';
import 'package:notemefy/services/notification_service.dart';
import 'package:intl/intl.dart';
import 'package:notemefy/presentation/screens/settings_screen.dart';
import 'package:notemefy/services/font_settings_service.dart';
import 'package:native_geofence/native_geofence.dart';
import 'package:notemefy/services/geofence_service.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  final String? initialNoteId;

  const ReviewScreen({super.key, this.initialNoteId});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  bool _hasOpenedInitialNote = false;
  StreamSubscription<String?>? _payloadSub;

  @override
  void initState() {
    super.initState();
    _payloadSub = ref.read(notificationServiceProvider).payloadStream.listen((payload) {
        if (payload != null && mounted) {
           debugPrint('NoteMeFy: ReviewScreen Stream caught payload tap: $payload');
           
           // We must check if the notes are available in provider already:
           final notes = ref.read(notesStreamProvider).value;
           if (notes != null) {
              final targetNote = notes.where((n) => n.id == payload).firstOrNull;
              if (targetNote != null) {
                showNoteEditSheet(context, ref, ref.read(fontSettingsProvider), targetNote);
              }
           }
        }
    });
  }

  @override
  void dispose() {
    _payloadSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the reactive stream of notes
    final notesAsync = ref.watch(notesStreamProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Captured Ideas', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 32),
          onPressed: () {
            ref.read(hapticServiceProvider).click();
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white54),
            onPressed: () {
              ref.read(hapticServiceProvider).click();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: notesAsync.when(
        data: (notes) {
          if (notes.isEmpty) {
            return const Center(
              child: Text(
                'Mind is clear.',
                style: TextStyle(color: Colors.white24, fontSize: 18),
              ),
            );
          }

          if (widget.initialNoteId != null && !_hasOpenedInitialNote) {
            debugPrint('NoteMeFy: ReviewScreen received initialNoteId: ${widget.initialNoteId}');
            final targetNote = notes.where((n) => n.id == widget.initialNoteId).firstOrNull;
            debugPrint('NoteMeFy: Found matching note: ${targetNote != null}');
            if (targetNote != null) {
              _hasOpenedInitialNote = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                 if (mounted) {
                   debugPrint('NoteMeFy: Automatically opening edit sheet for ${targetNote.id}');
                   showNoteEditSheet(context, ref, ref.read(fontSettingsProvider), targetNote);
                 }
              });
            }
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return _NoteCard(note: note);
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
        error: (error, stackTrace) => Center(
          child: Text(
            'Cannot load ideas: $error',
            style: const TextStyle(color: Colors.redAccent, fontSize: 16),
          ),
        ),
      ),
    );
  }
}

class _NoteCard extends ConsumerWidget {
  final Note note;

  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBusiness = note.category == 'Business';
    final settings = ref.watch(fontSettingsProvider);

    return GestureDetector(
      onTap: () => showNoteEditSheet(context, ref, settings, note),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isBusiness ? Colors.amber.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1)),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _getIconForTrigger(note.triggerType),
                    size: 16,
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    note.triggerType.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              if (isBusiness)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('WORK', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            note.content,
            style: TextStyle(color: Colors.white, fontSize: settings.fontSize * 0.6, height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('MMM d, h:mm a').format(note.createdAt),
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                    if (note.triggerValue != null && (note.triggerType == TriggerType.tonight || note.triggerType == TriggerType.custom)) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Scheduled:\n${DateFormat('MMM d, h:mm a').format(DateTime.tryParse(note.triggerValue!) ?? note.createdAt)}',
                        style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                children: [
                  Switch(
                    value: note.isActive,
                    onChanged: (val) async {
                      ref.read(hapticServiceProvider).click();
                      
                      // Intercept Premium Location Features
                      if (val && (note.triggerType == TriggerType.home || note.triggerType == TriggerType.work)) {
                        final isPro = ref.read(proUpgradeProvider);
                        if (!isPro) {
                          await RevenueCatUI.presentPaywallIfNeeded("NoteMeFy Pro");
                          return;
                        }
                      }
                      
                      final updated = note.copyWith(isActive: val);
                      await ref.read(noteRepositoryProvider).updateNote(updated);
                      
                      if (!val) {
                        // Cancel the notification if the note is disabled
                        await ref.read(notificationServiceProvider).cancelNotification(note.id);
                        try {
                          await NativeGeofenceManager.instance.removeGeofenceById(note.id);
                        } catch (e) {
                          debugPrint('Error cleaning geofence on disable: $e');
                        }
                      } else {
                        // Reschedule if re-enabled (simplified tonight logic for now)
                        if (note.triggerType == TriggerType.tonight) {
                          final newDt = await ref.read(notificationServiceProvider).scheduleTonightTrigger(updated);
                          await ref.read(noteRepositoryProvider).updateNote(updated.copyWith(triggerValue: newDt.toIso8601String()));
                        } else if (note.triggerType == TriggerType.custom && note.triggerValue != null) {
                          final dt = DateTime.tryParse(note.triggerValue!);
                          if (dt != null && dt.isAfter(DateTime.now())) {
                             await ref.read(notificationServiceProvider).scheduleCustomTrigger(updated, dt);
                          } else {
                             // Revert toggle if it's already past
                             await ref.read(noteRepositoryProvider).updateNote(updated.copyWith(isActive: false));
                          }
                        } else if (note.triggerType == TriggerType.home || note.triggerType == TriggerType.work) {
                          bool success = await ref.read(geofenceServiceProvider).registerLocationTrigger(updated);
                          if (!success) {
                            // Revert toggle
                            await ref.read(noteRepositoryProvider).updateNote(note.copyWith(isActive: false));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to re-enable location trigger. Check permissions and App Settings.', style: TextStyle(color: Colors.white)),
                                  backgroundColor: Colors.redAccent,
                                  duration: Duration(seconds: 4),
                                )
                              );
                            }
                          }
                        }
                      }
                    },
                    activeTrackColor: Colors.blueAccent.withValues(alpha: 0.5),
                    activeThumbColor: Colors.blueAccent,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white38),
                    onPressed: () async {
                      ref.read(hapticServiceProvider).click();
                      await ref.read(noteRepositoryProvider).deleteNote(note.id);
                      // Cancel service worker notification
                      await ref.read(notificationServiceProvider).cancelNotification(note.id);
                    },
                  ),
                ],
              )
            ],
          )
        ],
      ),
    ),
  );
}

  IconData _getIconForTrigger(TriggerType type) {
    switch (type) {
      case TriggerType.home:
        return Icons.home_rounded;
      case TriggerType.work:
        return Icons.business_rounded;
      case TriggerType.tonight:
        return Icons.nights_stay_rounded;
      case TriggerType.custom:
        return Icons.access_time_filled_rounded;
      case TriggerType.routine:
        return Icons.star_rounded;
    }
  }
}

void showNoteEditSheet(BuildContext context, WidgetRef ref, FontSettings settings, Note note) async {
  final textController = TextEditingController(text: note.content);
  
  // Wait slightly to ensure any screen push transition is completely finished 
  // before attempting to render a ModalBottomSheet on top of it.
  await Future.delayed(const Duration(milliseconds: 350));
  if (!context.mounted) return;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
            ),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Idea', style: TextStyle(color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: TextField(
                    controller: textController,
                    autofocus: true,
                    maxLines: null,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: settings.fontSize * 0.7,
                      height: 1.4,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Type an idea...',
                      hintStyle: TextStyle(color: Colors.white24),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () async {
                    if (textController.text.trim().isEmpty) return;
                    ref.read(hapticServiceProvider).click();
                    
                    final updated = note.copyWith(content: textController.text.trim());
                    await ref.read(noteRepositoryProvider).updateNote(updated);
                    
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Update Note', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  },
  );
}
