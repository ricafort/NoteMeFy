import 'package:flutter/material.dart';
import 'package:quick_actions/quick_actions.dart';

class QuickActionService {
  static const String actionCapture = 'action_capture';
  
  void init(GlobalKey<NavigatorState> navigatorKey) {
    const QuickActions quickActions = QuickActions();
    
    quickActions.initialize((String shortcutType) {
      if (shortcutType == actionCapture) {
        // If the app was opened or resumed via the Quick Action,
        // pop any top screens (like ReviewScreen) to return to CaptureScreen instantly.
        navigatorKey.currentState?.popUntil((route) => route.isFirst);
      }
    });

    quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(
        type: actionCapture, 
        localizedTitle: 'Capture Idea', 
        icon: 'ic_launcher' // Will use the launcher icon by default, or you can provide a custom one
      ),
    ]);
  }
}
