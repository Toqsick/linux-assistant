# Hermes Layer – Backlog / Wartebank

> **Status:** ⏸️ Geparkt. Der Hermes-Layer ist noch nicht final durchdacht und
> wird **nicht** in der aktuellen Etappe (ThemeExtension-Migration,
> Dashboard/Settings-Fokus, siehe `feature/theme-extension`) weiterentwickelt.
> Dieser Branch ist die Sammelstelle, bis das Konzept steht.

---

## Was existiert bereits

Aus dem Fork (`lib/widgets/hermes/`, Tokens in `lib/layouts/hermes_tokens.dart`):

| Komponente | Datei | Vermutete Rolle |
|---|---|---|
| HermesCard | `hermes_card.dart` | Karten-Basis des neuen Looks |
| HermesBadge | `hermes_badge.dart` | Status-/Label-Chips |
| HermesNavItem | `hermes_nav_item.dart` | Sidebar-Navigation |
| HermesStatTile | `hermes_stat_tile.dart` | Dashboard-Kachel (Wert + Trend) |
| HermesSparkline | `hermes_sparkline.dart` | Mini-Verlaufschart |
| HermesHaloDot | `hermes_halo_dot.dart` | Leuchtender Status-Punkt |
| HermesCopyCommand | `hermes_copy_command.dart` | Kommando-Zeile mit Copy-Button |

Web-Referenz im Styleguide: `docs/design/linux-assistant-ui-templates.html`
enthält HTML-Entsprechungen (Nav, StatTile, HaloDot, CopyCommand).

---

## Scope-Trennung (festgelegt)

```
┌────────────────────────────────────────────┐
│ Layer 2: HERMES (optional, modern, Glass)  │  ← dieser Backlog
├────────────────────────────────────────────┤
│ Layer 1: MINT-Y TOKENS (Basis, verifiziert)│  ← feature/theme-extension
├────────────────────────────────────────────┤
│ Layer 0: Flutter Material 3                │
└────────────────────────────────────────────┘
```

- **Mint-Y bleibt die Basis.** Alle Kern-Tokens (Farben, Typo, Radius,
  Spacing) leben in `lib/layouts/mint_y_tokens.dart`.
- **Hermes konsumiert Mint-Y-Tokens**, definiert keine eigenen Farbwerte.
  Erst wenn `hermes_tokens.dart` gegen `MintYColors` gemappt ist, gilt der
  Layer als integriert.
- Hermes ist **opt-in** (Preset „Modern"), niemals Pflicht-Look.

---

## Offene Design-Fragen (vor Reaktivierung klären)

1. **Visuelle Identität:** Wie weit darf Hermes von Mint-Y abweichen?
   (Glow/Halo, Blur, Gradients vs. flache Mint-Y-Flächen)
2. **Glassmorphism:** Backdrop-Blur auf Linux/GTK ist teuer –
   Performance-Budget pro Screen definieren (Ziel: < 1 ms zusätzliche
   Rasterzeit, messbar mit Flutter Performance Overlay).
3. **Token-Mapping:** Welche Hermes-Tokens mappen auf `MintYColors`,
   welche sind genuinely neu (z. B. Halo-Glow-Stärke, Blur-Radius)?
4. **Zustandsmodell:** HermesNavItem/HermesBadge brauchen definierte
   Zustände (default/hover/focus/active/disabled) analog zur Roadmap.
5. **Dark-only oder beide Themes?** Glow-Effekte funktionieren auf hellem
   Grund schlecht – ggf. Hermes als Dark-only-Preset deklarieren.
6. **Motion:** HaloDot-Pulsieren, Sparkline-Animation – Durations/Curves
   erst nach Motion-Spec (Roadmap) festlegen.
7. **A11y:** Glow nicht als einzigen Statusindikator; Kontrast der
   transluzenten Flächen gegen WCAG AA prüfen.
8. **Abbhängigkeit von Etappe 1:** Hermes-Widgets auf
   `context.mintY.*` umstellen, sobald PR B/C gemerged sind.

---

## Reaktivierungs-Kriterien (Definition of Ready)

Der Layer verlässt die Wartebank, wenn:

- [ ] ThemeExtension-Migration gemerged (PR A–C aus `theme-extension-migration.md`)
- [ ] Offene Fragen 1–7 oben entschieden (kurzer ADR pro Entscheidung)
- [ ] `hermes_tokens.dart` vollständig auf `MintYColors` gemappt
- [ ] Mindestens 1 Referenz-Screen (Dashboard) komplett in Hermes umgesetzt
- [ ] Golden Tests für Hermes-Komponenten (Dark, Akzente mint/zorin)

## Ideen-Sammlung (unverbindlich)

- Hermes als „Profi-Modus"-Skin: mehr Datendichte, Sparklines überall
- HaloDot als globaler System-Status-Indikator in der Titelleiste
- CopyCommand mit Erfolgs-Feedback (Clipboard-Toast)
- Distro-Halo: HaloDot-Farbe folgt `MintYAccent`
