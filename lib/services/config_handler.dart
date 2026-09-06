import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:linux_assistant/services/linux.dart';
import 'package:linux_assistant/services/logger.dart';

class ConfigHandler {
  /// handle IconLoader as a singleton
  static final ConfigHandler _instance = ConfigHandler._privateConstructor();
  factory ConfigHandler() {
    return _instance;
  }
  ConfigHandler._privateConstructor();

  Map<String, dynamic> configMap = {
    "config_initialized": false,
  };

  /// Test seam: drops the in-memory config so the next access reloads.
  @visibleForTesting
  void resetForTesting({Directory? directory}) {
    directoryOverride = directory;
    configMap = {
      "config_initialized": false,
    };
  }

  Future<dynamic> getValue(key, defaultValue) async {
    await ensureConfigIsLoaded();
    return getValueUnsafe(key, defaultValue);
  }

  /// ensure that the config is loaded into memory before!! (call ensureConfigIsLoaded() before)
  /// that has only to be done once per programm start
  dynamic getValueUnsafe(key, defaultValue) {
    if (configMap.containsKey(key)) {
      return configMap[key];
    } else {
      return defaultValue;
    }
  }

  /// Ensures that the config is loaded into memory before
  /// Also ensures that the config is saved to file after
  /// You may directly access the saved variable with getValueUnsafe()
  Future<void> setValue(key, value) async {
    await ensureConfigIsLoaded();
    setValueUnsafe(key, value);
    await saveConfigToFile();
  }

  /// ensure that the config is loaded into memory before!! (call ensureConfigIsLoaded() before)
  /// that has only to be done once per programm start
  /// also ensure that saveConfigToFile() is called once before programm exit
  void setValueUnsafe(key, value) {
    configMap[key] = value;
  }

  Future<void> ensureConfigIsLoaded() async {
    if (!configMap["config_initialized"]) {
      await loadConfigFromFile();
    }
  }

  /// Test seam: when set, the config is read and written here instead of
  /// under `$HOME`, so tests never touch the developer's own configuration.
  @visibleForTesting
  static Directory? directoryOverride;

  /// Directory and file the config lives in.
  ///
  /// Kept in one place: the path used to be spelled out three times, once via
  /// a `mkdir -p` subprocess.
  Directory get configDirectory =>
      directoryOverride ??
      Directory("${Linux.getHomeDirectory()}.config/linux-assistant");

  File get configFile => File("${configDirectory.path}/config.json");

  Future<void> loadConfigFromFile() async {
    try {
      if (!await configFile.exists()) {
        await configDirectory.create(recursive: true);
        configMap["config_initialized"] = true;
        return;
      }

      String configString = await configFile.readAsString();
      if (configString.trim() == "") {
        configMap["config_initialized"] = true;
        return;
      }

      Map<String, dynamic> loaded =
          Map<String, dynamic>.from(jsonDecode(configString) as Map);
      loaded["config_initialized"] = true;
      configMap = loaded;
    } catch (e) {
      // Do not fall through to the defaults silently. The next setValue()
      // would write them over the user's file, which is how a single bad byte
      // used to erase the whole configuration.
      await _quarantineUnreadableConfig(e);
      configMap["config_initialized"] = true;
    }
  }

  Future<void> _quarantineUnreadableConfig(Object error) async {
    logError("Loading linux-assistant config failed", error);
    try {
      if (!await configFile.exists()) {
        return;
      }
      String stamp = DateTime.now().toIso8601String().replaceAll(":", "-");
      String backup = "${configFile.path}.unreadable-$stamp";
      await configFile.copy(backup);
      logInfo("Kept a copy of the unreadable config at $backup");
    } catch (e) {
      logError("Could not preserve the unreadable config", e);
    }
  }

  Future<void> saveConfigToFile() async {
    await ensureConfigIsLoaded();
    String configString = jsonEncode(configMap);

    await configDirectory.create(recursive: true);

    // Write to a sibling and rename. `writeAsString` truncates first, so an
    // app that dies mid-write — or two windows writing at once — used to leave
    // a half-written config that no longer parses.
    File temporary = File("${configFile.path}.tmp");
    await temporary.writeAsString(configString, flush: true);

    if (await configFile.exists()) {
      await configFile.copy("${configFile.path}.bak");
    }
    await temporary.rename(configFile.path);
  }

  /// removes dates of open times, which are older than 28 days.
  Future<void> clearOldDatesOfOpenendEntries() async {
    DateTime oldestDate = DateTime.now().subtract(const Duration(days: 28));
    await ensureConfigIsLoaded();
    for (String key in configMap.keys) {
      if (key.startsWith("opened.")) {
        String newDateString = "";

        if (getValueUnsafe("self_learning_search", true)) {
          List<String> dateStrings = configMap[key].split(";");
          for (String dateString in dateStrings) {
            if (dateString.trim() == "") {
              continue;
            }
            DateTime? date = DateTime.tryParse(dateString);
            if (date == null) {
              // One unparseable timestamp used to throw out of this method,
              // and this method runs on the way into the search. Drop the
              // entry instead of blocking the search from starting.
              logInfo("Discarding unreadable open date '$dateString' in $key");
              continue;
            }

            /// oldestDate is after date:
            if (oldestDate.compareTo(date) > 0) {
              /// do nothing, don't add it again.
            } else {
              newDateString = "$newDateString$dateString;";
            }
          }
        }

        configMap[key] = newDateString;
      }
    }
    // Only the entries this method emptied. The unqualified version removed
    // every empty value in the config, including settings the user had
    // deliberately cleared.
    configMap
        .removeWhere((key, value) => key.startsWith("opened.") && value == "");
    await saveConfigToFile();
  }
}
