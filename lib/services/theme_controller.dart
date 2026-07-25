import 'package:flutter/material.dart';
import 'package:linux_assistant/services/config_handler.dart';

/// Holds the app-wide appearance state and notifies on change.
///
/// Before this existed, the theme was read once in `main()` and baked into a
/// `StatelessWidget`, so switching between light and dark required restarting
/// the app. Listening to this controller lets `MaterialApp` rebuild in place.
///
/// A plain [ChangeNotifier] is deliberate: the app has no state-management
/// package, and pulling one in for two booleans would be a heavier change than
/// the problem warrants.
class ThemeController extends ChangeNotifier {
  static final ThemeController _instance = ThemeController._();

  factory ThemeController() => _instance;

  ThemeController._();

  static const String _themeModeKey = "theme_mode";
  static const String _legacyDarkKey = "dark_theme_activated";
  static const String _useDistroColorsKey = "use_distro_colors";

  ThemeMode _themeMode = ThemeMode.system;
  bool _useDistroColors = false;

  ThemeMode get themeMode => _themeMode;
  bool get useDistroColors => _useDistroColors;

  /// True when the app should currently render dark.
  ///
  /// [systemIsDark] is what the desktop environment reports, used only when the
  /// mode is [ThemeMode.system].
  bool isDark(bool systemIsDark) {
    switch (_themeMode) {
      case ThemeMode.light:
        return false;
      case ThemeMode.dark:
        return true;
      case ThemeMode.system:
        return systemIsDark;
    }
  }

  /// Loads the persisted preferences.
  ///
  /// [systemIsDark] is the desktop's current setting, used to migrate the old
  /// `dark_theme_activated` boolean: if the user had explicitly flipped it away
  /// from what the system reports, that choice is preserved as an explicit
  /// light/dark mode instead of silently becoming "follow system".
  Future<void> load({required bool systemIsDark}) async {
    final config = ConfigHandler();

    final storedMode = await config.getValue(_themeModeKey, null);
    if (storedMode is String) {
      _themeMode = _parseThemeMode(storedMode);
    } else {
      final legacyDark = await config.getValue(_legacyDarkKey, systemIsDark);
      _themeMode = (legacyDark == systemIsDark)
          ? ThemeMode.system
          : (legacyDark == true ? ThemeMode.dark : ThemeMode.light);
    }

    _useDistroColors =
        await config.getValue(_useDistroColorsKey, false) == true;

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) {
      return;
    }
    _themeMode = mode;
    notifyListeners();
    await ConfigHandler().setValue(_themeModeKey, _serializeThemeMode(mode));
  }

  Future<void> setUseDistroColors(bool value) async {
    if (_useDistroColors == value) {
      return;
    }
    _useDistroColors = value;
    notifyListeners();
    await ConfigHandler().setValue(_useDistroColorsKey, value);
  }

  /// Cycles system -> light -> dark -> system, for the toolbar toggle.
  Future<void> cycleThemeMode() async {
    switch (_themeMode) {
      case ThemeMode.system:
        await setThemeMode(ThemeMode.light);
        break;
      case ThemeMode.light:
        await setThemeMode(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        await setThemeMode(ThemeMode.system);
        break;
    }
  }

  static ThemeMode _parseThemeMode(String value) {
    switch (value) {
      case "light":
        return ThemeMode.light;
      case "dark":
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _serializeThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return "light";
      case ThemeMode.dark:
        return "dark";
      case ThemeMode.system:
        return "system";
    }
  }

  /// Test seam: resets to defaults so widget tests start from a known state.
  @visibleForTesting
  void resetForTesting() {
    _themeMode = ThemeMode.system;
    _useDistroColors = false;
  }
}
