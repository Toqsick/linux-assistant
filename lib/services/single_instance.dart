import 'dart:async';
import 'dart:io';

import 'package:linux_assistant/services/logger.dart';

/// Keeps one Linux Assistant per session and hands the hotkey to it.
///
/// The launcher script used to decide this with `wmctrl -l | grep 'Linux
/// Assistant'`. wmctrl talks to an X11 window manager, and on a Wayland
/// session it lists nothing at all — so the test always failed and every press
/// of the shortcut started another copy. The workaround for that lived in the
/// search screen, which quit the whole app five seconds after each use.
///
/// A Unix socket in `$XDG_RUNTIME_DIR` answers the question without asking the
/// window manager: whoever owns it is the running instance.
class SingleInstance {
  static ServerSocket? _server;

  static String socketPath() {
    final String? runtimeDirectory = Platform.environment["XDG_RUNTIME_DIR"];
    if (runtimeDirectory != null && runtimeDirectory.isNotEmpty) {
      return "$runtimeDirectory/linux-assistant.sock";
    }
    // No XDG_RUNTIME_DIR (SSH-forwarded session, some display managers):
    // the system temp dir is shared between users, so the fallback has to
    // be user-keyed — otherwise user B's launch hands the hotkey to user
    // A's running instance and exits without ever showing a window.
    // dart:io has no getuid(); the login name is unique per machine.
    final String user = Platform.environment["USER"] ??
        Platform.environment["LOGNAME"] ??
        "unknown-user";
    return "${Directory.systemTemp.path}/linux-assistant-$user.sock";
  }

  static InternetAddress _address() =>
      InternetAddress(socketPath(), type: InternetAddressType.unix);

  /// Returns true when this process is the instance that should keep running.
  ///
  /// When another one already holds the socket, it is asked to come forward
  /// and this call returns false — the caller should exit.
  static Future<bool> claim(
      {required FutureOr<void> Function() onRaise}) async {
    try {
      await _bind(onRaise);
      return true;
    } on SocketException {
      // Either a live instance owns it, or a previous run left the socket
      // file behind after a crash.
      if (await _askRunningInstanceToRaise()) {
        return false;
      }

      logInfo("Removing a stale single-instance socket at ${socketPath()}");
      try {
        await File(socketPath()).delete();
        await _bind(onRaise);
        return true;
      } catch (e) {
        // Better a second window than no window: if this cannot be sorted
        // out, the app still has to start.
        logError("Could not claim the single-instance socket", e);
        return true;
      }
    }
  }

  static Future<void> _bind(FutureOr<void> Function() onRaise) async {
    final ServerSocket server = await ServerSocket.bind(_address(), 0);
    _server = server;
    server.listen((Socket socket) async {
      try {
        await socket.drain();
        await onRaise();
      } catch (e) {
        logError("Handling a raise request failed", e);
      } finally {
        await socket.close();
      }
    });
  }

  static Future<bool> _askRunningInstanceToRaise() async {
    try {
      final Socket socket = await Socket.connect(_address(), 0,
          timeout: const Duration(seconds: 2));
      socket.write("raise");
      await socket.flush();
      await socket.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Releases the socket. Best effort — a stale file is detected on the next
  /// start anyway.
  static Future<void> release() async {
    await _server?.close();
    _server = null;
    try {
      final File file = File(socketPath());
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Nothing useful to do while shutting down.
    }
  }
}
