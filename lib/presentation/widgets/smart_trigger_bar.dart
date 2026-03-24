import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notemefy/domain/models/note.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:notemefy/services/haptic_service.dart';
import 'package:notemefy/services/pro_upgrade_service.dart';

class SelectedTriggerNotifier extends Notifier<TriggerType> {
  @override
  TriggerType build() => TriggerType.home;

  void updateTrigger(TriggerType type) {
    state = type;
  }
}

final selectedTriggerProvider =
    NotifierProvider<SelectedTriggerNotifier, TriggerType>(
        SelectedTriggerNotifier.new);

class SelectedTagNotifier extends Notifier<String> {
  @override
  String build() => 'Personal';

  void updateTag(String tag) {
    state = tag;
  }
}

final selectedTagProvider =
    NotifierProvider<SelectedTagNotifier, String>(SelectedTagNotifier.new);

class SelectedCustomTimeNotifier extends Notifier<TimeOfDay?> {
  @override
  TimeOfDay? build() => null;

  void updateTime(TimeOfDay time) {
    state = time;
  }
}

final selectedCustomTimeProvider =
    NotifierProvider<SelectedCustomTimeNotifier, TimeOfDay?>(
        SelectedCustomTimeNotifier.new);

class SmartTriggerBar extends ConsumerWidget {
  const SmartTriggerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTrigger = ref.watch(selectedTriggerProvider);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTriggerButton(context, ref, TriggerType.home, Icons.home_rounded, 'Home', currentTrigger, isProFeature: true),
                _buildTriggerButton(context, ref, TriggerType.work, Icons.business_rounded, 'Work', currentTrigger, isProFeature: true),
                _buildTriggerButton(context, ref, TriggerType.tonight, Icons.nights_stay_rounded, 'Tonight', currentTrigger),
                
                Builder(
                  builder: (context) {
                    final customTime = ref.watch(selectedCustomTimeProvider);
                    final label = customTime != null ? customTime.format(context) : 'Custom';
                    return _buildTriggerButton(context, ref, TriggerType.custom, Icons.access_time_filled_rounded, label, currentTrigger);
                  }
                ),
                
                // Category Tag
                _buildTagButton(context, ref),
                
                // NoteMeFy Pro Trigger
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Container(
                    height: 24,
                    width: 1,
                    color: Colors.white24,
                  ),
                ),
                _buildTriggerButton(context, ref, TriggerType.routine, Icons.star_rounded, 'Pro', currentTrigger, isProFeature: true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTriggerButton(
    BuildContext context,
    WidgetRef ref,
    TriggerType type,
    IconData icon,
    String label,
    TriggerType activeType, {
    bool isProFeature = false,
  }) {
    final isActive = type == activeType;
    final primaryColor = isProFeature ? Colors.amberAccent : Colors.blueAccent;
    final userHasPro = ref.watch(proUpgradeProvider);


    return GestureDetector(
      onTap: () async {
        ref.read(hapticServiceProvider).click();
        
        if (isProFeature && !userHasPro) {
          await RevenueCatUI.presentPaywallIfNeeded("NoteMeFy Pro");
          return;
        }

        ref.read(selectedTriggerProvider.notifier).updateTrigger(type);
        
        if (type == TriggerType.custom) {
           _showCupertinoTimePicker(context, ref);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? primaryColor.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? primaryColor : Colors.white54,
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildTagButton(BuildContext context, WidgetRef ref) {
    // Currently, since this is a mocked "Pro" feature, we'll pretend it's in a perpetual "unselected" state 
    // until clicked, which route-pushes to ProUpgradeScreen instead of toggling state.
    // If we wanted real active state tracking (e.g. for a paid user tracking "Is this a business note?"),
    // we would check if `tag` == 'Business' and it is actively selected. 
    // For now, we will just make it look like an unselected icon to match the others.
    final isBusiness = ref.watch(selectedTagProvider) == 'Business';
    final isPro = ref.watch(proUpgradeProvider);
    
    return GestureDetector(
      onTap: () async {
        ref.read(hapticServiceProvider).click();
        
        if (!isPro) {
          // Force Upgrade
          await RevenueCatUI.presentPaywallIfNeeded("NoteMeFy Pro");
        } else {
          // Toggle Tag if they have PRO
          if (isBusiness) {
             ref.read(selectedTagProvider.notifier).updateTag('Personal');
          } else {
             ref.read(selectedTagProvider.notifier).updateTag('Business');
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              isBusiness ? Icons.work : Icons.person,
              size: 20,
              color: Colors.white54,
            ),
          ],
        ),
      ),
    );
  }

  void _showCupertinoTimePicker(BuildContext context, WidgetRef ref) {
    TimeOfDay initialTime = ref.read(selectedCustomTimeProvider) ?? TimeOfDay.now();
    DateTime initialDateTime = DateTime(2020, 1, 1, initialTime.hour, initialTime.minute);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext builderContext) {
        DateTime tempPickedDate = initialDateTime;
        return SizedBox(
          height: 300,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                         ref.read(hapticServiceProvider).click();
                         Navigator.pop(builderContext);
                      },
                      child: const Text("Cancel", style: TextStyle(color: Colors.white54, fontSize: 16)),
                    ),
                    const Text(
                      "Pick Time",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(hapticServiceProvider).click();
                        ref.read(selectedCustomTimeProvider.notifier).updateTime(
                          TimeOfDay(hour: tempPickedDate.hour, minute: tempPickedDate.minute)
                        );
                        Navigator.pop(builderContext);
                      },
                      child: const Text("Done", style: TextStyle(color: Colors.blueAccent, fontSize: 16)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoTheme(
                  data: const CupertinoThemeData(
                    brightness: Brightness.dark,
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: initialDateTime,
                    onDateTimeChanged: (DateTime newDateTime) {
                      tempPickedDate = newDateTime;
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
