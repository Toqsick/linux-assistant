// Guards the translation files against the two ways they rot: a key that no
// longer exists in the template (a typo, or a string that was removed), and a
// growing pile of untranslated keys.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String templateFile = "lib/l10n/app_en.arb";

/// How many template keys each locale is currently allowed to be missing.
///
/// This is a ratchet, not a target: adding an English string without a
/// translation is fine, adding one without also lowering this number is not.
/// Lower these as translations land; never raise them.
const Map<String, int> untranslatedBudget = {
  "lib/l10n/app_de.arb": 0,
  "lib/l10n/app_it.arb": 20,
  "lib/l10n/linuxassistant_fi.arb": 77,
};

Set<String> messageKeys(String path) {
  final Map<String, dynamic> arb =
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  // Keys starting with @ are metadata (@key descriptions, @@locale).
  return arb.keys.where((k) => !k.startsWith("@")).toSet();
}

void main() {
  final Set<String> template = messageKeys(templateFile);

  test("the template carries messages at all", () {
    expect(template, isNotEmpty);
  });

  for (final MapEntry<String, int> entry in untranslatedBudget.entries) {
    final String path = entry.key;
    final int budget = entry.value;

    group(path.split("/").last, () {
      test("has no keys the template does not define", () {
        final Set<String> stale = messageKeys(path).difference(template);
        expect(stale, isEmpty,
            reason: "these keys reach no widget and are dead weight; "
                "if one is a typo, fix the spelling instead of deleting it");
      });

      test("is missing no more than its budget of $budget keys", () {
        final int missing = template.difference(messageKeys(path)).length;
        expect(missing, lessThanOrEqualTo(budget),
            reason: "new English strings need a translation, or this "
                "budget entry needs to be raised deliberately");
        expect(missing, greaterThanOrEqualTo(budget - 5),
            reason: "translations landed — lower the budget to $missing "
                "so the ratchet keeps holding");
      });
    });
  }
}
