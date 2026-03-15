import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:notemefy/services/font_settings_service.dart';
import 'package:notemefy/services/haptic_service.dart';
import 'package:notemefy/services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provides the current "Tonight" time locally for the UI to display reactively
final tonightTimeProvider = NotifierProvider<TonightTimeNotifier, TimeOfDay>(
  () {
    return TonightTimeNotifier();
  },
);

// TUTORIAL: Riverpod 2.0 State Management
// In older Riverpod, we used `StateNotifier`. But it was often clunky to initialize asynchronous data immediately.
// The new `Notifier<T>` pattern provides a safe `build()` method where we can set our default state
// while simultaneously firing off an async `_loadTime()` fetch. When `state` is mutated later,
// the UI instantly rebuilds where `ref.watch(tonightTimeProvider)` is called!
class TonightTimeNotifier extends Notifier<TimeOfDay> {
  @override
  TimeOfDay build() {
    _loadTime();
    return const TimeOfDay(hour: 20, minute: 0);
  }

  Future<void> _loadTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('tonight_hour') ?? 20;
    final minute = prefs.getInt('tonight_minute') ?? 0;
    state = TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> updateTime(TimeOfDay newTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tonight_hour', newTime.hour);
    await prefs.setInt('tonight_minute', newTime.minute);
    state = newTime;
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(fontSettingsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Typography',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 32),

                const Text(
                  'Font Size',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      'A',
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                    Expanded(
                      child: Slider(
                        value: settings.fontSize,
                        min: 8.0,
                        max: 40.0,
                        divisions: 32,
                        activeColor: Colors.blueAccent,
                        onChanged: (val) {
                          ref
                              .read(fontSettingsProvider.notifier)
                              .updateFontSize(val);
                        },
                        onChangeEnd: (_) {
                          ref.read(hapticServiceProvider).click();
                        },
                      ),
                    ),
                    const Text(
                      'A',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                const Text(
                  'Preview',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Text(
                    'The quick brown fox jumps over the lazy dog.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: settings.fontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Location Triggers',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 32),
                _buildLocationButton(
                  context,
                  ref,
                  icon: Icons.home_rounded,
                  title: 'Set Home Location',
                  subtitle: 'Saves your current location as Home',
                  onTap: () async {
                    ref.read(hapticServiceProvider).click();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Retrieving location...')),
                    );
                    final success = await ref
                        .read(locationServiceProvider)
                        .saveHomeLocation();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Home location saved successfully! 🏠'
                                : 'Failed to save location. Check permissions.',
                          ),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                _buildLocationButton(
                  context,
                  ref,
                  icon: Icons.work_rounded,
                  title: 'Set Work Location',
                  subtitle: 'Saves your current location as Work',
                  onTap: () async {
                    ref.read(hapticServiceProvider).click();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Retrieving location...')),
                    );
                    final success = await ref
                        .read(locationServiceProvider)
                        .saveWorkLocation();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Work location saved successfully! 💼'
                                : 'Failed to save location. Check permissions.',
                          ),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 32),
                const Text(
                  'Time Triggers',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 32),
                Consumer(
                  builder: (context, WidgetRef ref, _) {
                    final tonightTime = ref.watch(tonightTimeProvider);
                    // Format time (e.g., 8:00 PM)
                    final formattedTime = tonightTime.format(context);

                    return _buildLocationButton(
                      context,
                      ref,
                      icon: Icons.nightlight_round,
                      title: 'Tonight Trigger Time',
                      subtitle: 'Currently set to $formattedTime',
                      onTap: () async {
                        ref.read(hapticServiceProvider).click();
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: tonightTime,
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: Colors.blueAccent,
                                  onPrimary: Colors.white,
                                  surface: Color(0xFF1E1E1E),
                                  onSurface: Colors.white,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          ref
                              .read(tonightTimeProvider.notifier)
                              .updateTime(picked);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Tonight trigger set to ${picked.format(context)} 🌙',
                                ),
                              ),
                            );
                          }
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationButton(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.blueAccent),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}
