import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:linux_assistant/l10n/app_localizations.dart';
import 'package:linux_assistant/layouts/settings/settings_widgets.dart';
import 'package:linux_assistant/services/config_handler.dart';
import 'package:linux_assistant/services/linux.dart';
import 'package:linux_assistant/services/theme_controller.dart';

class AppearanceSettings extends StatefulWidget {
  const AppearanceSettings({super.key});

  @override
  State<AppearanceSettings> createState() => _AppearanceSettingsState();
}

class _AppearanceSettingsState extends State<AppearanceSettings> {
  final ThemeController _themeController = ThemeController();

  @override
  void initState() {
    super.initState();
    ConfigHandler().ensureConfigIsLoaded();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      width: min(600, MediaQuery.of(context).size.width - 100),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.themeModeSetting,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                ListenableBuilder(
                  listenable: _themeController,
                  builder: (context, _) => SegmentedButton<ThemeMode>(
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text(l10n.themeModeSystem),
                        icon: const Icon(Icons.brightness_auto_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text(l10n.themeModeLight),
                        icon: const Icon(Icons.light_mode_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text(l10n.themeModeDark),
                        icon: const Icon(Icons.dark_mode_outlined),
                      ),
                    ],
                    selected: {_themeController.themeMode},
                    onSelectionChanged: (selection) => unawaited(
                        _themeController.setThemeMode(selection.first)),
                  ),
                ),
              ],
            ),
          ),
          SettingWidgetOnOff(
            settingKey: "colorfulBackground",
            text: AppLocalizations.of(context)!.colorfulBackground,
          ),
          SettingWidgetText(
              settingKey: "main_color",
              text: AppLocalizations.of(context)!.mainColorSetting,
              defaultValue: "",
              hintText: "#8ab15a",
              parseFunction: _parseHexColor),
          SettingWidgetText(
              settingKey: "secondary_color",
              text: AppLocalizations.of(context)!.secondaryColorSetting,
              defaultValue: "",
              hintText: "#2eb9a2",
              parseFunction: _parseHexColor),
          InkWell(
            child: Text(
              "Web color picker for HEX code: https://htmlcolorcodes.com/",
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            onTap: () {
              Linux.openWebbrowserWithSite("https://htmlcolorcodes.com/");
            },
          )
        ],
      ),
    );
  }

  String _parseHexColor(String p0) {
    RegExp hexColor = RegExp(r'^#?([0-9a-fA-F]{6})$');
    if (!hexColor.hasMatch(p0)) {
      p0 = "";
    }
    return p0;
  }
}
