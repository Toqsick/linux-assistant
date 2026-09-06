import 'package:flutter/material.dart';
import 'package:linux_assistant/layouts/greeter/start_after_installation.dart';
import 'package:linux_assistant/layouts/mint_y.dart';
import 'package:linux_assistant/l10n/app_localizations.dart';
import 'package:linux_assistant/services/linux.dart';

class ActivateHotkeyQuestion extends StatelessWidget {
  final Widget route;
  const ActivateHotkeyQuestion(
      {super.key, this.route = const StartAfterInstallationRoutineQuestion()});

  @override
  Widget build(BuildContext context) {
    return MintYPage(
      title: AppLocalizations.of(context)!.activateHotkey,
      contentElements: [
        Text(
          AppLocalizations.of(context)!.openLinuxAssistantFaster,
          style: Theme.of(context).textTheme.displayLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(
          height: 16,
        ),
        Text(
          AppLocalizations.of(context)!
              .openLinuxAssistantFasterDescription(Linux.getHotkeyModifier()),
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
      bottom: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MintYButtonNavigate(
            route: route,
            text: Text(
              AppLocalizations.of(context)!.skip,
              style: MintY.heading4,
            ),
          ),
          const SizedBox(
            width: 16,
          ),
          MintYButtonNavigate(
            route: route,
            text: Text(
              AppLocalizations.of(context)!.yesSetUpHotkey,
              style: MintY.heading4White,
            ),
            color: MintY.currentColor,
            onPressed: () {
              Linux.activateSystemHotkeyForLinuxAssistant();
            },
          ),
        ],
      ),
    );
  }
}
