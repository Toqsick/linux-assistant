import 'package:flutter_test/flutter_test.dart';
import 'package:linux_assistant/helpers/command_helper.dart';
import 'package:linux_assistant/layouts/security_check/security_check_outcome.dart';

/// The security page used to treat every failure as "you need root rights".
/// That hid the deb822 parsing crash behind a permissions message. These
/// tests pin the contract that separates the two.
void main() {
  const marker = "#!script ran successfully.";

  group("classifySecurityCheck", () {
    test("report with marker and exit 0 is a success", () {
      final result =
          CommandResult(true, "homefoldernotsecure: \n$marker\n", "", 0);
      expect(classifySecurityCheck(result), SecurityCheckOutcome.success);
    });

    test("dismissed pkexec dialog (126) means no root rights", () {
      final result = CommandResult(false, "", "Not authorized\n", 126);
      expect(classifySecurityCheck(result), SecurityCheckOutcome.noRootRights);
    });

    test("denied authorization (127) means no root rights", () {
      final result = CommandResult(false, "", "Authorization failed\n", 127);
      expect(classifySecurityCheck(result), SecurityCheckOutcome.noRootRights);
    });

    test("crash after successful auth is a script error, not a rights problem",
        () {
      // This is the deb822 crash as it actually reached the UI.
      final result = CommandResult(
          false,
          "",
          "Traceback (most recent call last):\n"
              '  File "check_security.py", line 42, in <module>\n'
              "    sources = sources[0].split(\":\")\n"
              "IndexError: list index out of range\n",
          1);
      expect(classifySecurityCheck(result), SecurityCheckOutcome.scriptError);
    });

    test("exit 0 without the marker is a script error", () {
      final result = CommandResult(true, "something unexpected\n", "", 0);
      expect(classifySecurityCheck(result), SecurityCheckOutcome.scriptError);
    });

    test("unstartable process (pkexec missing) is a script error", () {
      final result = CommandResult(false, "", "No such file or directory", -1);
      expect(classifySecurityCheck(result), SecurityCheckOutcome.scriptError);
    });
  });

  group("checkerErrorExcerpt", () {
    test("prefers stderr and trims it", () {
      final result =
          CommandResult(false, "stdout noise\n", "  IndexError: boom\n", 1);
      expect(checkerErrorExcerpt(result), "IndexError: boom");
    });

    test("falls back to stdout when stderr is empty", () {
      final result = CommandResult(false, "reported on stdout\n", "", 1);
      expect(checkerErrorExcerpt(result), "reported on stdout");
    });

    test("reports the exit code when both streams are empty", () {
      final result = CommandResult(false, "", "   \n", 1);
      expect(checkerErrorExcerpt(result), "exit code 1");
    });

    test("keeps the tail of long tracebacks", () {
      final filler = "x" * 5000;
      final result =
          CommandResult(false, "", "Traceback...\n$filler\nFINAL ERROR", 1);
      final excerpt = checkerErrorExcerpt(result, maxLength: 100);
      expect(excerpt.endsWith("FINAL ERROR"), isTrue);
      expect(excerpt.length, lessThanOrEqualTo(101)); // tail + ellipsis
      expect(excerpt.startsWith("…"), isTrue);
    });
  });
}
