import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:linux_assistant/services/config_handler.dart';

void main() {
  late Directory sandbox;
  late ConfigHandler config;

  File configFile() => File("${sandbox.path}/config.json");

  setUp(() {
    sandbox = Directory.systemTemp.createTempSync("la-config-test");
    config = ConfigHandler();
    config.resetForTesting(directory: sandbox);
  });

  tearDown(() {
    config.resetForTesting();
    if (sandbox.existsSync()) {
      sandbox.deleteSync(recursive: true);
    }
  });

  group("load", () {
    test("a missing config starts from defaults and creates the directory",
        () async {
      sandbox.deleteSync(recursive: true);

      expect(await config.getValue("anything", "fallback"), "fallback");
      expect(sandbox.existsSync(), isTrue);
    });

    test("an empty file is treated as an empty config", () async {
      configFile().writeAsStringSync("   \n");

      expect(await config.getValue("anything", "fallback"), "fallback");
    });

    test("existing values are read back", () async {
      configFile().writeAsStringSync(jsonEncode({
        "colorfulBackground": false,
        "opened.foo": "2026-09-01;",
      }));

      expect(await config.getValue("colorfulBackground", true), isFalse);
      expect(await config.getValue("opened.foo", ""), "2026-09-01;");
    });
  });

  group("unreadable config", () {
    test("is preserved instead of being overwritten with defaults", () async {
      configFile().writeAsStringSync("{ this is not json");

      await config.setValue("something", "new");

      final List<String> preserved = sandbox
          .listSync()
          .map((e) => e.path.split("/").last)
          .where((name) => name.contains("unreadable"))
          .toList();
      expect(preserved, hasLength(1),
          reason: "the damaged file must survive as a copy");
      expect(File("${sandbox.path}/${preserved.single}").readAsStringSync(),
          "{ this is not json");
    });

    test("does not stop the app from writing a fresh config", () async {
      configFile().writeAsStringSync("{ this is not json");

      await config.setValue("something", "new");

      expect(jsonDecode(configFile().readAsStringSync())["something"], "new");
    });
  });

  group("save", () {
    test("writes valid json and keeps a backup of the previous file", () async {
      await config.setValue("first", 1);
      await config.setValue("second", 2);

      final Map<String, dynamic> written =
          jsonDecode(configFile().readAsStringSync());
      expect(written["first"], 1);
      expect(written["second"], 2);

      final File backup = File("${configFile().path}.bak");
      expect(backup.existsSync(), isTrue);
      expect(jsonDecode(backup.readAsStringSync())["first"], 1);
    });

    test("leaves no temporary file behind", () async {
      await config.setValue("first", 1);

      expect(File("${configFile().path}.tmp").existsSync(), isFalse);
    });

    test("survives a reload", () async {
      await config.setValue("colorfulBackground", false);

      config.resetForTesting(directory: sandbox);
      expect(await config.getValue("colorfulBackground", true), isFalse);
    });
  });

  group("clearOldDatesOfOpenendEntries", () {
    String isoDaysAgo(int days) => DateTime.now()
        .subtract(Duration(days: days))
        .toIso8601String()
        .split("T")
        .first;

    test("drops dates older than 28 days and keeps recent ones", () async {
      await config.setValue(
          "opened.some_action", "${isoDaysAgo(40)};${isoDaysAgo(2)};");

      await config.clearOldDatesOfOpenendEntries();

      expect(
          await config.getValue("opened.some_action", ""), "${isoDaysAgo(2)};");
    });

    test("an unparseable date does not abort the sweep", () async {
      await config.setValue(
          "opened.some_action", "not-a-date;${isoDaysAgo(2)};");
      await config.setValue("opened.other_action", "${isoDaysAgo(1)};");

      await config.clearOldDatesOfOpenendEntries();

      expect(
          await config.getValue("opened.some_action", ""), "${isoDaysAgo(2)};");
      expect(await config.getValue("opened.other_action", ""),
          "${isoDaysAgo(1)};");
    });

    test("keeps unrelated settings that happen to be empty", () async {
      await config.setValue("main_color", "");
      await config.setValue("opened.some_action", "${isoDaysAgo(40)};");

      await config.clearOldDatesOfOpenendEntries();

      expect(config.configMap.containsKey("main_color"), isTrue,
          reason: "only emptied opened.* entries may be removed");
      expect(config.configMap.containsKey("opened.some_action"), isFalse);
    });
  });
}
