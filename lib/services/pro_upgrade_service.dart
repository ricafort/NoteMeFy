import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final proUpgradeProvider = NotifierProvider<ProStatusNotifier, bool>(ProStatusNotifier.new);

// TUTORIAL: In Riverpod 3.0, `Notifier` replaces the old `StateNotifier`. 
// It allows us to hold a single piece of mutable state (in this case, a boolean).
// When we change `state = true`, any UI watching this provider automatically rebuilds!
class ProStatusNotifier extends Notifier<bool> {
  final _box = Hive.box('settingsBox');
  static const _proStatusKey = 'is_pro_unlocked';

  // TUTORIAL: The build method is called completely synchronously when the app boots.
  // Because Hive is incredibly fast and memory-mapped, we don't have to await it.
  // This means our UI can render instantly without a "loading" spinner!
  @override
  bool build() {
    return _box.get(_proStatusKey, defaultValue: false);
  }

  Future<void> unlockPro() async {
    // Simulate network/store delay
    await Future.delayed(const Duration(seconds: 1));
    await _box.put(_proStatusKey, true);
    state = true;
  }

  Future<void> restorePurchases() async {
    // Simulate network/store delay
    await Future.delayed(const Duration(seconds: 1));
    // In a real app we'd check RevenueCat/StoreKit. For MVP we'll just check local state
    // For testing purposes, let's say restoring just verifies the local flag.
    state = _box.get(_proStatusKey, defaultValue: false);
  }
  
  Future<void> resetProForTesting() async {
    await _box.put(_proStatusKey, false);
    state = false;
  }
}
