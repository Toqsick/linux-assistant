import 'package:flutter_test/flutter_test.dart';
import 'package:linux_assistant/services/app_launcher.dart';

void main() {
  tearDown(AppLauncher.resetOverrides);

  group('AppLauncher.detectBrowser', () {
    test('findet Brave, wenn verfügbar', () async {
      AppLauncher.debugOverride(
        whichRunner: (bin) async => bin == 'brave',
        processStarter: (_, __) async => true,
      );
      expect(await AppLauncher.detectBrowser(), 'brave');
    });

    test('fällt auf brave-browser zurück, wenn brave fehlt', () async {
      AppLauncher.debugOverride(
        whichRunner: (bin) async => bin == 'brave-browser',
        processStarter: (_, __) async => true,
      );
      expect(await AppLauncher.detectBrowser(), 'brave-browser');
    });

    test('gibt null zurück, wenn kein Browser gefunden', () async {
      AppLauncher.debugOverride(
        whichRunner: (_) async => false,
        processStarter: (_, __) async => false,
      );
      expect(await AppLauncher.detectBrowser(), isNull);
    });
  });

  group('AppLauncher.launchBrowser', () {
    test('launchedPreferred, wenn Brave startet', () async {
      final started = <String>[];
      AppLauncher.debugOverride(
        whichRunner: (bin) async => bin == 'brave',
        processStarter: (bin, args) async {
          started.add('$bin ${args.join(" ")}');
          return true;
        },
      );
      final result = await AppLauncher.launchBrowser(url: 'https://example.com');
      expect(result, BrowserLaunchResult.launchedPreferred);
      expect(started.single, 'brave https://example.com');
    });

    test('launchedFallback via xdg-open, wenn kein Browser gefunden', () async {
      final started = <String>[];
      AppLauncher.debugOverride(
        whichRunner: (_) async => false,
        processStarter: (bin, args) async {
          started.add(bin);
          return bin == 'xdg-open';
        },
      );
      final result = await AppLauncher.launchBrowser();
      expect(result, BrowserLaunchResult.launchedFallback);
      expect(started, ['xdg-open']);
    });

    test('failed, wenn weder Browser noch xdg-open starten', () async {
      AppLauncher.debugOverride(
        whichRunner: (_) async => false,
        processStarter: (_, __) async => false,
      );
      expect(await AppLauncher.launchBrowser(), BrowserLaunchResult.failed);
    });

    test('startet ohne URL-Argument, wenn keine übergeben', () async {
      List<String>? capturedArgs;
      AppLauncher.debugOverride(
        whichRunner: (bin) async => bin == 'brave',
        processStarter: (bin, args) async {
          capturedArgs = args;
          return true;
        },
      );
      await AppLauncher.launchBrowser();
      expect(capturedArgs, isEmpty);
    });
  });

  group('AppLauncher.launchApp', () {
    test('startet beliebige Binaries detached', () async {
      String? startedBin;
      AppLauncher.debugOverride(
        processStarter: (bin, args) async {
          startedBin = bin;
          return true;
        },
      );
      expect(await AppLauncher.launchApp('nautilus'), isTrue);
      expect(startedBin, 'nautilus');
    });

    test('gibt false bei Startfehler zurück', () async {
      AppLauncher.debugOverride(processStarter: (_, __) async => false);
      expect(await AppLauncher.launchApp('nonexistent'), isFalse);
    });
  });
}
