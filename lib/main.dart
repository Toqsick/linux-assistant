import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:linux_assistant/enums/distros.dart';
import 'package:linux_assistant/layouts/greeter/flathub_permissions.dart';
import 'package:linux_assistant/layouts/greeter/start_screen.dart';
import 'package:linux_assistant/layouts/hermes_tokens.dart';
import 'package:linux_assistant/layouts/hub/hub_shell.dart';
import 'package:linux_assistant/layouts/mint_y.dart';
import 'package:linux_assistant/services/config_handler.dart';
import 'package:linux_assistant/services/linux.dart';
import 'package:linux_assistant/services/theme_controller.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:linux_assistant/l10n/app_localizations.dart';

String CURRENT_LINUX_ASSISTANT_VERSION = "";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WindowManager.instance.ensureInitialized();
  WindowManager.instance.setTitle("Linux Assistant");

  // For hot reload, `unregisterAll()` needs to be called.
  await HotKeyManager.instance.unregisterAll();

  StatelessWidget firstScreen = const StartScreen();
  bool systemIsDark = false;

  // Are we in a flatpak? Is the folder /app/bin/ present? // Do we have flatpak-spawn?
  var runningInFlatpak = Directory("/app/bin/").existsSync();
  if (runningInFlatpak) {
    firstScreen = const FlathubPermissionsPage();
    var result = Process.runSync("flatpak-spawn", ["--host", "ls", "/"]);
    if (result.stderr.toString().isEmpty) {
      firstScreen = const StartScreen();
    }
    print(result.stdout.toString());
    print(result.stderr.toString());
  }

  // Normal startup if everything is fine.
  if (firstScreen is StartScreen) {
    await Linux.init();

    systemIsDark = await Linux.isDarkThemeEnabled();
    await ThemeController().load(systemIsDark: systemIsDark);

    String versionFile = "${Linux.executableFolder}/version";
    if (await File(versionFile).exists()) {
      try {
        CURRENT_LINUX_ASSISTANT_VERSION =
            (await File(versionFile).readAsString()).trim();
      } catch (e) {
        // Do nothing.
      }
    }
  }

  runApp(MyApp(
    systemIsDark: systemIsDark,
    firstPage: firstScreen,
  ));
}

class MyApp extends StatefulWidget {
  /// What the desktop environment reports, used when the user follows the
  /// system theme.
  final bool systemIsDark;
  final Widget firstPage;

  const MyApp({
    super.key,
    this.systemIsDark = false,
    required this.firstPage,
  });

  @override
  State<MyApp> createState() => _MyAppState();

  static void initHotkeyToShowUp() {
    HotKey hotKey = HotKey(
      key: PhysicalKeyboardKey.keyQ,
      modifiers: [HotKeyModifier.meta],
      scope: HotKeyScope.system,
    );
    hotKeyManager.register(
      hotKey,
      keyDownHandler: (hotKey) {
        Linux.runCommandWithCustomArguments(
            "wmctrl", ["-a", "Linux Assistant"]);
        // Raising the window is only half the job when the hub is open: the
        // hotkey is meant to land the user in the search box.
        HubShell.onSearchRequested?.call();
      },
    );
  }

  /// Applies the accent colors for the current appearance.
  ///
  /// The app now ships the Hermes palette by default; the per-distribution
  /// colors below are opt-in via the `use_distro_colors` setting. An explicit
  /// `main_color` / `secondary_color` in the config still overrides both.
  static void setMainColor({required bool isDark}) {
    final tokens = isDark ? HermesTokens.dark : HermesTokens.light;

    if (!ThemeController().useDistroColors) {
      MintY.currentColor = tokens.accent;
      MintY.secondaryColor = tokens.accentHover;
      _applyConfiguredColorOverrides();
      return;
    }

    MintY.secondaryColor = const Color(0xff2ab9a4);
    switch (Linux.currentenvironment.distribution) {
      case DISTROS.DEBIAN:
        MintY.currentColor = const Color.fromARGB(255, 208, 7, 78);
        MintY.secondaryColor = const Color.fromARGB(255, 75, 5, 35);
        break;
      case DISTROS.LINUX_MINT:
      case DISTROS.LMDE:
        MintY.currentColor = const Color.fromARGB(255, 53, 168, 84);
        MintY.secondaryColor = const Color.fromARGB(255, 35, 130, 70);
        break;
      case DISTROS.MXLINUX:
        MintY.currentColor = const Color.fromARGB(255, 34, 34, 34);
        MintY.secondaryColor = const Color.fromARGB(255, 70, 80, 95);
        break;
      case DISTROS.POPOS:
        MintY.currentColor = const Color.fromARGB(255, 72, 185, 199);
        MintY.secondaryColor = const Color.fromARGB(255, 15, 80, 100);
        break;
      case DISTROS.ZORINOS:
        MintY.currentColor = const Color.fromARGB(255, 21, 166, 240);
        MintY.secondaryColor = const Color.fromARGB(255, 10, 85, 180);
        break;
      case DISTROS.KDENEON:
        MintY.currentColor = const Color.fromARGB(255, 35, 104, 150);
        MintY.secondaryColor = const Color.fromARGB(255, 24, 160, 135);
        break;
      case DISTROS.OPENSUSE:
        MintY.currentColor = const Color.fromARGB(255, 115, 186, 37);
        MintY.secondaryColor = const Color.fromARGB(255, 15, 95, 75);
        break;
      case DISTROS.UBUNTU:
        MintY.currentColor = const Color.fromARGB(255, 233, 84, 32);
        MintY.secondaryColor = const Color.fromARGB(255, 122, 42, 82);
        break;
      case DISTROS.FEDORA:
        MintY.currentColor = const Color.fromARGB(255, 81, 162, 218);
        MintY.secondaryColor = const Color.fromARGB(255, 41, 65, 114);
        break;
      case DISTROS.ARCH:
        MintY.currentColor = const Color.fromARGB(255, 15, 148, 210);
        MintY.secondaryColor = const Color.fromARGB(255, 28, 40, 51);
        break;
      case DISTROS.MANJARO:
        MintY.currentColor = const Color.fromARGB(255, 53, 191, 164);
        MintY.secondaryColor = const Color.fromARGB(255, 26, 40, 37);
        break;
      case DISTROS.ENDEAVOUR:
        MintY.currentColor = const Color.fromARGB(255, 127, 63, 191);
        MintY.secondaryColor = const Color.fromARGB(255, 127, 127, 255);
        break;
      default:
        MintY.currentColor = Colors.blue;
    }
    _applyConfiguredColorOverrides();
  }

  static void _applyConfiguredColorOverrides() {
    ConfigHandler configHandler = ConfigHandler();
    String colorString = configHandler.getValueUnsafe("main_color", "");
    if (colorString.isNotEmpty) {
      MintY.currentColor = HexColor(colorString);
    }
    colorString = configHandler.getValueUnsafe("secondary_color", "");
    if (colorString.isNotEmpty) {
      MintY.secondaryColor = HexColor(colorString);
    }
  }
}

class _MyAppState extends State<MyApp> {
  final ThemeController _themeController = ThemeController();

  @override
  void initState() {
    super.initState();
    MyApp.initHotkeyToShowUp();
    _themeController.addListener(_onAppearanceChanged);
  }

  @override
  void dispose() {
    _themeController.removeListener(_onAppearanceChanged);
    super.dispose();
  }

  void _onAppearanceChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final bool isDark = _themeController.isDark(widget.systemIsDark);

    // Widgets that predate the theme extension read this static directly.
    MintY.dark = isDark;
    MyApp.setMainColor(isDark: isDark);

    final Color? accent =
        _themeController.useDistroColors ? MintY.currentColor : null;

    return MaterialApp(
      title: 'Linux Assistant',
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('de', ''),
        Locale('it', ''),
      ],
      theme: MintY.theme(accent: accent),
      darkTheme: MintY.themeDark(accent: accent),
      // Resolved here rather than handed to Flutter as ThemeMode.system: the
      // desktop's setting comes from gsettings/kdeglobals via
      // Linux.isDarkThemeEnabled(), which the platform brightness does not
      // reliably mirror on Linux.
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: widget.firstPage,
    );
  }
}
