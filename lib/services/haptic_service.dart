import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haptic_feedback/haptic_feedback.dart';

final hapticServiceProvider = Provider<HapticService>((ref) {
  return HapticService();
});

/// Wraps native haptics to provide tactile confirmation of actions
class HapticService {
  /// A heavy "thud" or "click" when a user selects a trigger tag
  Future<void> click() async {
    // We try selection click, falling back to heavy impact if needed
    final canUseHaptics = await Haptics.canVibrate();
    if (canUseHaptics) {
      await Haptics.vibrate(HapticsType.selection);
    }
  }

  /// A satisfying snapping feeling when the note is "thrown" / saved
  Future<void> snapThrow() async {
    final canUseHaptics = await Haptics.canVibrate();
    if (canUseHaptics) {
      // Impact heavy gives the "thud" of the note leaving
      await Haptics.vibrate(HapticsType.heavy);
    }
  }
}
