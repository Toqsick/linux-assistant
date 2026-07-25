import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linux_assistant/l10n/app_localizations.dart';
import 'package:linux_assistant/layouts/hermes_tokens.dart';
import 'package:linux_assistant/layouts/hub/hub_grid.dart';
import 'package:linux_assistant/layouts/mint_y.dart';
import 'package:linux_assistant/layouts/security_check/security_finding.dart';
import 'package:linux_assistant/widgets/hermes/hermes_badge.dart';
import 'package:linux_assistant/widgets/hermes/hermes_card.dart';
import 'package:linux_assistant/widgets/hermes/hermes_halo_dot.dart';
import 'package:linux_assistant/widgets/hermes/hermes_nav_item.dart';
import 'package:linux_assistant/widgets/hermes/hermes_sparkline.dart';
import 'package:linux_assistant/widgets/hermes/hermes_stat_tile.dart';

/// Wraps a widget in the app's real theme and localizations.
Widget _host(Widget child, {bool dark = false, Size size = const Size(900, 700)}) {
  return MaterialApp(
    theme: dark ? MintY.themeDark() : MintY.theme(),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en', '')],
    locale: const Locale('en', ''),
    home: Scaffold(
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: child,
      ),
    ),
  );
}

void main() {
  group("HermesCard", () {
    testWidgets("renders its child", (tester) async {
      await tester.pumpWidget(_host(
        const HermesCard(child: Text("payload")),
      ));
      expect(find.text("payload"), findsOneWidget);
    });

    testWidgets("is flat: no drop shadow", (tester) async {
      await tester.pumpWidget(_host(
        const HermesCard(child: Text("payload")),
      ));

      final container = tester.widget<Container>(
        find
            .ancestor(
              of: find.text("payload"),
              matching: find.byType(Container),
            )
            .last,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.boxShadow, anyOf(isNull, isEmpty));
      expect(decoration.border, isNotNull);
    });

    testWidgets("fires onTap", (tester) async {
      int taps = 0;
      await tester.pumpWidget(_host(
        HermesCard(onTap: () => taps++, child: const Text("tap me")),
      ));

      await tester.tap(find.text("tap me"));
      await tester.pump();
      expect(taps, 1);
    });
  });

  group("HermesBadge", () {
    testWidgets("shows its label", (tester) async {
      await tester.pumpWidget(_host(
        const HermesBadge(text: "P1 High", tone: HermesTone.error),
      ));
      expect(find.text("P1 High"), findsOneWidget);
    });

    test("every tone resolves to three distinct-purpose colors", () {
      for (final tone in HermesTone.values) {
        final colors = hermesToneColors(HermesTokens.light, tone);
        expect(colors.fg, isNotNull);
        expect(colors.bg, isNotNull);
        expect(colors.border, isNotNull);
      }
    });
  });

  testWidgets("HermesHaloDot renders", (tester) async {
    await tester.pumpWidget(_host(const HermesHaloDot()));
    expect(find.byType(HermesHaloDot), findsOneWidget);
  });

  group("HermesStatTile", () {
    testWidgets("shows label, value and unit", (tester) async {
      await tester.pumpWidget(_host(
        const HermesStatTile(
          label: "CPU usage",
          icon: Icons.speed,
          value: "42",
          unit: "%",
        ),
      ));

      expect(find.text("CPU USAGE"), findsOneWidget);
      expect(find.text("42"), findsOneWidget);
      expect(find.text("%"), findsOneWidget);
    });

    testWidgets("falls back to a dash before data arrives", (tester) async {
      await tester.pumpWidget(_host(
        const HermesStatTile(label: "RAM", icon: Icons.memory),
      ));
      expect(find.text("—"), findsOneWidget);
    });
  });

  group("HermesSparkline", () {
    testWidgets("renders with a normal series", (tester) async {
      await tester.pumpWidget(_host(
        const HermesSparkline(values: [0.1, 0.5, 0.3, 0.9, 0.4]),
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets("survives empty and single-point series", (tester) async {
      await tester.pumpWidget(_host(const HermesSparkline(values: [])));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(_host(const HermesSparkline(values: [0.5])));
      expect(tester.takeException(), isNull);
    });
  });

  group("HermesNavItem", () {
    testWidgets("selected item reports itself to accessibility",
        (tester) async {
      await tester.pumpWidget(_host(
        HermesNavItem(
          icon: Icons.dashboard,
          label: "Dashboard",
          selected: true,
          onTap: () {},
        ),
      ));

      expect(find.text("Dashboard"), findsOneWidget);
      final semantics = tester.getSemantics(find.byType(HermesNavItem));
      expect(semantics.hasFlag(SemanticsFlag.isSelected), isTrue);
    });

    testWidgets("hides the label when collapsed", (tester) async {
      await tester.pumpWidget(_host(
        HermesNavItem(
          icon: Icons.dashboard,
          label: "Dashboard",
          selected: false,
          collapsed: true,
          onTap: () {},
        ),
      ));
      expect(find.text("Dashboard"), findsNothing);
    });
  });

  group("HubGrid", () {
    testWidgets("uses more columns as the window widens", (tester) async {
      Future<double> tileWidthAt(double width) async {
        await tester.pumpWidget(_host(
          HubGrid(
            minTileWidth: 260,
            children: List.generate(4, (i) => Text("tile$i")),
          ),
          size: Size(width, 700),
        ));
        await tester.pump();
        return tester.getSize(find.ancestor(
          of: find.text("tile0"),
          matching: find.byType(SizedBox),
        ).first).width;
      }

      final narrow = await tileWidthAt(300);
      final wide = await tileWidthAt(1200);

      // One column when narrow, several when wide: the tile itself shrinks.
      expect(narrow, greaterThan(wide));
    });

    testWidgets("renders nothing when empty", (tester) async {
      await tester.pumpWidget(_host(const HubGrid(children: [])));
      expect(tester.takeException(), isNull);
    });
  });

  group("SecurityFindingTile", () {
    testWidgets("shows severity, explanation and the command", (tester) async {
      await tester.pumpWidget(_host(
        const SecurityFindingTile(
          finding: SecurityFinding(
            severity: FindingSeverity.high,
            title: "Firewall is inactive",
            why: "A firewall blocks incoming connections.",
            command: "sudo ufw status verbose",
          ),
        ),
      ));

      expect(find.text("Firewall is inactive"), findsOneWidget);
      expect(find.textContaining("P1"), findsOneWidget);
      expect(find.text("sudo ufw status verbose"), findsOneWidget);
      expect(find.textContaining("A firewall blocks"), findsOneWidget);
    });

    testWidgets("offers no button that changes the system", (tester) async {
      await tester.pumpWidget(_host(
        const SecurityFindingTile(
          finding: SecurityFinding(
            severity: FindingSeverity.high,
            title: "Firewall is inactive",
            command: "sudo ufw status verbose",
          ),
        ),
      ));

      // The only interactive control is "copy to clipboard".
      final buttons = find.byType(IconButton).evaluate();
      expect(buttons.length, 1);
      expect(find.byIcon(Icons.copy), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets("an OK finding carries no command", (tester) async {
      await tester.pumpWidget(_host(
        const SecurityFindingTile(
          finding: SecurityFinding(
            severity: FindingSeverity.ok,
            title: "Firewall is running",
          ),
        ),
      ));

      expect(find.text("OK"), findsOneWidget);
      expect(find.byType(IconButton), findsNothing);
    });

    testWidgets("renders in dark mode too", (tester) async {
      await tester.pumpWidget(_host(
        const SecurityFindingTile(
          finding: SecurityFinding(
            severity: FindingSeverity.medium,
            title: "Updates pending",
            command: "apt list --upgradable",
          ),
        ),
        dark: true,
      ));

      expect(tester.takeException(), isNull);
      expect(find.text("Updates pending"), findsOneWidget);
    });
  });
}
