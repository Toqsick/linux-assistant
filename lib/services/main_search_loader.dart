import 'package:flutter/material.dart';
import 'package:linux_assistant/content/basic_entries.dart';
import 'package:linux_assistant/content/recommendations.dart';
import 'package:linux_assistant/layouts/main_screen/main_search.dart';
import 'package:linux_assistant/layouts/mint_y.dart';
import 'package:linux_assistant/models/action_entry.dart';
import 'package:linux_assistant/services/action_entry_list_service.dart';
import 'package:linux_assistant/services/config_handler.dart';
import 'package:linux_assistant/services/linux.dart';
import 'package:linux_assistant/l10n/app_localizations.dart';

class MainSearchLoader extends StatefulWidget {
  const MainSearchLoader({Key? key}) : super(key: key);

  @override
  State<MainSearchLoader> createState() => _MainSearchLoaderState();
}

class _MainSearchLoaderState extends State<MainSearchLoader> {
  late Future<void> futureVoid;

  @override
  void initState() {
    super.initState();
    // P1: initialise once in initState — build() can be called multiple times
    // (e.g. theme change, resize) which would restart prepare() on every rebuild.
    futureVoid = prepare();
  }

  Future<void> prepare() async {
    MainSearch.unregisterHotkeysForKeyboardUse();

    ConfigHandler configHandler = ConfigHandler();
    await configHandler.ensureConfigIsLoaded();
    Future clearOldEntries = configHandler.clearOldDatesOfOpenendEntries();

    ActionEntryListService.clearEntries();

    // P2: wrap fire-and-forget calls in unawaited error handlers so exceptions
    // are logged rather than silently swallowed.
    if (configHandler.getValueUnsafe("search_filter_basic_folders", true)) {
      print("Loading basic folders");
      Linux.getAllFolderEntriesOfUser(context).catchError((e) {
        print("Error loading basic folders: $e");
        return <ActionEntry>[];
      });
    }

    if (configHandler.getValueUnsafe("search_filter_applications", true)) {
      print("Loading applications");
      Linux.getAllAvailableApplications().catchError((e) {
        print("Error loading applications: $e");
        return <ActionEntry>[];
      });
    }

    if (configHandler.getValueUnsafe(
        "search_filter_recently_used_files_and_folders", true)) {
      print("Loading recently used files and folders");
      Linux.getRecentFiles(context).catchError((e) {
        print("Error loading recent files: $e");
        return <ActionEntry>[];
      });
    }

    if (configHandler.getValueUnsafe(
        "search_filter_favorite_files_and_folder_bookmarks", true)) {
      Linux.getFavoriteFiles(context).catchError((e) {
        print("Error loading favorite files: $e");
        return <ActionEntry>[];
      });
    }

    if (configHandler.getValueUnsafe("search_filter_bookmarks", true)) {
      print("Loading browser bookmarks");
      Linux.getBrowserBookmarks(context).catchError((e) {
        print("Error loading browser bookmarks: $e");
        return <ActionEntry>[];
      });
    }

    if (configHandler.getValueUnsafe(
        "search_filter_uninstall_software", true)) {
      print("Loading uninstall entries");
      Linux.getUninstallEntries(context).catchError((e) {
        print("Error loading uninstall entries: $e");
        return <ActionEntry>[];
      });
    }

    List<ActionEntry> functionEntries = [];
    functionEntries.addAll(getRecommendations(context));
    functionEntries.addAll(getBasicEntries(context));

    print("Removing disabled entries");
    List<ActionEntry> entriesToRemove = [];
    for (ActionEntry entry in functionEntries) {
      if (entry.disableEntryIf != null) {
        if (entry.disableEntryIf!()) {
          entriesToRemove.add(entry);
        }
      }
    }
    for (ActionEntry entry in entriesToRemove) {
      functionEntries.remove(entry);
    }
    ActionEntryListService.addEntries(functionEntries);
    print("Initiating configHandler");
    await configHandler.setValue("runFirstStartUp", false);
    await clearOldEntries;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: futureVoid,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return (MainSearch());
        } else {
          return MintYLoadingPage(
              text: AppLocalizations.of(context)!.preparingSearch);
        }
      },
    );
  }
}
