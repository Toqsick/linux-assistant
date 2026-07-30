import 'package:flutter/material.dart';
import 'package:linux_assistant/layouts/mint_y.dart';
import 'package:linux_assistant/layouts/run_command_queue.dart';
import 'package:linux_assistant/services/main_search_loader.dart';
import 'package:linux_assistant/services/updater.dart';
import 'package:linux_assistant/l10n/app_localizations.dart';
import 'package:linux_assistant/services/weekly_tasks.dart';

class LinuxAssistantUpdatePage extends StatefulWidget {
  const LinuxAssistantUpdatePage({super.key});

  @override
  State<LinuxAssistantUpdatePage> createState() =>
      _LinuxAssistantUpdatePageState();
}

class _LinuxAssistantUpdatePageState extends State<LinuxAssistantUpdatePage> {
  /// Started once. As a `build()` local this re-fired the weekly check — which
  /// includes a network request to api.github.com with a five second timeout —
  /// on every rebuild of the startup screen.
  late final Future<void> weeklyTasks = WeeklyTasks.doWeekleyTasks();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: weeklyTasks,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            LinuxAssistantUpdater.isNewerVersionAvailable()) {
          return MintYPage(
            title: AppLocalizations.of(context)!.update,
            contentElements: [
              Text(
                AppLocalizations.of(context)!.aNewVersionIsAvailable,
                style: Theme.of(context).textTheme.displayLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 10,
              ),
              Text(
                AppLocalizations.of(context)!.doYouWantToUpdateNow,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            bottom: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MintYButtonNavigate(
                  route: const MainSearchLoader(),
                  text: Text(
                    AppLocalizations.of(context)!.later,
                    style: MintY.heading4,
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                MintYButtonNavigate(
                  onPressed: () {
                    LinuxAssistantUpdater.updateLinuxAssistantToNewestVersion();
                  },
                  route: RunCommandQueue(
                      message: AppLocalizations.of(context)!
                          .linuxAssistantIsUpdating,
                      title: AppLocalizations.of(context)!.update,
                      route: const MainSearchLoader()),
                  text: Text(
                    AppLocalizations.of(context)!.updateNow,
                    style: MintY.heading4White,
                  ),
                  color: MintY.currentColor,
                ),
              ],
            ),
          );
        } else if (snapshot.connectionState == ConnectionState.done ||
            snapshot.hasError) {
          // This is where startup lands, so it is what opens the hub.
          return const MainSearchLoader(destination: LoaderDestination.hub);
        } else {
          return const MintYLoadingPage();
        }
      },
    );
  }
}
