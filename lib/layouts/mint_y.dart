import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:linux_assistant/l10n/app_localizations.dart';
import 'package:linux_assistant/layouts/hermes_tokens.dart';

class MintY {
  /// Accent used for buttons, icons and the header gradient.
  ///
  /// Defaults to the Hermes gold. `MyApp.setMainColor()` may replace it with a
  /// distribution-specific color when the user opts into that.
  static Color currentColor = HermesTokens.light.accent;

  static Color secondaryColor = HermesTokens.light.accentHover;

  static bool dark = false;
  static MaterialColor currentColorTheme = green;

  static Color colors(String color) {
    switch (color) {
      case "Green":
        // return Color(0xff92b372);
        return const Color(0xff6db443);
      case "Aqua":
        return const Color(0xff6cabcd);
      case "Blue":
        return const Color(0xff5b73c4);
      case "Brown":
        return const Color(0xffaa876a);
      case "Grey":
        return const Color(0xff9d9d9d);
      case "Orange":
        return const Color(0xffdb9d61);
      case "Pink":
        return const Color(0xffc76199);
      case "Purple":
        return const Color(0xff8c6ec9);
      case "Red":
        return const Color(0xffc15b58);
      case "Sand":
        return const Color(0xffc8ac69);
      case "Teal":
        return const Color(0xff5aaa9a);
    }
    return const Color(0xff92b372);
  }

// Generated with: https://maketintsandshades.com/
  static const green = MaterialColor(
    0xff6db443,
    <int, Color>{
      50: Color(0xffb6daa1), //50% Hell
      100: Color(0xffa7d28e), //40% Hell
      200: Color(0xff99cb7b), //30% Hell
      300: Color(0xff8ac369), //20% Hell
      400: Color(0xff7cbc56), //10% Hell
      500: Color(0xff62a23c), //10% Dunkel
      600: Color(0xff579036), //20% Dunkel
      700: Color(0xff4c7e2f), //30% Dunkel
      800: Color(0xff416c28), //40% Dunkel
      900: Color(0xff375a22), //50% Dunkel
    },
  );

  /// A getter, not a field: as a field it captured [currentColor] once at class
  /// load time and kept showing the old gradient after a color or theme change.
  static BoxDecoration get colorfulBackground => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0, 1],
          colors: [currentColor, secondaryColor],
        ),
      );

  static const Color _white = Color.fromARGB(255, 255, 255, 255);

  static const heading1White = TextStyle(
      color: _white,
      fontSize: 32,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);

  // The non-White styles deliberately carry no color: they inherit it from the
  // ambient DefaultTextStyle, which the active theme drives. That is what makes
  // them legible in dark mode. The *White variants keep an explicit color
  // because they sit on the accent gradient, where white is always correct.
  static const heading1 = TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);

  static const heading2White = TextStyle(
      color: _white,
      fontSize: 24,
      fontWeight: FontWeight.w400,
      decoration: TextDecoration.none);

  static const heading2 = TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w400,
      decoration: TextDecoration.none);

  static const heading3White = TextStyle(
      color: _white,
      fontSize: 20,
      fontWeight: FontWeight.w400,
      decoration: TextDecoration.none);

  static const heading3 = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w400,
      decoration: TextDecoration.none);

  static const heading4White = TextStyle(
      color: _white,
      fontSize: 17,
      fontWeight: FontWeight.w400,
      decoration: TextDecoration.none);

  static const heading4 = TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w400,
      decoration: TextDecoration.none);

  static const paragraph = TextStyle(
      fontWeight: FontWeight.w400,
      decoration: TextDecoration.none,
      fontSize: 15);

  static const paragraphWhite = TextStyle(
    fontWeight: FontWeight.w300,
    color: _white,
    decoration: TextDecoration.none,
    fontSize: 15,
  );

  /// [accent] overrides the Hermes gold, e.g. with a distribution color. The
  /// derived tints and text colors are recomputed so contrast stays valid.
  static ThemeData theme({Color? accent}) => _buildTheme(
        accent == null
            ? HermesTokens.light
            : HermesTokens.light.withAccent(accent),
        Brightness.light,
      );

  static ThemeData themeDark({Color? accent}) => _buildTheme(
        accent == null
            ? HermesTokens.dark
            : HermesTokens.dark.withAccent(accent),
        Brightness.dark,
      );

  /// Builds a theme from a [HermesTokens] palette.
  ///
  /// Both brightnesses go through here so that light and dark can never drift
  /// apart. The previous themes set only `primaryColor` and left `colorScheme`
  /// at its default, which meant every Material 3 component ignored the app's
  /// colors entirely.
  static ThemeData _buildTheme(HermesTokens t, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: t.accent,
      onPrimary: t.onAccent,
      primaryContainer: t.accentBgStrong,
      onPrimaryContainer: t.accentText,
      secondary: t.info,
      onSecondary: isDark ? t.bg : const Color(0xFFFFFFFF),
      secondaryContainer: t.surfaceSubtle,
      onSecondaryContainer: t.text,
      tertiary: t.accentText,
      onTertiary: isDark ? t.bg : const Color(0xFFFFFFFF),
      error: t.error,
      onError: isDark ? t.bg : const Color(0xFFFFFFFF),
      errorContainer: t.surfaceSubtle,
      onErrorContainer: t.error,
      surface: t.bg,
      onSurface: t.text,
      onSurfaceVariant: t.muted,
      surfaceContainerLowest: t.bg,
      surfaceContainerLow: t.sidebar,
      surfaceContainer: t.surfaceSubtle,
      surfaceContainerHigh: t.surface,
      surfaceContainerHighest: t.surfaceSubtleHover,
      outline: t.border,
      outlineVariant: t.borderSubtle,
      inverseSurface: t.text,
      onInverseSurface: t.bg,
      inversePrimary: t.accentHover,
      shadow: const Color(0xFF000000),
      scrim: const Color(0xFF000000),
    );

    // The heading/paragraph styles carry no color of their own, so apply the
    // token colors once here instead of duplicating a *White variant per slot.
    const base = TextTheme(
      displayLarge: heading1,
      displayMedium: heading1,
      displaySmall: heading2,
      headlineLarge: heading2,
      headlineMedium: heading3,
      headlineSmall: heading4,
      titleLarge: heading3,
      titleMedium: heading4,
      titleSmall: paragraph,
      bodyLarge: paragraph,
      bodyMedium: paragraph,
      bodySmall: paragraph,
      labelLarge: paragraph,
      labelMedium: paragraph,
      labelSmall: paragraph,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      primaryColor: t.accent,
      scaffoldBackgroundColor: t.bg,
      canvasColor: t.bg,
      cardColor: t.surface,
      dividerColor: t.border,
      hoverColor: t.hoverBg,
      extensions: <ThemeExtension<dynamic>>[t],
      textTheme: base.apply(
        bodyColor: t.text,
        displayColor: t.strong,
      ),
      dividerTheme: DividerThemeData(
        color: t.border,
        space: 1,
        thickness: HermesTokens.borderWidth,
      ),
      cardTheme: CardThemeData(
        color: t.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HermesTokens.radiusMd),
          side: BorderSide(color: t.border, width: HermesTokens.borderWidth),
        ),
      ),
      iconTheme: IconThemeData(color: t.muted),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: t.surface,
          border: Border.all(color: t.border, width: HermesTokens.borderWidth),
          borderRadius: BorderRadius.circular(HermesTokens.radiusSm),
        ),
        textStyle: TextStyle(color: t.text, fontSize: 12),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.surfaceSubtle,
        hintStyle: TextStyle(color: t.muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HermesTokens.radiusMd),
          borderSide:
              BorderSide(color: t.border, width: HermesTokens.borderWidth),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HermesTokens.radiusMd),
          borderSide:
              BorderSide(color: t.border, width: HermesTokens.borderWidth),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HermesTokens.radiusMd),
          borderSide: BorderSide(color: t.accent, width: 2),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: t.accent,
        selectionColor: t.accentBgStrong,
        selectionHandleColor: t.accent,
      ),
    );
  }

  static void showMessage(
      BuildContext context, String message, VoidCallback? callback) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    message,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(
                  height: 32,
                ),
                MintYButton(
                  text: Text(
                    AppLocalizations.of(context)!.close,
                    style: MintY.heading3,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    callback?.call();
                  },
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

class MintYPage extends StatelessWidget {
  final String title;
  final List<Widget> contentElements;
  final Widget customContentElement;
  final Widget? bottom;

  MintYPage(
      {super.key,
      this.title = "",
      this.contentElements = const [],
      this.customContentElement = const Text(""),
      this.bottom});

  final ScrollController scrollController = ScrollController();

  // void _scrollListener() {
  //   // you can access the height of ListView content using maxScrollExtent
  //   print(_controller.position.maxScrollExtent);

  //   // if you wanna get once you can directly removeListener
  //   // _controller.removeListener(_scrollListener);
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        key: UniqueKey(),
        child: Column(
          children: [
            Container(
              decoration: MintY.colorfulBackground,
              padding: const EdgeInsets.all(26.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: MintY.heading2White,
                  ),
                ],
              ),
            ),
            Container(height: 8),
            contentElements.isNotEmpty
                ? Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: ListView(
                          shrinkWrap: true,
                          children: contentElements,
                        ),
                      ),
                    ),
                  )
                : customContentElement,
            Container(height: 8),
            bottom != null
                ? SizedBox(
                    height: 80,
                    child: Center(child: bottom),
                  )
                : Container()
          ],
        ),
      ),
    );
  }
}

class MintYButton extends StatelessWidget {
  final Widget text;
  final IconData? icon;

  /// deprecated, use [textColor] and [backgroundColor] instead
  final Color color;
  final Color backgroundColor;

  /// Only used for icon color currently:
  final Color textColor;
  final VoidCallback? onPressed;
  final double width;
  final double height;
  final String? tooltip;

  const MintYButton(
      {super.key,
      this.text = const Text(""),
      this.icon,

      /// deprecated, use [textColor] and [backgroundColor] instead
      Color color = const Color.fromARGB(0, 0, 0, 0),
      Color backgroundColor = const Color.fromARGB(0, 0, 0, 0),

      /// Only used for icon color currently:
      this.textColor = const Color.fromARGB(255, 255, 255, 255),
      this.tooltip,
      this.onPressed,
      this.width = 110,
      this.height = 40})
      : color = color,
        // An unset backgroundColor falls back to the deprecated [color]. The
        // old constructor body did this by assigning its own fields, which
        // also contained two no-op self-assignments (`text = text;`).
        backgroundColor = backgroundColor == const Color.fromARGB(0, 0, 0, 0)
            ? color
            : backgroundColor;

  @override
  Widget build(BuildContext context) {
    var buttonChildren = <Widget>[];

    if (icon != null) {
      buttonChildren.add(
        Icon(
          icon,
          color: textColor,
        ),
      );
      if (text is Text && (text as Text).data.toString().isNotEmpty) {
        buttonChildren.add(const SizedBox(width: 8));
      } else if (text is String && text.toString().isNotEmpty) {
        buttonChildren.add(const SizedBox(width: 8));
      }
    }

    if (text is Text) {
      buttonChildren.add(
        text as Text,
      );
    } else {
      buttonChildren.add(text);
    }

    Widget button = Container(
      constraints: BoxConstraints(minWidth: width, minHeight: height),
      child: ElevatedButton(
        key: UniqueKey(),
        onPressed: () {
          onPressed?.call();
        },
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(backgroundColor),
        ),
        child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: buttonChildren),
      ),
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    } else {
      return button;
    }
  }
}

class MintYButtonNavigate extends StatelessWidget {
  final Widget route;

  /// will be called before the button navigates
  final VoidCallback? onPressed;

  final Text text;
  final Color color;
  final double width;
  final double height;

  const MintYButtonNavigate(
      {required this.route,
      this.text = const Text("Text"),
      this.color = const Color.fromARGB(255, 232, 232, 232),
      this.width = 110,
      this.height = 40,
      this.onPressed,
      super.key});

  @override
  Widget build(BuildContext context) {
    return MintYButton(
      text: text,
      color: color,
      width: width,
      height: height,
      onPressed: () {
        onPressed?.call();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => route),
        );
      },
    );
  }
}

class MintYButtonNext extends StatelessWidget {
  final Widget route;

  /// will be called before the button navigates
  final VoidCallback? onPressed;

  /// will be called before the button navigates
  final AsyncCallback? onPressedFuture;

  const MintYButtonNext(
      {required this.route, this.onPressed, this.onPressedFuture, super.key});

  @override
  Widget build(BuildContext context) {
    return MintYButton(
      text: Text(
        AppLocalizations.of(context)!.next,
        style: MintY.heading4White,
      ),
      color: MintY.currentColor,
      onPressed: () async {
        onPressed?.call();
        if (onPressedFuture != null) {
          unawaited(Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => const MintYLoadingPage(),
          )));
          await onPressedFuture!.call();
        }
        if (!context.mounted) return;
        unawaited(Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => route),
        ));
      },
    );
  }
}

class MintYSelectableCardWithIcon extends StatefulWidget {
  final Widget icon;
  final String title;
  final String text;

  /// Initial selection. The current one lives in the state — the widget is
  /// rebuilt from its parent and must not carry the toggle itself.
  final bool selected;
  final VoidCallback? onPressed;

  const MintYSelectableCardWithIcon(
      {this.icon = const Icon(Icons.umbrella),
      this.title = "Title",
      this.text = "Lorem ipsum...",
      this.selected = false,
      this.onPressed,
      super.key});

  @override
  State<MintYSelectableCardWithIcon> createState() =>
      _MintYSelectableCardWithIconState();
}

class _MintYSelectableCardWithIconState
    extends State<MintYSelectableCardWithIcon> {
  late bool _selected = widget.selected;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: InkWell(
          onTap: () {
            setState(() {
              _selected = !_selected;
            });
            widget.onPressed?.call();
          },
          child: Container(
            padding: const EdgeInsets.all(15),
            height: 400,
            width: 350,
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(10),
                height: 30,
                child: _selected
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.check,
                            size: 30,
                            color: MintY.currentColor,
                          )
                        ],
                      )
                    : null,
              ),
              widget.icon,
              const SizedBox(
                height: 30,
              ),
              Text(widget.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center),
              const SizedBox(
                height: 16,
              ),
              Text(
                widget.text,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              )
            ]),
          ),
        ),
      ),
    );
  }
}

class MintYSelectableEntryWithIconHorizontal extends StatefulWidget {
  final Widget icon;
  final String title;
  final String text;

  /// Initial selection. The current one lives in the state.
  final bool selected;

  /// Shows only info text if [selected] == [showInfoTextAtThisSelectionState]
  final Text? infoText;

  /// Shows only info text if [selected] == [showInfoTextAtThisSelectionState]
  final bool showInfoTextAtThisSelectionState;

  final VoidCallback? onPressed;

  const MintYSelectableEntryWithIconHorizontal(
      {this.icon = const Icon(Icons.umbrella),
      this.title = "Title",
      this.text = "Lorem Ipsum...",
      this.selected = false,
      this.onPressed,
      this.infoText,
      this.showInfoTextAtThisSelectionState = false,
      super.key});

  @override
  State<MintYSelectableEntryWithIconHorizontal> createState() =>
      _MintYSelectableEntryWithIconHorizontalState();
}

class _MintYSelectableEntryWithIconHorizontalState
    extends State<MintYSelectableEntryWithIconHorizontal> {
  late bool _selected = widget.selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Card(
        child: InkWell(
          onTap: () {
            setState(() {
              _selected = !_selected;
            });
            widget.onPressed?.call();
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [widget.icon],
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Flexible(
                  fit: FlexFit.tight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        height: 16,
                      ),
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        widget.text,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 100,
                      ),
                      widget.infoText != null &&
                              widget.showInfoTextAtThisSelectionState ==
                                  _selected
                          ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: widget.infoText!,
                            )
                          : Container(),
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      child: _selected
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(
                                  Icons.check,
                                  size: 30,
                                  color: MintY.currentColor,
                                )
                              ],
                            )
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MintYButtonBigWithIcon extends StatelessWidget {
  final Widget icon;
  final String title;
  final String text;
  final VoidCallback? onPressed;

  const MintYButtonBigWithIcon({
    super.key,
    this.icon = const Icon(Icons.umbrella),
    this.title = "Title",
    this.text = "Lorem ipsum...",
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          onPressed?.call();
        },
        child: Container(
          padding: const EdgeInsets.all(15),
          height: 400,
          width: 300,
          child: Column(
            children: [
              const SizedBox(height: 15),
              icon,
              const SizedBox(height: 20),
              Text(title,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Text(
                text,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              )
            ],
          ),
        ),
      ),
    );
  }
}

class MintYCardWithIconAndAction extends StatelessWidget {
  final Widget icon;
  final String title;
  final String text;
  final String buttonText;
  final Widget? customWidgetBetweenButtonAndText;
  final VoidCallback? onPressed;

  const MintYCardWithIconAndAction({
    super.key,
    this.icon = const Text(""),
    this.title = "Title",
    this.text = "Lorem ipsum...",
    this.buttonText = "Button",
    this.customWidgetBetweenButtonAndText,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Card(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  icon,
                  const SizedBox(
                    width: 16,
                  ),
                  Flexible(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          text,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                ],
              ),
              if (customWidgetBetweenButtonAndText != null)
                customWidgetBetweenButtonAndText!,
              if (customWidgetBetweenButtonAndText == null)
                const SizedBox(height: 8),
              Center(
                child: MintYButton(
                  text: Text(
                    buttonText,
                    style: MintY.heading4White,
                  ),
                  color: MintY.currentColor,
                  onPressed: () {
                    onPressed?.call();
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class MintYGrid extends StatelessWidget {
  final List<Widget> children;
  final double padding;
  final double ratio;
  final double widgetSize;
  const MintYGrid(
      {super.key,
      required this.children,
      this.padding = 10.0,
      this.ratio = 350 / 150,
      this.widgetSize = 450});

  @override
  Widget build(BuildContext context) {
    List<Widget> childrenCopy = List.from(children);
    int columsCount =
        ((MediaQuery.of(context).size.width - (2 * padding)) / (widgetSize))
            .round();

    // Insert space Elements for last row, that the elements are something like centered
    if ((childrenCopy.length % columsCount) != 0) {
      int spacingCounts =
          ((columsCount - (childrenCopy.length % columsCount)) / 2).floor();
      for (int i = 0; i < spacingCounts; i++) {
        childrenCopy.insert(
            childrenCopy.length - childrenCopy.length % columsCount,
            Container());
      }
    }
    return Expanded(
      child: GridView.count(
        // mainAxisAlignment: MainAxisAlignment.center,
        padding: EdgeInsets.all(padding),
        crossAxisCount: columsCount,
        childAspectRatio: ratio,
        children: childrenCopy,
      ),
    );
  }
}

/// Icon on the left side, on the right side heading with description.
class MintYFeature extends StatelessWidget {
  final String heading;
  final String description;
  final Widget icon;
  const MintYFeature(
      {super.key,
      required this.heading,
      required this.description,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: icon,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                heading,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}

class MintYProgressIndicatorCircle extends StatelessWidget {
  const MintYProgressIndicatorCircle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: 80,
        width: 80,
        child: CircularProgressIndicator(color: MintY.currentColor),
      ),
    );
  }
}

/// data should be a 2D list of strings
/// First row are headings
class MintYTable extends StatelessWidget {
  final List<List<dynamic>> data;
  const MintYTable({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    List<TableRow> tableRows = [];
    for (int i = 0; i < data.length; i++) {
      List<TableCell> cells = [];
      for (int j = 0; j < data[i].length; j++) {
        cells.add(
          TableCell(
            child: Text(
              data[i][j].toString(),
              style: i == 0
                  ? Theme.of(context).textTheme.headlineMedium
                  : Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
      tableRows.add(
        TableRow(
          children: cells,
        ),
      );
    }
    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: tableRows,
    );
  }
}

/// As default text "Loading..." will be taken.
class MintYLoadingPage extends StatelessWidget {
  final String text;
  const MintYLoadingPage({super.key, this.text = ""});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              height: 80,
              width: 80,
              child: MintYProgressIndicatorCircle(),
            ),
            const SizedBox(
              height: 30,
            ),
            Text(
              text == "" ? AppLocalizations.of(context)!.loading : text,
              style: Theme.of(context).textTheme.headlineLarge,
            )
          ],
        ),
      ),
    );
  }
}

class MintYCheckboxSetting extends StatefulWidget {
  final String text;

  /// Initial value; the current one lives in the state.
  final bool value;

  /// Callback function that takes as parameter the new value of the setting
  final Function(bool) onChanged;

  const MintYCheckboxSetting(
      {super.key,
      required this.text,
      required this.value,
      required this.onChanged});

  @override
  State<MintYCheckboxSetting> createState() => _MintYCheckboxSettingState();
}

class _MintYCheckboxSettingState extends State<MintYCheckboxSetting> {
  late bool _value = widget.value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 100.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.text,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Checkbox(
            value: _value,
            onChanged: (bool? newValue) {
              setState(() {
                _value = newValue!;
              });
              widget.onChanged.call(newValue!);
            },
            activeColor: MintY.currentColor,
          ),
        ],
      ),
    );
  }
}

class MintYTextSetting extends StatefulWidget {
  final String text;
  final String value;
  final TextAlign textAlign;
  final Function(String) onChanged;

  const MintYTextSetting(
      {super.key,
      required this.text,
      required this.value,
      required this.textAlign,
      required this.onChanged});

  @override
  State<MintYTextSetting> createState() => _MintYTextSettingState();
}

class _MintYTextSettingState extends State<MintYTextSetting> {
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.value);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 100.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.text,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(
            width: 200,
            child: TextField(
              controller: controller,
              onChanged: (String newValue) {
                widget.onChanged.call(newValue);
              },
              textAlign: widget.textAlign,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: MintY.currentColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: MintY.currentColor,
                      width: 2,
                      style: BorderStyle.solid),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
