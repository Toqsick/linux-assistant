import 'dart:async';

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

  /// Downloads and verifies the package before anything is queued.
  ///
  /// The button used to queue a `wget` and an `apt install` and navigate away
  /// immediately, so a download that failed or was tampered with was followed
  /// by an install attempt regardless.
  Future<void> _startUpdate(BuildContext context) async {
    final String updating =
        AppLocalizations.of(context)!.linuxAssistantIsUpdating;
    final String title = AppLocalizations.of(context)!.update;
    final NavigatorState navigator = Navigator.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    unawaited(navigator.push(MaterialPageRoute(
      builder: (context) => const MintYLoadingPage(),
    )));

    final String? error = await LinuxAssistantUpdater.prepareUpdate();

    if (error != null) {
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    unawaited(navigator.pushReplacement(MaterialPageRoute(
      builder: (context) => RunCommandQueue(
        message: updating,
        title: title,
        route: const MainSearchLoader(destination: LoaderDestination.hub),
      ),
    )));
  }

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
                  // Same destination as the no-update path below. Without it,
                  // declining an update drops the user into the launcher
                  // overlay instead of the hub, which looks like the new
                  // interface never arrived.
                  route: const MainSearchLoader(
                      destination: LoaderDestination.hub),
                  text: Text(
                    AppLocalizations.of(context)!.later,
                    style: MintY.heading4,
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                MintYButton(
                  onPressed: () => _startUpdate(context),
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
