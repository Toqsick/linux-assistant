# UI/UX-Analyse — Linux Assistant v0.7.1 (Baseline) + 0.8.0-Codestand

**Datum:** 2026-09-10 · **Evidence-Basis:** 14 Baseline-Screenshots (`screenshots/v0.7.1/`), Code-Recon (5 Agenten), Live-Session auf Zorin OS 18.1 (Wayland), journal-Evidence.
**Skala:** 🔴 Critical · 🟠 Important · 🟡 Minor · 💡 Nice-to-have. Zielversion: V0.8.0 (diese Session) / V0.8.X / V0.9 (s. roadmap.md).

---

## 🔴 Critical

**C1 — Die Sicherheitsprüfung lügt über ihre Fehler.**
Nach erfolgreicher Passwort-Eingabe (journal: „successfully authenticated") crasht das alte
`check_security.py`; die UI zeigt statisch „Du benötigst Root-Rechte…" — für JEDEN Fehler,
auch Script-Crashs. stderr wird geschluckt (in Output konkateniert, nie angezeigt).
→ Evidence: `screenshots/v0.7.1/04b`, `04c`; `lib/layouts/security_check/overview.dart:92` (v0.7.1);
journal 2026-09-10 21:53:19. **Fix in V0.8.0:** rc-Unterscheidung (126/127 = Rechte; sonst Script-Fehler
+ stderr-Ausschnitt). Der deb822-Crash selbst ist bereits gefixt (`apt_sources.py`).

## 🟠 Important

**I1 — Theme-Toggle ohne Zustands-Anzeige.** Der Topbar-Button durchläuft einen 3er-Zyklus
(system→light→dark), zeigt aber nicht, welcher Modus aktiv ist. Live nachvollzogen: ein Klick
von „dark" landet bei „system" — auf dunklem Desktop bleibt die UI dunkel, der Nutzer glaubt,
der Toggle sei kaputt (genau das ist der Session-Verlauf; Ø-RGB-Messung 16,15,26 vs. erwartetes Light).
→ `lib/services/theme_controller.dart`, Toggle in `hub_shell.dart:365-386`. **V0.8.X:** Modus-Anzeige
(Icon + Tooltip/Label „System hell/dunkel") oder Drehschalter mit Menü.

**I2 — Zwei konkurrierende Widget-/Token-Systeme.** `MintY*`-Legacy (15 Widgets, `mint_y.dart`, 1165 Zeilen)
vs. `Hermes*` (7 Widgets) vs. neu `MintYColors` (mint_y_tokens.dart) DREI Farb-/Stilquellen. Screens
mischen beide Familien → inkonsistente Anmutung, doppelter Wartungsaufwand; einzelne Screens lesen
statisch `MintY.currentColor`/`MintY.dark` statt Theme (z. B. `main_search.dart:189`).
→ **V0.8.X.7** (Migration + Goldens #30 schützen danach).

**I3 — E1–E4-Werkzeuge sind nicht lokalisiert.** `tools/system_monitor.dart`, `tools/file_manager.dart`
etc. enthalten hardcoded deutsche Strings (Snackbars „Löschen fehlgeschlagen…", „Signal an … gesendet")
neben l10n-gerechten Alt-Screens (en/de/it/fi ARBs existieren). Für nicht-deutsche Nutzer bricht die Sprache mitten in der App.
→ Issue #25; **V0.8.X.7.**

**I4 — Hardcoded Farben auf Gradient-Flächen.** `Colors.white` (main_search.dart:289,375,391,824;
settings_widgets.dart:158), `Colors.red` (uninstaller_question.dart:22,58; clean_disk.dart:132;
cleaner_select_disk.dart:45), Grau-Fixwerte (disk_space.dart:49) — brechen bei Theme-/Akzentwechsel
(sichtbar riskant in Light: Weiß-auf-Creme-Kanten).
→ **V0.8.X** (mit I2 zusammen erledigen).

**I5 — Finnisch generiert, aber nicht registriert.** `app_localizations_fi.dart` (1146 Zeilen) existiert,
`supportedLocales` (main.dart:281-285) meldet nur en/de/it — fi ist toter Code; README wirbt mit Finnisch.
→ **V0.8.0** (Phase E, 1-Zeiler + Test).

**I6 — Sicherheits-Sektion triggert den Scan automatisch beim Betreten.** Jeder Seitenbesuch startet
pkexec + Passwortdialog — im Session-Verlauf zweimal passiert (21:53 Auth durch Basti; später erneuter
Dialog). Nutzer, die nur schauen wollen, werden mit Root-Prompts konfrontiert; der Dialog gehört zur
teuersten Interaktion der App.
→ **V0.8.X:** Scan nur noch explizit per Button („Prüfen"), Ergebnis cachen (TTL), Auto-Scan als Opt-in.

## 🟡 Minor

**M1 — Deutsche Rechtschreibung/Duverz im UI.** „Schau Deinem Linux-Nach**bor**" (→ Nachbar),
uneinheitliche Anrede: App duzt („Trage hier deine Suchbegriffe"), Polkit-Meldungen siezen
(„Ihr Passwort", `org.linux-assistant.operations.policy`). → V0.8.X l10n-Pass.

**M2 — Magic-Number-Geometrie.** Radii 10/9/7/2 und Spacings 20/26/40/52/64 neben den Tokens 4/8/12/999
(action_entry_card.dart:47, hub_shell.dart:293, clean_disk.dart:134, cleaner_select_disk.dart:47).
→ mit I2/I4 aufräumen.

**M3 — Health-Sektion zeigt Roh-Daten.** Partition „Gentle(GPartitonale)" (PARTLABEL ungefiltert),
Prozesstabelle dicht, keine Sortier-/Filter-Hinweise im Shot erkennbar. → V0.9 System-Monitor-Ausbau.

**M4 — ~31 inline-TextStyles** außerhalb der zentralen Skala (11px-Labels, 12,5px-Meta, 28px-Tile-Wert).
Typografie-Skala definieren (design/typography.md listet alle Stellen). → V0.8.X.

**M5 — God-Files.** `services/linux.dart` (3301), `mint_y.dart` (1165), `main_search.dart` (897) —
Änderungsrisiko und Review-Kosten steigen. → schrittweise in V0.8.X/V0.9 splitten (kein Big-Bang).

**M6 — Launcher-Suche ohne sichtbaren Leeren-Zustand-Hinweis auf Privatsphäre.** Recent/Favorite-Files
erscheinen sofort im Fokus (im Session-Betrieb personaldaten-trächtig bei Screenshots/Vorführungen).
→ V0.9: Privatsphäre-Modus / Historie-ausblenden Option (Existiert: „Suche-Historie löschen" in Sidebar —
gut! aber nur reaktiv).

## 💡 Nice-to-have

- **N1** — Breadcrumb „DASHBOARD → SYSTEMSTATUS → SCHNELLAKTIONEN" deklariert Hierarchie, ist aber nicht
  klickbar/navigierend. → V0.9 echte Breadcrumbs oder weg.
- **N2** — KPI-Tiles aktualisieren live (Sparklines) — gut! Persistente History + Schwellen-Badges ( roadmap V0.9 P1).
- **N3** — Einstellungen als Dialog statt Sektion wirkt inkonsistent zur Sidebar-Navi (Einstellungen IST
  ein Sidebar-Item, öffnet aber Modal). → V0.8.X prüfen: Sektion statt Dialog.
- **N4** — Fokus-Zustände/Tastatur-Navigation nicht systematisch geprüft ( Flutter-Defaults vermutlich ok,
  aber nicht belegt) → mit Goldens (#30) + manuellem Pass in V0.8.X klären.

---

## Ehrliches Urteil: „Admin-Linux-Hub"-Readiness

**Trägt bereits:** HubShell mit Sektionen + Sidebar/Rail, ThemeExtension-Token (HermesTokens, AA-sicherer
Akzent-Rechner, 13 Distro-Paletten), Hermes-Widget-Vokabular (StatTile/Sparkline/Badge — genau die
Dashboard-Bausteine), E1–E4-Werkzeuge als Proof-of-Pattern (Service + Screen + Registry-Eintrag),
Live-Systemstats-Service, polkit-feingranulare Policy-Struktur (auf 0.8.0).

**Fehlt für das Ziel:** (1) eine Tool-/Plugin-Registry als formale Naht (#27) — aktuell ist „Werkzeuge"
ein Enum + if/else; (2) privilegierte Aktionen über einen Helper (#28) statt Scatter-pkexec; (3)
Persistenz/History für Monitor-Daten; (4) die Härtung unten (Error-UX, l10n, Widget-Einheit) — ein
Admin-Hub, dem man bei Fehlern nicht glauben kann, ist kein Admin-Hub (C1!).

**Fazit:** Fundament ist besser als der Ruf der Version — die 0.8.0-Härtung + Registry in 0.8.X machen
den Hub plausibel; V0.9-Module sind dann reine Registrierungsarbeit. Das größte Einzelrisiko bleibt
C1 (Vertrauen), das größte Strukturrisiko I2 (drei Stil-Systeme).
