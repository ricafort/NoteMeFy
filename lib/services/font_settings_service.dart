import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

class FontSettings {
  final double fontSize;
  final String fontFamily;

  FontSettings({required this.fontSize, required this.fontFamily});

  FontSettings copyWith({double? fontSize, String? fontFamily}) {
    return FontSettings(
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }
}

class FontSettingsNotifier extends Notifier<FontSettings> {
  static const String _boxName = 'settingsBox';
  static const String _fontSizeKey = 'fontSize';
  static const String _fontFamilyKey = 'fontFamily';
  late Box _box;

  @override
  FontSettings build() {
    _box = Hive.box(_boxName);
    final size = _box.get(_fontSizeKey, defaultValue: 32.0) as double;
    final family = _box.get(_fontFamilyKey, defaultValue: 'System') as String;
    return FontSettings(fontSize: size, fontFamily: family);
  }

  void updateFontSize(double newSize) {
    _box.put(_fontSizeKey, newSize);
    state = state.copyWith(fontSize: newSize);
  }

  void updateFontFamily(String newFamily) {
    _box.put(_fontFamilyKey, newFamily);
    state = state.copyWith(fontFamily: newFamily);
  }
}

final fontSettingsProvider = NotifierProvider<FontSettingsNotifier, FontSettings>(() {
  return FontSettingsNotifier();
});
