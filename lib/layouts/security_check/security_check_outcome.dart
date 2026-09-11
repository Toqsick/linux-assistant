import 'package:linux_assistant/helpers/command_helper.dart';

/// What actually happened when the privileged security checker ran.
enum SecurityCheckOutcome {
  /// The checker produced a report.
  success,

  /// pkexec was dismissed or denied: the user never got root rights.
  noRootRights,

  /// Root was granted and the checker itself failed — an app bug, not a
  /// permissions problem.
  scriptError,
}

/// The success marker every `check_security*.py` prints as its last line.
const String kSecurityCheckSuccessMarker = "#!script ran successfully.";

/// Classifies a checker run from the raw process result.
///
/// pkexec's exit-code contract: 126 = the dialog was dismissed, 127 =
/// authorization denied or unavailable. Those are the only outcomes that mean
/// "no root rights". Any other non-zero exit — or a zero exit without the
/// success marker — means the script ran privileged and failed on its own,
/// which the UI must not present as a permissions problem.
SecurityCheckOutcome classifySecurityCheck(CommandResult result) {
  if (result.exitCode == 126 || result.exitCode == 127) {
    return SecurityCheckOutcome.noRootRights;
  }
  if (result.exitCode == 0 &&
      result.output.contains(kSecurityCheckSuccessMarker)) {
    return SecurityCheckOutcome.success;
  }
  return SecurityCheckOutcome.scriptError;
}

/// A short excerpt of the failure for the error page.
///
/// Prefers stderr, where a Python traceback lands; falls back to stdout for
/// scripts that report on the wrong stream. Keeps the tail, not the head:
/// a traceback ends with the actual exception, and the excerpt is meant for
/// copying into a bug report.
String checkerErrorExcerpt(CommandResult result, {int maxLength = 2000}) {
  final String raw =
      result.error.trim().isNotEmpty ? result.error : result.output;
  final String squashed = raw.trim().replaceAll(RegExp(r"\n{3,}"), "\n\n");
  if (squashed.isEmpty) {
    return "exit code ${result.exitCode}";
  }
  if (squashed.length <= maxLength) {
    return squashed;
  }
  return "…${squashed.substring(squashed.length - maxLength)}";
}
