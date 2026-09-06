import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:linux_assistant/services/config_handler.dart';
import 'package:linux_assistant/services/logger.dart';
import 'package:linux_assistant/services/updater.dart';
import 'package:http/http.dart' as http;

class WeeklyTasks {
  /// Seconds
  static const int _defaultTimeout = 5;

  static Future<void> doWeekleyTasks() async {
    DateTime.parse(
        ConfigHandler().getValueUnsafe("last-weekly-task", "1970-01-01"));
    DateTime lastSearch = DateTime.parse(
        ConfigHandler().getValueUnsafe("last-weekly-task", "1970-01-01"));
    if (DateTime.now().difference(lastSearch).inDays < 7) {
      return;
    }

    Future newestVersionRunner = _getNewestVersion();
    await newestVersionRunner;

    String newDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await ConfigHandler().setValue("last-weekly-task", newDate);
  }

  static Future<void> _getNewestVersion() async {
    http.Response response = await http
        .get(Uri.parse("https://api.github.com/repos/"
            "${LinuxAssistantUpdater.releaseRepository}/releases/latest"))
        .timeout(const Duration(seconds: _defaultTimeout));

    if (response.statusCode != 200) {
      // A repository without a published release answers 404. That is a
      // normal state for a fork, not an error worth throwing over — and
      // throwing here used to happen a line later, on `null.replaceAll`.
      logInfo("No release information from GitHub "
          "(HTTP ${response.statusCode}); skipping the update check.");
      return;
    }

    final decoded = json.decode(response.body);
    if (decoded is! Map || decoded["name"] is! String) {
      logInfo("Unexpected release payload; skipping the update check.");
      return;
    }

    LinuxAssistantUpdater.newestVersionInformation = decoded;
    String newestVersion = (decoded["name"] as String).replaceAll("v", "");
    await ConfigHandler()
        .setValue("newest-linux-assistant-version", newestVersion);
  }
}
