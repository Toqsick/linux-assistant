# Visuelle Baseline-Analyse (Phase 1, Schritt 4 – manuelle Referenz)
## Screenshots der laufenden App, Fork v0.7.1 auf Zorin OS 18.1

> Quelle: 9 Screenshots vom 2026-08-20 (lokaler Lauf, Zorin OS 18.1, GNOME,
> 1280×800-Fenster). Die JPGs liegen lokal vor und gehören nach
> `docs/design/baseline/` (Binär-Upload via Git, nicht via API).

---

## 1. ⚠️ Zentraler Befund: Der Fork hat ein eigenes UI

Die Screenshots zeigen: **Die v0.7.1-Fork-UI weicht fundamental vom Upstream ab.**
Das bisherige Audit (Inventory/Inconsistencies/Catalog) beschreibt den
Upstream-Stand (MintYPage + Bottom-Bar). Der Fork nutzt:

- **Sidebar-Navigation** (links, feste Breite): Dashboard, Suche, Speicher,
  Linux-Gesundheit, Sicherheitsüberprüfung; Einstellungen unten angepinnt
- **Top-Bar** pro Screen: Titel links, Aktionen rechts (Suche, Reload,
  Theme-Toggle Sonne/Mond)
- **Dashboard als Startscreen** mit Stat-Karten – die Roadmap-Forderung
  „Dashboard-first statt Search-first" ist im Fork bereits umgesetzt ✅

**Konsequenz für das Design System:** Die Token-Ebene (`mint_y_tokens.dart`)
bleibt gültig, aber die Dokumente müssen zwei Layout-Generationen
unterscheiden: „Classic" (Upstream, MintYPage) vs. „v0.7" (Fork, Sidebar).

---

## 2. Gemessene/geschätzte Fork-Tokens (aus den Screenshots)

| Token | Wert (geschätzt aus Screenshot) | Anmerkung |
|---|---|---|
| Akzent (aktiv) | Amber/Gold (~`#E6A817`) | **Nicht** Zorin-Blau – vermutlich Custom Color aus Appearance-Settings |
| Canvas Light | warmes Creme (~`#F7F3EA`) | Fork-eigen, nicht neutral-weiß |
| Surface Light | etwas dunkleres Creme mit feiner Border | Karten klar abgegrenzt |
| Canvas Dark | tiefes Navy-Schwarz (~`#0D0B1E`) | Fork-eigen, nicht `#1F1F1F` |
| Surface Dark | leicht aufgehelltes Navy | Karten mit subtiler Border |
| Nav-Item aktiv (Light) | Amber-Text + linker Akzent-Balken + helles Amber-Tint | HermesNavItem-Pattern ✅ |
| Nav-Item aktiv (Dark) | Amber-Text auf dunklem Amber-Tint + Akzent-Balken | konsistent |
| Badge (Zombies, Laufzeit) | Amber-Tint + Amber-Text, Pill-Form | HermesBadge-Pattern ✅ |
| Swap-Balken | Orange | neu dokumentiert (bisher nur CPU/RAM bekannt) |

**Aktion:** Diese Werte beim nächsten lokalen Lauf per `flutter inspect`/
Farb-Pipette exakt messen und in `mint_y_tokens.dart` als zweites
Fork-Preset (`MintYColors.darkV07()` / `lightV07()`?) hinterlegen –
oder klären, ob die Warm-Palette dem Hermes-Layer zugeordnet wird.

---

## 3. Screen-by-Screen-Baseline

| # | Screen | Theme | Inhalt/Besonderheiten |
|---|---|---|---|
| 1 | Dashboard | Light | Header-Karte (Hostname, Distro/Kernel/Desktop/CPU/GPU-Chips, Laufzeit-Badge), CPU 21 %, RAM 69 % + Swap-Zeile, Prozesse 765 + „3 Zombies"-Badge, Speicherplatz 88 % mit Balken pro Mount, Schnellaktionen-Grid (6 Karten mit Blitz-Icon) |
| 2 | Dashboard | Dark | identisch aufgebaut; Sparkline in Amber; Karten Navy |
| 3 | Suche | Light | Vertikale Disk-Balken (Zorin OS 88 %, DATA 81 %), CPU/RAM/Swap-Balken (blau/lila/orange), Hardware-Info-Karte, Suchfeld mit Query „a2", Empfehlungs-Karte unten (Redshift), Icon-Cluster unten rechts |
| 4 | Suche | Dark | gleiche Struktur, Suchfeld mit Dateiname-Query, Empfehlungs-Karte „Linux-Gesundheit" |
| 5 | Speicher | Light | Horizontale Balken mit Prozent-Chip rechts (88 %, 81 %), Gerätepfad + Belegt/Gesamt, „Speicherplatz bereinigen"-Aktion oben rechts |
| 6 | Speicher | Dark | identisch; Amber-Balken auf Navy |
| 7 | Linux-Gesundheit | Light | Laufzeit-Warnungen (orange ⚠), Prozess-Tabellen RAM/CPU, Speicher-Sektion mit grünen ✓ und orangen ⚠ |
| 8 | Linux-Gesundheit | Dark | identisch; gute Lesbarkeit der Statusfarben auf Navy |
| 9 | Sicherheitsüberprüfung | Dark | **Error-State:** „Das hat leider nicht funktioniert. Du benötigst Root-Rechte…" + „Erneut versuchen"-Link (Amber). Notieren: kein Icon, keine weitere Handlungsoption |

Abdeckung: 5 von 7 Haupt-Screens in beiden Themes (Dashboard, Suche,
Speicher, Linux-Gesundheit) + Security-Error-State. **Fehlen:**
Einstellungen (beide Themes), Sicherheitsüberprüfung Light + Erfolgs-State,
Greeter/Onboarding, Power-Mode, Terminal/RunCommandQueue.

---

## 4. UX-Notizen aus den Screenshots

1. **Error-State (Root-Rechte):** Funktional, aber spartanisch. Vorschlag aus
   der Roadmap greift hier: Icon + Erklärung + zwei CTAs („Erneut versuchen"
   + „Mit pkexec ausführen" o. ä.).
2. **Disk 88 % zeigt Amber, nicht Rot:** Der Fork nutzt offenbar den Akzent
   für die Balken und hebt kritische Werte nur im Chip hervor (oder der
   89 %-Schwellwert greift nicht mehr / anders). → Verhalten gegen
   `MintYThresholds.diskUsageWarningPercent` verifizieren!
3. **Schnellaktionen-Texte abgeschnitten:** Karten-Beschreibungen enden mit
   „…" (max 2 Zeilen). OK, aber Tooltip mit Volltext wäre gut.
4. **Prozess-Liste im Dashboard:** zeigt `claude-desktop` doppelt (2 PIDs) –
   fachlich korrekt, visuell aber wie ein Duplikat-Fehler wirkend. Ggf.
   Prozesse gleichen Namens aggregieren.
5. **Theme-Toggle in Top-Bar:** sichtbar und funktional (L/D-Paare beweisen
   es) ✅ – damit ist Live-Theme-Wechsel im Fork schon real; die
   ThemeExtension-Migration baut darauf auf.

---

## 5. Dateien lokal ablegen (Binär-Upload)

Die Connector-API kann nur Textdateien pushen. Für die JPGs lokal:

```bash
git checkout docs/design-audit
mkdir -p docs/design/baseline
# sinnvolle Namen vergeben:
cp Bildschirmfoto-vom-2026-08-20-22-55-24.jpg docs/design/baseline/dashboard.light.jpg
cp Bildschirmfoto-vom-2026-08-20-22-56-59.jpg docs/design/baseline/dashboard.dark.jpg
cp Bildschirmfoto-vom-2026-08-20-22-55-41.jpg docs/design/baseline/suche.light.jpg
cp Bildschirmfoto-vom-2026-08-20-22-56-43.jpg docs/design/baseline/suche.dark.jpg
cp Bildschirmfoto-vom-2026-08-20-22-55-58.jpg docs/design/baseline/speicher.light.jpg
cp Bildschirmfoto-vom-2026-08-20-22-56-25.jpg docs/design/baseline/speicher.dark.jpg
cp Bildschirmfoto-vom-2026-08-20-22-56-03.jpg docs/design/baseline/gesundheit.light.jpg
cp Bildschirmfoto-vom-2026-08-20-22-56-10.jpg docs/design/baseline/gesundheit.dark.jpg
cp Bildschirmfoto-vom-2026-08-20-22-57-04.jpg docs/design/baseline/sicherheit.error.dark.jpg
git add docs/design/baseline/ && git commit -m "docs: add v0.7.1 visual baseline screenshots" && git push
```

(Dateinamen-Mapping ggf. anhand der Thumbnails prüfen – Zuordnung oben nach
Bildinhalt.)

---

## 6. Konsequenzen für die Roadmap

| Bisherige Annahme | Korrektur durch Baseline |
|---|---|
| Dashboard-first ist ein Vorschlag | ✅ bereits implementiert – Roadmap-Punkt streichen |
| Sidebar/HermesNav ist Zukunft (Backlog) | ⚠️ teilweise bereits Realität – Hermes-Backlog um „ist-live-Teile" vs. „geplante Teile" differenzieren |
| Light-Theme zweitklassig | ✅ Fork-Light ist voll ausgebaut (warm) – `MintYColors.light()` an Fork-Werte anpassen |
| Disk-Warnung rot ab 89 % | ⚠️ im Fork nicht sichtbar (88 % amber) – Schwellwert-Verhalten prüfen |
