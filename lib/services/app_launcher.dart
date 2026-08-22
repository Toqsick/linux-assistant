import 'dart:io';

import 'config_handler.dart';

/// Ergebnis eines Browser-Launches.
enum BrowserLaunchResult {
  /// Konfigurierter/Bevorzugter Browser wurde gestartet.
  launchedPreferred,

  /// Fallback auf Standard-Browser via xdg-open.
  launchedFallback,

  /// Nichts gefunden – UI sollte Fehlermeldung zeigen.
  failed,
}

/// Bekannte Browser-Binaries in Prioritätsreihenfolge.
/// Der konfigurierte Browser (ConfigHandler-Key `preferred_browser`)
/// wird dieser Liste vorangestellt.
const List<String> kKnownBrowsers = [
  'brave',
  'brave-browser',
  'firefox',
  'chromium',
  'chromium-browser',
  'google-chrome',
  'falkon',
];

/// Startet externe Anwendungen (Browser etc.) detached vom App-Prozess.
///
/// CLI-first: nutzt `which` zur Erkennung und startet Prozesse mit
/// [ProcessStartMode.detached], damit die App nicht blockiert und der
/// Browser die App überlebt.
///
/// Testbar: [whichRunner] und [processStarter] sind injizierbar.
class AppLauncher {
  /// Signatur für `which`-Aufrufe (injizierbar für Tests).
  static Future<bool> Function(String binary) _which = _defaultWhich;

  /// Signatur für Prozess-Starts (injizierbar für Tests).
  static Future<bool> Function(String binary, List<String> args)
      _starter = _defaultStarter;

  /// Überschreibt Prozess-Aufrufe – nur für Tests verwenden!
  static void debugOverride({
    Future<bool> Function(String binary)? whichRunner,
    Future<bool> Function(String binary, List<String> args)? processStarter,
  }) {
    _which = whichRunner ?? _defaultWhich;
    _starter = processStarter ?? _defaultStarter;
  }

  /// Setzt Test-Overrides zurück.
  static void resetOverrides() {
    _which = _defaultWhich;
    _starter = _defaultStarter;
  }

  static Future<bool> _defaultWhich(String binary) async {
    try {
      final result = await Process.run('which', [binary]);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _defaultStarter(String binary, List<String> args) async {
    try {
      await Process.start(binary, args, mode: ProcessStartMode.detached);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Prüft, ob ein Binary im PATH verfügbar ist.
  static Future<bool> isAvailable(String binary) => _which(binary);

  /// Gibt den ersten verfügbaren Browser aus der Prioritätsliste zurück.
  /// Berücksichtigt den konfigurierten Browser (`preferred_browser`).
  static Future<String?> detectBrowser() async {
    final configured = _configuredBrowser();
    final candidates = [
      if (configured != null && configured.isNotEmpty) configured,
      ...kKnownBrowsers,
    ];
    for (final bin in candidates) {
      if (await _which(bin)) return bin;
    }
    return null;
  }

  /// Startet den Browser. [url] ist optional (Default: Startseite).
  ///
  /// Ablauf gemäß Admin-Hub-Spec (E1):
  /// 1. Konfigurierter/erster verfügbarer Browser → [launchedPreferred]
  /// 2. Fallback `xdg-open` → [launchedFallback]
  /// 3. Alles fehlgeschlagen → [failed]
  static Future<BrowserLaunchResult> launchBrowser({String? url}) async {
    final args = url != null ? [url] : <String>[];

    final browser = await detectBrowser();
    if (browser != null && await _starter(browser, args)) {
      return BrowserLaunchResult.launchedPreferred;
    }

    // Fallback: Standard-Browser des Systems.
    if (await _starter('xdg-open', [url ?? 'https://'])) {
      return BrowserLaunchResult.launchedFallback;
    }
    return BrowserLaunchResult.failed;
  }

  /// Startet eine beliebige Anwendung detached (für spätere Werkzeuge,
  /// z. B. „Im Terminal öffnen" im Dateimanager).
  static Future<bool> launchApp(String binary, {List<String> args = const []}) {
    return _starter(binary, args);
  }

  static String? _configuredBrowser() {
    try {
      final value = ConfigHandler().getValueUnsafe('preferred_browser', '');
      return value.isEmpty ? null : value;
    } catch (_) {
      return null; // ConfigHandler nicht initialisiert (z. B. in Tests)
    }
  }
}
