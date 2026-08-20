import 'package:flutter/material.dart';

/// MintYColors – ThemeExtension für das Linux Assistant Design System.
///
/// Ersetzt schrittweise den globalen Mutable-State `MintY.currentColor` /
/// `MintY.secondaryColor` aus `mint_y.dart`. Vorteile:
/// - Hot-Switch des Distro-Akzents ohne App-Neustart
/// - Testbar (Golden Tests pro Theme)
/// - Kein globaler State, saubere Dependency via Theme.of(context)
///
/// Zugriff:
/// ```dart
/// final colors = Theme.of(context).extension<MintYColors>()!;
/// Container(color: colors.accent);
/// ```
///
/// Registrierung im Theme:
/// ```dart
/// ThemeData(
///   extensions: [MintYColors.dark(MintYAccent.mint)],
/// )
/// ```
@immutable
class MintYColors extends ThemeExtension<MintYColors> {
  const MintYColors({
    required this.accent,
    required this.accentSecondary,
    required this.canvas,
    required this.surface,
    required this.surfaceRaised,
    required this.textPrimary,
    required this.textDim,
    required this.statusSuccess,
    required this.statusWarning,
    required this.statusDanger,
    required this.chartCpu,
    required this.chartRam,
    required this.chartDisk,
    required this.chartTrack,
  });

  /// Hauptakzent (ersetzt MintY.currentColor). Steuert Buttons,
  /// Checkboxen, Icons, Textselektion, Fortschrittsbalken.
  final Color accent;

  /// Sekundärakzent (ersetzt MintY.secondaryColor), distro-spezifisch.
  final Color accentSecondary;

  /// App-Hintergrund (Dark: #1F1F1F).
  final Color canvas;

  /// Karten-/Panel-Fläche (Dark: #2D2D2D).
  final Color surface;

  /// Erhöhte Fläche für Hover/Selected-Zustände.
  final Color surfaceRaised;

  final Color textPrimary;

  /// Gedämpfter Text. ACHTUNG: #9D9D9D auf #2D2D2D liegt unter WCAG AA
  /// (ca. 3.3:1) – für Body-Text #B5B5B5 verwenden (siehe Roadmap).
  final Color textDim;

  /// Statusfarben – nur für echte Systemzustände verwenden.
  final Color statusSuccess;
  final Color statusWarning;
  final Color statusDanger;

  /// Funktionale Chart-Farben (memory_status, disk_space).
  final Color chartCpu;
  final Color chartRam;
  final Color chartDisk;
  final Color chartTrack;

  /// Dark-Theme (Standard der App) mit wählbarem Distro-Akzent.
  factory MintYColors.dark(MintYAccent accent) {
    final pair = accent.colors;
    return MintYColors(
      accent: pair.primary,
      accentSecondary: pair.secondary,
      canvas: const Color(0xff1f1f1f),
      surface: const Color(0xff2d2d2d),
      surfaceRaised: const Color(0xff383838),
      textPrimary: const Color(0xffffffff),
      textDim: const Color(0xffb5b5b5), // Kontrast-Fix statt #9D9D9D
      statusSuccess: const Color(0xff4caf50),
      statusWarning: const Color(0xffff9800),
      statusDanger: const Color(0xfff44336),
      chartCpu: const Color(0xff4699dd),
      chartRam: const Color(0xffc177f3),
      chartDisk: const Color(0xff8d8d8d),
      chartTrack: const Color(0xff3a3a3a),
    );
  }

  /// Light-Theme mit symmetrischem Token-Set (Roadmap-Punkt:
  /// Light war bisher zweitklassig, canvasColor/cardColor fehlten).
  factory MintYColors.light(MintYAccent accent) {
    final pair = accent.colors;
    return MintYColors(
      accent: pair.primary,
      accentSecondary: pair.secondary,
      canvas: const Color(0xfffafafa),
      surface: const Color(0xffffffff),
      surfaceRaised: const Color(0xfff0f0f0),
      textPrimary: const Color(0xff000000),
      textDim: const Color(0xff5a5a5a),
      statusSuccess: const Color(0xff388e3c),
      statusWarning: const Color(0xfff57c00),
      statusDanger: const Color(0xffd32f2f),
      chartCpu: const Color(0xff4699dd),
      chartRam: const Color(0xffc177f3),
      chartDisk: const Color(0xff8d8d8d),
      chartTrack: const Color(0xffd3d3d3),
    );
  }

  @override
  MintYColors copyWith({
    Color? accent,
    Color? accentSecondary,
    Color? canvas,
    Color? surface,
    Color? surfaceRaised,
    Color? textPrimary,
    Color? textDim,
    Color? statusSuccess,
    Color? statusWarning,
    Color? statusDanger,
    Color? chartCpu,
    Color? chartRam,
    Color? chartDisk,
    Color? chartTrack,
  }) {
    return MintYColors(
      accent: accent ?? this.accent,
      accentSecondary: accentSecondary ?? this.accentSecondary,
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      textPrimary: textPrimary ?? this.textPrimary,
      textDim: textDim ?? this.textDim,
      statusSuccess: statusSuccess ?? this.statusSuccess,
      statusWarning: statusWarning ?? this.statusWarning,
      statusDanger: statusDanger ?? this.statusDanger,
      chartCpu: chartCpu ?? this.chartCpu,
      chartRam: chartRam ?? this.chartRam,
      chartDisk: chartDisk ?? this.chartDisk,
      chartTrack: chartTrack ?? this.chartTrack,
    );
  }

  @override
  MintYColors lerp(ThemeExtension<MintYColors>? other, double t) {
    if (other is! MintYColors) return this;
    return MintYColors(
      accent: Color.lerp(accent, other.accent, t)!,
      accentSecondary: Color.lerp(accentSecondary, other.accentSecondary, t)!,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textDim: Color.lerp(textDim, other.textDim, t)!,
      statusSuccess: Color.lerp(statusSuccess, other.statusSuccess, t)!,
      statusWarning: Color.lerp(statusWarning, other.statusWarning, t)!,
      statusDanger: Color.lerp(statusDanger, other.statusDanger, t)!,
      chartCpu: Color.lerp(chartCpu, other.chartCpu, t)!,
      chartRam: Color.lerp(chartRam, other.chartRam, t)!,
      chartDisk: Color.lerp(chartDisk, other.chartDisk, t)!,
      chartTrack: Color.lerp(chartTrack, other.chartTrack, t)!,
    );
  }
}

/// Typisiertes Akzent-Farbpaar (Primary + Secondary).
class MintYAccentPair {
  const MintYAccentPair(this.primary, this.secondary);
  final Color primary;
  final Color secondary;
}

/// Distro-Akzente als Enum – ersetzt die String-Keys aus
/// getColorByName()/setMainColor() (Laufzeit-Typo-Risiko entfällt).
///
/// Werte verifiziert aus main.dart (setMainColor) und mint_y.dart.
enum MintYAccent {
  /// Linux Mint / Default.
  mint(MintYAccentPair(Color(0xff6db443), Color(0xff2ab9a4))),

  /// LMDE.
  lmde(MintYAccentPair(Color(0xff35a854), Color(0xff238246))),

  /// Debian.
  debian(MintYAccentPair(Color(0xffd0074e), Color(0xff2ab9a4))),

  /// openSUSE.
  opensuse(MintYAccentPair(Color(0xff73ba25), Color(0xff0f5f4b))),

  /// KDE Neon.
  kdeNeon(MintYAccentPair(Color(0xff236896), Color(0xff18a087))),

  /// Ubuntu (Roadmap-Erweiterung).
  ubuntu(MintYAccentPair(Color(0xffe95420), Color(0xff77216f))),

  /// Zorin OS (Roadmap-Erweiterung).
  zorin(MintYAccentPair(Color(0xff15a6cf), Color(0xff0c7ba6))),

  /// Fedora (Roadmap-Erweiterung).
  fedora(MintYAccentPair(Color(0xff51a2da), Color(0xff294172))),

  /// Arch (Roadmap-Erweiterung).
  arch(MintYAccentPair(Color(0xff1793d1), Color(0xff0f5f8a))),

  /// Pop!_OS (Roadmap-Erweiterung).
  popos(MintYAccentPair(Color(0xff48b9c7), Color(0xff2d8a95))),

  /// Manjaro (Roadmap-Erweiterung).
  manjaro(MintYAccentPair(Color(0xff35bf5c), Color(0xff1f7a3a)));

  const MintYAccent(this.colors);
  final MintYAccentPair colors;
}

/// Radius-Tokens (verifiziert aus den Layouts).
abstract final class MintYRadius {
  /// Mini-Progressbars (cleaner_select_disk).
  static const double xs = 2;

  /// Fortschrittsbalken (clean_disk).
  static const double sm = 7;

  /// Info-Chips, Security-Check-Boxen.
  static const double md = 8;

  /// Action-Entry-Cards / ListTiles / Buttons.
  static const double lg = 10;

  /// Große Panels / Hero-Cards (flathub_permissions).
  static const double xl = 20;
}

/// Spacing-Tokens (aus SizedBox-/Padding-Mustern).
/// TODO(Roadmap): auf 4er/8er-Raster vereinheitlichen (10 → 8 oder 12).
abstract final class MintYSpacing {
  static const double s1 = 8;
  static const double s2 = 10;
  static const double s3 = 16;
  static const double s4 = 32;
}

/// Typografie-Tokens (verifiziert aus mint_y.dart).
abstract final class MintYText {
  static const TextStyle heading1 =
      TextStyle(fontSize: 32, fontWeight: FontWeight.w500);
  static const TextStyle heading2 =
      TextStyle(fontSize: 24, fontWeight: FontWeight.w400);
  static const TextStyle heading3 =
      TextStyle(fontSize: 20, fontWeight: FontWeight.w400);
  static const TextStyle heading4 =
      TextStyle(fontSize: 16, fontWeight: FontWeight.w400);

  /// Monospace für Terminal-/Log-Ausgabe. Fallback-Stack statt reinem
  /// "Courier" (Roadmap: nicht auf jedem Linux vorhanden).
  static const TextStyle mono = TextStyle(
    fontSize: 14,
    fontFamily: 'JetBrains Mono',
    fontFamilyFallback: ['DejaVu Sans Mono', 'Courier', 'monospace'],
  );
}

/// Funktionale Schwellwerte – vorher Magic Numbers im Code.
abstract final class MintYThresholds {
  /// Disk-Auslastung in %, ab der der Balken rot wird (disk_space.dart).
  static const int diskUsageWarningPercent = 89;

  /// CPU-Last (x100), ab der der Balken rot wird (memory_status.dart).
  static const double cpuLoadCritical = 1.0;
}
