import 'dart:io';

class CommandResult {
  final String error;
  final String output;
  final bool success;

  /// The process' exit code, or -1 if it could not be started.
  final int exitCode;

  const CommandResult(this.success, this.output, this.error,
      [this.exitCode = 0]);
}

/// The one place in the app that starts a process.
///
/// [Linux.runCommandWithCustomArguments] delegates here, so the Flatpak
/// indirection, the environment handling and the exit code all live in a
/// single implementation instead of two that had drifted apart.
abstract class CommandHelper {
  /// Set by `Linux.init()` when the app itself runs inside a Flatpak sandbox.
  ///
  /// Commands then have to be handed to the host through `flatpak-spawn`.
  static bool runningInFlatpak = false;

  static Future<CommandResult> run(String cmd,
      {Map<String, String>? env,
      bool asRoot = false,
      bool hostOnFlatpak = true,
      bool runInShell = false}) async {
    return await runWithArguments(cmd, const [],
        env: env,
        asRoot: asRoot,
        hostOnFlatpak: hostOnFlatpak,
        runInShell: runInShell);
  }

  static Future<CommandResult> runWithArguments(String cmd, List<String> args,
      {Map<String, String>? env,
      bool asRoot = false,
      bool hostOnFlatpak = true,
      bool runInShell = false}) async {
    // A copy. Both this method and its counterpart in Linux used to insert
    // their prefixes into the list the caller passed in, so calling either one
    // twice with the same list produced "pkexec pkexec …".
    final List<String> argv = [cmd, ...args];

    if (asRoot) {
      argv.insert(0, "pkexec");
    }
    if (runningInFlatpak) {
      // Without --host the command stays inside the sandbox, which is what a
      // few callers want.
      argv.insertAll(
          0, hostOnFlatpak ? ["flatpak-spawn", "--host"] : ["flatpak-spawn"]);
    }

    try {
      final ProcessResult result = await Process.run(
        argv.first,
        argv.sublist(1),
        environment: env,
        runInShell: runInShell,
      );
      return CommandResult(
        result.exitCode == 0,
        result.stdout.toString(),
        result.stderr.toString(),
        result.exitCode,
      );
    } on ProcessException catch (e) {
      // A missing executable is a normal answer here — "is zypper installed"
      // is asked by trying to run it — so it is reported, not thrown.
      return CommandResult(false, "", e.message, -1);
    }
  }

  /// Convenience for the many checks that only ask "did this succeed".
  ///
  /// Runs with `LC_ALL=C` so the caller can rely on the exit code without
  /// worrying about the user's locale.
  static Future<bool> succeeds(String cmd, List<String> args,
      {Map<String, String>? env}) async {
    final CommandResult result = await runWithArguments(
      cmd,
      args,
      env: {"LC_ALL": "C", ...?env},
    );
    return result.success;
  }
}
