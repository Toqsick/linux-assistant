# Deep-Research-Prompt: Linux-Assistant-Verbesserungen

**Verwendung:** Inhalt unterhalb der Trennlinie komplett in Perplexity einfügen (Modus „Deep Research"). Erstellt 2026-09-11 aus dem Roadmap-/Ideen-Pool des Forks; Repo-Fakten im Kontext entsprechen Stand v0.8.0.

---

# Deep Research: Umsetzungsoptionen für geplante Verbesserungen an „Linux Assistant" (Flutter/Dart Linux-Desktop-App)

Du bist ein Senior-Technologie-Analyst für Linux-Desktop-Entwicklung und Flutter/Dart. Recherchiere für das unten beschriebene Projekt zu **jedem Themenblock alle realistischen Umsetzungswege** — jeweils: selbst entwickeln vs. bestehende Open-Source-Bibliotheken/Pakete integrieren vs. bestehende externe Tools einbinden. Prüfe den **aktuellen Stand (2025/2026)** von Paketen, Protokollen und APIs — nicht den Stand von vor Jahren. Kennzeichne alles Unbelegte explizit als unsicher und gib Quellen (Links) an.

## 0. Projektkontext (belegter Ist-Zustand, nicht hinterfragen)

- **App:** „Linux Assistant" — täglicher Linux-Helfer: globale-Hotkey-Launcher (Standard Super+Q, auf Zorin/Ubuntu/Pop!_OS/KDE Alt+Q) mit mächtiger Suche + „Admin-Hub" (Dashboard mit Live-Tiles CPU/RAM/Disk, Sidebar-Navigation) und eingebetteten Tools: Browser-Launcher, Quick Notes, Dateimanager, Systemmonitor.
- **Stack:** Flutter/Dart (C++/GTK-Runner) + privilegierte Python-Helfer; Paketierung ausschließlich Debian (.deb); Dart ≥ 3.4, Flutter ≥ 3.27. Lokalisiert (en/de/it/fi).
- **Zielplattform (Fokus):** Zorin OS 18.1 (GNOME-Basis) und Ubuntu 24.04 LTS; X11- und Wayland-Sessions werden unterstützt. Weitere Distros (Mint, Fedora, Arch …) sind nice-to-have.
- **Aktuelle Flutter-Abhängigkeiten (komplett):** flutter_localizations, intl, fl_chart, flutter_svg_provider, hotkey_manager, window_manager, crypto, http, hexcolor, logger, mutex. **Es existieren bislang KEINE Pakete für Webview, Terminal-Emulation, Audio-Aufnahme, PDF oder resizable Docks — alle einschlägigen Themen sind Greenfield.**
- **Hotkey-Realität:** X11 → In-App-Grab via hotkey_manager (libkeybinder); Wayland → kein globales Grab, stattdessen desktopspezifische gsettings-Keybindings (GNOME/Cinnamon) per Python-Skript.
- **Browser-Launcher (Ist):** einfache `which`-Probe über 7 hartkodierte Binärnamen (`brave`, `brave-browser`, `firefox`, `chromium`, `chromium-browser`, `google-chrome`, `falkon`), Fallback `xdg-open`; Flatpak-Erkennung nur in einem separaten After-Installation-Flow (u. a. `com.brave.Browser`).
- **Quick Notes (Ist):** Markdown-Dateien unter `$XDG_DATA_HOME/linux-assistant/notes/`, Autosave, reiner TextField-Editor ohne Markdown-Rendering, kein Interface für Attachments/Audio.
- **Hub-Architektur (Ist):** Tools sind ein hartes Flutter-Enum (kein Plugin-Registry — eine Registry-Architektur ist als nächster Architekturschritt geplant); Sidebar fix 260 px (nicht resizable); Dashboard-Tiles sind eigene ThemeExtension-basierte Widgets (StatTile + Sparkline).
- **Sicherheitsmodell (Invarianten, nicht verhandelbar):** Alle privilegierten Aktionen laufen über eine JSON-Lines-Command-Queue (keine Shell, Hash-Check) mit polkit — genau zwei feingranulare Polkit-Actions mit gehashten Exec-Pfaden. „So wenige Abhängigkeiten wie möglich" und Free-Software-Präferenz sind Manifest-Grundsätze.
- **Feature-Tier-Modell:** Features werden klassifiziert als **Core** (Mission, Release-Blocker bei Bruch), **QoL** (Alltagskomfort, keine neuen System-Abhängigkeiten über Core hinaus, darf auf Distros fehlen) und **n2h** (Nice-to-have: optional, kleiner Abhängigkeits-Fußabdruck, Security-Invarianten unangetastet, Entfernung legitim). Jedes recherchierte Thema soll am Ende eine Tier-Einordnung bekommen.

## 1. Private Eigeninfrastruktur — IMPORTANT: nicht öffentlich recherchierbar

Die folgenden Komponenten sind **private Eigenentwicklungen des App-Autors und nicht Gegenstand der Recherche** (nicht versuchen, sie im Web zu „finden"). Behandle sie als Blackboxes mit diesen Interfaces; recherchiere ausschließlich die **generischen Integrationsmuster**:

- **Hermes** — persönlicher AI-Agenten-Stapel: Gateway als systemd `--user`-Dienst (lokale HTTP/SSE-API), ein Kanban-Board, eine Web-UI (HTML/CSS/JS im Browser lauffähig) und eine CLI (u. a. `hermes kanban wrap`).
- **Odysseus** — eigener API-Gateway-/Scoped-API-Layer (stellt u. a. authentifizierte Zugriffe Dritter Dienste bereit).
- **ZCode & Claude Code** — externe Coding-Agent-CLIs mit Hook-/Event-Systemen (die App kann deren Hooks/Logs beobachten, aber nicht steuern).
- **token-calc** — eigenes Dashboard, das Token-Verbrauchsdaten exportiert (Export-/SQLite-Datei als Datenquelle).

## 2. Themenblöcke

### Thema 1 — Hermes-Integration: Web-UI des Hermes Agent in die App einbetten

Ziel: Die bestehende Hermes-Web-UI (läuft lokal gegen das Hermes-Gateway) soll in einem Hub-Screen nutzbar sein.

Forschungsfragen:

1. **Stand der Flutter-Linux-Webviews 2025/26:** Unterstützt `webview_flutter` Linux offiziell? Was leistet `flutter_inappwebview` auf Linux? Gibt es belastbare WebKitGTK-Anbindungen (Platform-Views, dart:ffi, Pakete wie webf o. ä.)? Was ist der stabilste Weg, eine lokale Web-App in ein Flutter-GTK-Fenster einzubetten — inkl. typischer Risiken (Compositing, DPI-Skalierung, Eingabemethoden)?
2. **Alternativen zum Einbetten:** Eigener Dart-Client gegen die Gateway-HTTP/SSE-API (Chat-UI in Flutter nativ nachbauen) vs. externer Browser-Aufruf vs. Einbetten. Kriterien: Wartungsaufwand, Nutzererlebnis, Abhängigkeits-Fußabdruck.
3. **Auth/Session lokal:** Bewährte Muster, eine lokale Web-UI mit Token/Auth aus einer nativen Desktop-App heraus zu betreiben (Session-Cookies, Token im GNOME-Keyring), ohne zusätzliche Daemon-Abhängigkeiten.
4. Gibt es Referenzprojekte (Open Source), die eine lokale Web-UI in einer Flutter-Desktop-App einbetten?

### Thema 2 — Tokentelemetrie (ggf. mit Kanban verknüpfen)

Ziel: Token-Verbrauchsdaten aus dem Export/SQLite eines bestehenden Dashboards als Tiles/Sparklines im Hub zeigen (StatTile-/Sparkline-Widgets existieren bereits); optional Korrelation mit Kanban-Aufgaben.

Forschungsfragen:

1. Bewährte lokale Dashboard-Muster für Zeitreihen-Daten in Flutter (Ringpuffer → Datei, SQLite via drift/sqflite_common_ffi auf Linux — was ist stand 2025/26 empfehlenswert?).
2. Gibt es leichtgewichtige offene Schemas/Standards für LLM-Token-Telemetrie (z. B. Anleihen bei OpenTelemetry, Langfuse-Selbsthosting als Vergleich), die man beim eigenen Datenformat berücksichtigen sollte?
3. Muster für „Kosten pro Aufgabe": Wie korreliert man Plugin-/Agent-Events (Hook-Logs) mit Aufgaben-IDs eines Kanban-Boards — welche Datenmodell-Ansätze sind üblich (Event-Sourcing, Join-Table, Tagging)?

### Thema 3 — Agenten-übergreifendes Kanban-Board (Hermes, ZCode, Claude)

Ziel: Ein gemeinsames Kanban-Board, das alle Agent-Workflows (Hermes-Kanban, ZCode-Sessions, Claude-Code-Sessions) teilen. Offene Alternative: einfach das bestehende Hermes-Kanban als Single Source of Truth nutzen.

Forschungsfragen:

1. **Vergleich lokaler, selbst-hostbarer Kanban-Tools mit API** (Stand 2025/26): Kanboard (JSON-RPC), Planka (REST), Vikunja (API-first), Wekan, Focalboard/Mattermost Boards, Leantime o. a. — Kriterien: Single-Binary/Low-Footprint, lokale Auth, API-Vollständigkeit, Debian-Paket, Free-Software-Lizenz, Activity-Streams/Webhooks.
2. **Hermes-Kanban als SoT + Adapter:** Welche Muster sind etabliert, um externe Events (Claude-Code-Hooks, ZCode-Hook-/Session-Events, Cron-Läufe) in ein bestehendes Board zu spiegeln (Webhooks → Adapter-Dienst, File-Watcher, Polling)? Risiken Zwei-Wege-Sync vs. Read-only-Spiegel.
3. Gibt es offene Formate/Standards für agenten-übergreifende Task-/Workflow-Boards (z. B. A2A-Task-Objekte, MCP-Server mit Board-Anbindung — Stand 2025/26)?
4. Empfehlung: eigenes Board-Widget in der App (read-only + Quick-Actions) vs. Board in Webview/externem Browser.

### Thema 4 — Wetter-Widget / Wetter-App

Forschungsfragen:

1. **Freie Wetter-APIs im Vergleich** (Datenschutz zuerst, kein Tracking): Open-Meteo (kostenlos, ohne API-Key? kommerzielle Grenzen?), MET Norway / yr.no (Nutzungsbedingungen, User-Agent-Pflicht), OpenWeatherMap (Key, Free-Tier-Grenzen) — welche ist 2025/26 für eine Free-Software-Desktop-App mit „so wenigen Abhängigkeiten wie möglich" am besten geeignet?
2. Flutter-Pakete für diese APIs (Stand, Wartungsstatus) — oder direkte HTTP-Anbindung (Paket `http` ist bereits vorhanden)?
3. Integrationsebene: Hub-Tile im Dashboard (empfohlener Weg?) vs. echtes Desktop-Widget (GNOME-Shell-Erweiterung — Aufwand, Zorin-Kompatibilität). Lokale Wetterstation/Metar als n2h-Option?

### Thema 5 — Browser-Support erweitern (u. a. Brave)

Ist: Launcher kennt 7 Binärnamen (Brave bereits enthalten), Flatpak-ID `com.brave.Browser` nur im After-Installation-Flow.

Forschungsfragen:

1. **Robuste Browser-Erkennung auf Linux 2025/26:** Best Practices jenseits von `which` — `.desktop`-Dateien/XDG-Mime (`x-scheme-handler/http`), `xdg-settings get default-web-browser`, Flatpak-IDs, Snap-Namen. Wie machen es referenzierte Apps (z. B. GNOME Web, Federated-Launcher-Projekte)?
2. **Vollständige Browser-Matrix:** Binärname + Flatpak-ID + Snap-Name der gängigen Linux-Browser (Firefox/ESR, Brave, Chromium, Chrome, Edge, Opera, Vivaldi, LibreWolf, Waterfox, Tor, Falkon, Zen?) inkl. Besonderheiten (Snap-Firefox auf Ubuntu 24.04!, Flatpak-Pfad-Isolation).
3. **Profil- und Modus-Steuerung per CLI:** Private Fenster (`--private`/`--incognito`/`-p` je Browser), Profilwahl (`--profile-directory`), `--new-window` — wo unterscheiden sich die Browser; was ist für einen Launcher realistisch ohne in Browser-Interna zu verschwinden?
4. Lohnt sich als QoL: „Standard-Browser-Status" im Hub (was ist eingestellt, per `xdg-settings` wechselbar)?

### Thema 6 — Notizen: Transkription + QoL-Features

Ist: Markdown-Dateien, reiner TextField-Editor, Autosave, keine Attachments.

Forschungsfragen:

1. **Lokale Spracherkennung auf dem Desktop (Datenschutz zuerst):** Stand 2025/26 von whisper.cpp und faster-whisper auf CPU/GPU (auch AMD?), Modellgrößen für Diktat-Qualität (de/en), Realzeit-Faktor. Gibt es belastbare Dart/Flutter-Bindings oder ist der pragmatische Weg ein Python-Helfer ( whisper.cpp-CLI über die bestehende Python-Schicht)?
2. **Audio-Aufnahme in Flutter/Linux:** Welche Pakete funktionieren auf PulseAudio/PipeWire (Paket `record`? flutter_sound?) — Stand und Linux-Desktop-Reife; Alternative: Aufnahme via Python-Helfer.
3. **Markdown-Editor-Komponenten für Flutter** (Stand/Wartung): flutter_quill, super_editor, AppFlowy Editor, markdown_widget — welche eignet sich für einen Notiz-Editor mit Live-Preview, Checklisten und Codeblöcken?
4. **QoL-Funktionen mit Prior art:** Notiz-Vorlagen, Wiki-Links `[[]]`, Tags, Volltextsuche (SQLite FTS5?), Anhänge, Foto-/Screenshot-in-Notiz, Sync-Optionen (git-basiert, Syncthing-Ordner) — was ist praxiserprobt ohne Cloud-Zwang?

### Thema 7 — Wayland-optimiert & Zorin-optimiert

Ziel: Die App soll auf Wayland (und speziell Zorin OS 18/GNOME) erstklassig funktionieren.

Forschungsfragen:

1. **Globale Hotkeys unter Wayland 2025/26:** Implementierungsstand des XDG-desktop-portal-Protokolls `GlobalShortcuts` in xdg-desktop-portal-gnome (welche GNOME-Versionen?), KDE und wlroots-Compositoren. Was ist der realistische Weg für eine Flutter-App (Portal-DBus direkt ansprechen? Flutter-Pakete? Weiterhin gsettings-Fallback für GNOME/Zorin?).
2. **Tray-Icon unter GNOME:** StatusNotifierItem-Status in GNOME 45+ (AppIndicator-Extension nötig?), Alternativen (DBus-Menu, Portal?), Empfehlung für Zorin.
3. **Fenster-Fokus/Aktivierung:** xdg-activation-Protokoll — wie hebt eine Flutter/GTK-App ihr Fenster auf Wayland zuverlässig in den Vordergrund (Ersatz für `wmctrl -a`)? Flutter- Pakete (window_manager — Wayland-Einschränkungen?).
4. **Zorin OS 18 spezifisch:** GNOME-Basisversion von Zorin 18, Zorin-eigene Erweiterungen/Abweichungen (Zorin Appearance, Layouts), was bedeutet das für gsettings-Pfade (Keybindings) und Theme-Erkennung; Unterschiede Zorin-X11 vs. Zorin-Wayland-Session.
5. Häufige Wayland-Fallstricke für GTK3/Flutter-Apps (Fractional Scaling, Texteingabemethoden, Screenshots/Screen-Cast via Portal, Klemmbrett) — Checkliste für „Wayland-optimiert".

### Thema 8 — Layout: stufenlos verstellbare Dash-Leiste + app-weites rechtes Dock

Ziel: (a) Die linke Sidebar/Dash-Leiste soll stufenlos in der Breite verstellbar (Drag) sein; (b) eine dauerhafte rechte Seitenleiste (app-weit über allen Hub-Screens), in die sich Panels andocken lassen — z. B. Datei-Vorschau oder ein Terminal.

Forschungsfragen:

1. **Resizable-Split-Panels in Flutter 2025/26:** Welche Pakete sind produktionsreif (multi_split_view, flutter_resizable o. a.)? Oder eigenes `GestureDetector`-Pattern — was ist wartbarer? Persistenz der Breiten (Config-Handler existiert) und A11y/Tastatur-Resize.
2. **Docking-Architektur:** Muster für einen app-weiten rechten Dock mit mehreren stapelbaren/kombinierbaren Panels (Datei-Vorschau, Terminal, Notiz-Vorschau) über IndexedStack-Screens hinweg — Provider/Controller-Pattern, Panel-Registry-Anschluss an die geplante Tool-Registry.
3. **Datei-Vorschau im Dock:** Reife Flutter-Lösungen für Text (Syntax-Highlight), Bilder, PDF (pdfx/pdfrx?), Video — Stand auf Linux; oder Vorschau via `gio preview`/ externe Tools (Abwägung).
4. Eingebettetes Terminal im Dock: siehe Thema 9 (Schnittstelle: „Terminal-Komponente, die im Dock leben kann").

### Thema 9 — „Terminal+": eingebettetes Terminal mit Syntax-Highlighting & Praxis-Features

Forschungsfragen:

1. **Eingebettetes Terminal in Flutter auf Linux (Stand 2025/26):** Reife von xterm.dart (Terminal-Widget) + PTY-Anbindung (flutter_pty o. ä. via FFI) — Stabilität, Escape-Sequenz-Abdeckung, Performance bei viel Output. Realistische Alternativen: VTE (GTK-Widget) einbetten (Platform-View/FFI — machbar?) vs. externes Terminal spawnen (Ist-Zustand).
2. **Syntax-Highlighting im Terminal:** Was ist technisch möglich und sinnvoll (Shell-Integration-Protokolle wie OSC 133 für Command-Delimiting, semantische Nachfärbung, VTE-Ansatz)? Realistischer Scope für ein Desktop-App-Terminal vs. Full-Feature-Emulator.
3. **Praxis-Features mit Prior art:** Auto-Vorschläge (fish-artig), Command-Palette/History (Ctrl+R-Ersatz), Snippets, SSH-Profile, Quick-Actions für Admin-Tasks der App. Welche existierenden Open-Source-Terminals (Ptyxis, Black Box, WezTerm, GNOME Console) lösen das gut — und ist „Integrieren statt Nachbauen" (z. B. Ptyxis als bevorzugtes externes Terminal + Deep-Linking) die bessere Empfehlung nach dem Free-Software/Minimal-Dependency-Grundsatz?
4. Sicherheitsabwägung: eingebettetes Terminal in einer App mit privilegierten Pfaden (Command-Queue) — wo müssen Trennlinien gezogen werden (Terminal läuft unprivilegiert als User-Shell)?

### Thema 10 — Proton Hub: Mail, VPN, Pass(Passwort-Manager), Auth, Drive

Ziel: Ein Hub-Screen als zentrale Anlaufstelle für Proton-Dienste (realistischer Scope: Status + Quick-Actions vs. Vollclient — bitte bewerten).

Forschungsfragen (je Produkt Stand 2025/26 belegen):

1. **Proton Mail:** Linux-Desktop-App-Status (offizielle App?), Proton Mail Bridge (IMAP/SMTP lokal — nur zahlende Pläne?), offizielle REST-API für Third-Party-Clients (ToS, open-source SDK?). Was kann ein Hub realistisch: Launch/Status/Unread-Abfrage?
2. **Proton VPN:** Offizieller Linux-Client/CLI (Distribution per eigenem Repo?), WireGuard-Config-Download für manuelles Setup, Statusabfrage (aktive Verbindung) aus einer App heraus — ohne die offizielle App zu umgehen (ToS!).
3. **Proton Pass:** CLI-Status (pass-cli?), Browser-Extension, API-Zugriff für Dritte; Alternative: Secrets nur als Links/Launch-Actions.
4. **Proton Drive:** Linux-Client-Status, rclone-Backend-Support (Stand!) — Sync-Status im Hub als QoL?
5. **Proton Authenticator** (existiert seit 2025?): Linux-Support, Integrationsoptionen.
6. Gesamtempfehlung: Welche Kombination „offizielle Apps starten + Status lesen + Quick-Actions" ist ohne ToS-Verstoß und ohne Reverse-Engineering realistisch für einen Hub-Screen?

### Thema 11 — Gmail + Odysseus-Frontend-Integration

Ziel: Mail-Zugriff (Gmail) über den eigenen Odysseus-API-Layer, Frontend in der App. Odysseus ist Blackbox (siehe Abschnitt 1) und kapselt OAuth/Dritt-APIs.

Forschungsfragen:

1. **Gmail-API für Desktop-Clients:** OAuth-2.0-Desktop-Flow (installed app), sinnvolle Scopes (read-only zuerst: `gmail.readonly`, `gmail.metadata`), Refresh-Token-Lebensdauer im Desktop-Kontext, Quoten/Pricing (Stand 2025/26).
2. **Alternative IMAP statt Gmail-API:** XOAUTH2-SASL mit Google-IMAP — Vor-/Nachteile gegenüber der API für ein reines Lese-/Such-Frontend.
3. **Architekturmuster „App ↔ eigener Gateway ↔ Google":** Token-Handhabung (wo liegt der Refresh-Token: im Gateway statt in der App?), Rate-Limit-Bündelung, Offline-Cache-Strategie (Lokale SQLite von Metadaten).
4. **Token-Speicher auf Linux-Desktop:** GNOME-Keyring/Secret-Service via D-Bus aus Flutter/Dart (Pakete? Stand) — Best Practice für Desktop-Apps.
5. Referenz-Frontends: Was zeigen Open-Source-Mail-Clients (Geary, Thunderbird, Mailspring) für ein minimales „Unread + Lesen + Schnellaktion"-Frontend?

### Thema 12 — Einordnung ins Tier-Modell

Für **jedes** Thema 1–11: Vorschlag Core / QoL / n2h mit einzeiliger Begründung nach diesen Regeln: Core = Missionskern (täglicher Helfer/Admin-Aufgaben), QoL = Komfort ohne neue System-Abhängigkeiten über Core-Bestand hinaus, n2h = optional, kleiner Abhängigkeits-Fußabdruck, Security-Invarianten unangetastet.

## 3. Querschnittsfragen

1. **Priorisierungsmatrix** über alle Themen: Nutzen für den täglichen Einsatz, Aufwand (S/M/L/XL), technische Abhängigkeiten untereinander (z. B. Tool-Registry-Architektur, la-helper für privilegierte Aktionen, GlobalShortcuts-Portal), Empfehlung Reihenfolge.
2. **Quick Wins:** Welche 3–5 Themen sind mit bestehender Infrastruktur (http, fl_chart, Config-Handler) in Tagen statt Wochen machbar?
3. **Abhängigkeits-Budget:** Welche Themen kollidieren mit dem Grundsatz „so wenige Abhängigkeiten wie möglich" und wie lässt sich das auflösen (Python-Helfer-Schicht vs. Flutter-Pakete vs. externe Tools)?
4. Wo gibt es **klare Absage-Empfehlungen** (Themen, die 2025/26 unrealistisch oder wartungstechnisch toxisch sind)?

## 4. Anforderungen an deine Ausgabe

- **Sprache: Deutsch** (Fachbegriffe/Paketnamen auf Englisch).
- **Pro Thema (1–11):** (1) Kurzstand „Stand 2025/26" mit Quellen, (2) Optionen-Vergleich als Tabelle: Ansatz | Bausteine/Pakete | Voraussetzungen | Risiken | Aufwand S/M/L/XL, (3) klare **Empfehlung mit Begründung** unter Berücksichtigung des Kontexts aus Abschnitt 0 (Free-Software-Präferenz, Minimal-Dependencies, Security-Invarianten), (4) Tier-Vorschlag.
- **Abschließend:** Priorisierungsmatrix, Quick-Wins-Liste, Absage-Empfehlungen, offene Fragen.
- **Quellen:** für jede belastbare Aussage einen Link; Versionsnummern/Datumsangaben nennen; bei Unsicherheit explizit „unklar/unverifiziert" schreiben statt schätzen.
