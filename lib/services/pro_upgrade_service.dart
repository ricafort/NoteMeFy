import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

final proUpgradeProvider = NotifierProvider<ProStatusNotifier, bool>(ProStatusNotifier.new);

class ProStatusNotifier extends Notifier<bool> {
  static const _apiKey = 'test_SdYXSEPWWgGvxSLaOcOyEfMkLgv';
  static const _entitlementId = 'NoteMeFy Pro';

  @override
  bool build() {
    // Start by assuming false until RevenueCat initializes
    _initRevenueCat();
    return false;
  }

  Future<void> _initRevenueCat() async {
    try {
      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      }

      PurchasesConfiguration configuration;
      if (Platform.isAndroid || Platform.isIOS) {
        // Prevent RevenueCat from fatally crashing the Profile/Release build with a test key
        if (!kDebugMode && _apiKey.startsWith('test_')) {
          debugPrint('WARNING: Bypassing RevenueCat init inside Profile/Release to prevent test_ key fatal crash.');
          return;
        }

        configuration = PurchasesConfiguration(_apiKey);
        await Purchases.configure(configuration);
        
        // Listen for changes (e.g., successful purchase, expiration)
        Purchases.addCustomerInfoUpdateListener((customerInfo) {
          _updateState(customerInfo);
        });
        
        // Get current status immediately
        final initialInfo = await Purchases.getCustomerInfo();
        _updateState(initialInfo);
      }
    } catch (e) {
      debugPrint('Error initializing RevenueCat: $e');
    }
  }

  void _updateState(CustomerInfo info) {
    try {
      final isPro = info.entitlements.all[_entitlementId]?.isActive ?? false;
      if (state != isPro) {
        state = isPro;
      }
    } catch (e) {
      debugPrint('Error updating RevenueCat state: $e');
    }
  }

  Future<void> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      _updateState(customerInfo);
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
    }
  }
}
