import 'dart:async';

import 'package:flutter/material.dart';
import 'package:linux_assistant/content/basic_entries.dart';
import 'package:linux_assistant/content/recommendations.dart';
import 'package:linux_assistant/layouts/hub/hub_shell.dart';
import 'package:linux_assistant/layouts/main_screen/main_search.dart';
import 'package:linux_assistant/layouts/mint_y.dart';
import 'package:linux_assistant/models/action_entry.dart';
import 'package:linux_assistant/services/action_entry_list_service.dart';
import 'package:linux_assistant/services/config_handler.dart';
import 'package:linux_assistant/services/linux.dart';
import 'package:linux_assistant/l10n/app_localizations.dart';
import 'package:logger/logger.dart';

/// What the loader shows once the action catalog is ready.
enum LoaderDestination {
  /// The launcher-style search screen.
  search,

  /// The hub, with the dashboard selected.
  hub,
}

class MainSearchLoader extends StatefulWidget {
  const MainSearchLoader({
    super.key,
    this.destination = LoaderDestination.search,
  });

  /// Defaults to [LoaderDestination.search] so the many existing "back to
  /// search" buttons keep behaving exactly as before.
  final LoaderDestination destination;

  @override
  State<MainSearchLoader> createState() => _MainSearchLoaderState();
}

class _MainSearchLoaderState extends State<MainSearchLoader> {
  late final Future<void> futureVoid;

  @override
  void initState() {
    super.initState();
    // Started once, here — not in `build()`. Rebuilds are cheap and frequent
    // (the hub's theme toggle rebuilds the whole app), while `prepare()` clears
    // the entry list and re-runs a filesystem scan plus three python scripts.
    futureVoid = prepare();
  }

  /// Runs one index module, bounded so a hanging scan cannot wedge the loader.
  Future<void> _module(String name, Future<void> work) {
    return work.timeout(
      const Duration(seconds: 20),
      onTimeout: () => _onTimeoutOfSearchLoadingModule(name),
    ).catchError((Object e) {
      Logger().w("Loading $name failed: $e");
    });
  }

  Future<void> prepare() async {
    MainSearch.unregisterHotkeysForKeyboardUse();

    ConfigHandler configHandler = ConfigHandler();
    await configHandler.ensureConfigIsLoaded();
    if (!mounted) {
      return;
    }
    Future clearOldEntries = configHandler.clearOldDatesOfOpenendEntries();

    // prepare Action Entries

    // List<Future<List<ActionEntry>>> futures = [];

    // if (configHandler.getValueUnsafe("search_filter_basic_folders", true)) {
    //   print("Loading basic folders");
    //   futures.add(Linux.getAllFolderEntriesOfUser(context).timeout(
    //       timeoutDuration,
    //       onTimeout: () =>
    //           _onTimeoutOfSearchLoadingModule("applicationEntries")));
    //   // future1 = Linux.getAllFolderEntriesOfUser(context);
    // }

    ActionEntryListService.clearEntries();

    // These six run concurrently and are intentionally not awaited as a group:
    // the search box should appear immediately and fill in as results land.
    // Each one is bounded, though — an unbounded `find` used to be able to run
    // for minutes with nothing to stop it.
    final List<Future<void>> modules = [];

    if (configHandler.getValueUnsafe("search_filter_basic_folders", true)) {
      modules.add(
          _module("basic folders", Linux.getAllFolderEntriesOfUser(context)));
    }

    // if (configHandler.getValueUnsafe("search_filter_applications", true)) {
    //   print("Loading applications");
    //   futures.add(Linux.getAllAvailableApplications().timeout(timeoutDuration,
    //       onTimeout: () =>
    //           _onTimeoutOfSearchLoadingModule("applicationEntries")));
    // }

    if (configHandler.getValueUnsafe("search_filter_applications", true)) {
      modules.add(
          _module("applications", Linux.getAllAvailableApplications()));
    }

    // if (configHandler.getValueUnsafe(
    //     "search_filter_recently_used_files_and_folders", true)) {
    //   print("Loading recently used files and folders");
    //   futures.add(Linux.getRecentFiles(context).timeout(timeoutDuration,
    //       onTimeout: () => _onTimeoutOfSearchLoadingModule("recentFiles")));
    // }

    if (configHandler.getValueUnsafe(
        "search_filter_recently_used_files_and_folders", true)) {
      modules.add(_module("recent files", Linux.getRecentFiles(context)));
    }

    // if (configHandler.getValueUnsafe(
    //     "search_filter_favorite_files_and_folder_bookmarks", true)) {
    //   print("Loading favorite files and folder bookmarks");
    //   futures.add(Linux.getFavoriteFiles(context).timeout(timeoutDuration,
    //       onTimeout: () => _onTimeoutOfSearchLoadingModule("favoriteFiles")));
    // }

    if (configHandler.getValueUnsafe(
        "search_filter_favorite_files_and_folder_bookmarks", true)) {
      modules.add(_module("favorite files", Linux.getFavoriteFiles(context)));
    }

    // if (configHandler.getValueUnsafe("search_filter_bookmarks", true)) {
    //   print("Loading browser bookmarks");
    //   futures.add(Linux.getBrowserBookmarks(context).timeout(timeoutDuration,
    //       onTimeout: () =>
    //           _onTimeoutOfSearchLoadingModule("browserBookmarks")));
    // }

    if (configHandler.getValueUnsafe("search_filter_bookmarks", true)) {
      modules.add(
          _module("browser bookmarks", Linux.getBrowserBookmarks(context)));
    }

    // Deinstallation Entries.
    // if (configHandler.getValueUnsafe(
    //     "search_filter_uninstall_software", true)) {
    //   print("Loading uninstall entries");
    //   futures.add(Linux.getUninstallEntries(context).timeout(timeoutDuration,
    //       onTimeout: () =>
    //           _onTimeoutOfSearchLoadingModule("uninstall_entries")));
    // }
    if (configHandler.getValueUnsafe(
        "search_filter_uninstall_software", true)) {
      modules.add(
          _module("uninstall entries", Linux.getUninstallEntries(context)));
    }
    unawaited(Future.wait(modules));

    // ActionEntryList returnValue = ActionEntryList(entries: []);
    // returnValue.entries.addAll(getRecommendations(context));
    // returnValue.entries.addAll(getBasicEntries(context));
    List<ActionEntry> functionEntries = [];
    functionEntries.addAll(getRecommendations(context));
    functionEntries.addAll(getBasicEntries(context));

    // // Collect all Futures in our returnValue.
    // for (Future<List<ActionEntry>> future in futures) {
    //   returnValue.entries.addAll(await future);
    // }

    // if (configHandler.getValueUnsafe(
    //     "search_filter_recently_used_files_and_folders", true)) {
    //   print("Loading recently used files and folders");
    //   var additionalFolders =
    //       Linux.getFoldersOfActionEntries(context, ActionEntryListService.getEntries());
    //   print("Finished: search_filter_recently_used_files_and_folders");
    //   // returnValue.entries.addAll(additionalFolders);
    //   ActionEntryListService.addEntries(additionalFolders);
    // }

    // Remove action entries for specific environments
    List<ActionEntry> entriesToRemove = [];
    for (ActionEntry entry in functionEntries) {
      if (entry.disableEntryIf != null) {
        // If the disableEntryIf function of the entry gets true, remove:
        if (entry.disableEntryIf!()) {
          entriesToRemove.add(entry);
        }
      }
    }
    for (ActionEntry entry in entriesToRemove) {
      // returnValue.entries.remove(entry);
      functionEntries.remove(entry);
    }
    ActionEntryListService.addEntries(functionEntries);
    await configHandler.setValue("runFirstStartUp", false);
    await clearOldEntries;
  }

  void _onTimeoutOfSearchLoadingModule(String module) {
    Logger().w(
        "Timeout of loading $module! Please report this to the developers on https://www.linux-assistant.org.");
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: futureVoid,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return widget.destination == LoaderDestination.hub
              ? const HubShell()
              : MainSearch();
        } else {
          return MintYLoadingPage(
              text: AppLocalizations.of(context)!.preparingSearch);
        }
      },
    );
  }
}
