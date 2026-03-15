import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notemefy/services/font_settings_service.dart';
import 'package:notemefy/services/haptic_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(fontSettingsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
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
                  const Text('A', style: TextStyle(color: Colors.white54, fontSize: 16)),
                  Expanded(
                    child: Slider(
                      value: settings.fontSize,
                      min: 16.0,
                      max: 64.0,
                      divisions: 24,
                      activeColor: Colors.blueAccent,
                      onChanged: (val) {
                        ref.read(fontSettingsProvider.notifier).updateFontSize(val);
                      },
                      onChangeEnd: (_) {
                        ref.read(hapticServiceProvider).click();
                      },
                    ),
                  ),
                  const Text('A', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
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
              
            ],
          ),
        ),
      ),
    );
  }
}
