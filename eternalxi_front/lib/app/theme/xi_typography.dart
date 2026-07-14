import 'package:flutter/material.dart';

/// Tipograf�a de marca Eternal XI.
///
/// Lumiare solo incluye Regular (400). Cualquier otro peso provoca trazos
/// fantasma dentro de los glifos (p. ej. la �b� de un nickname).
abstract final class XiTypography {
  static const family = 'Lumiare';
  static const weight = FontWeight.w400;

  /// Fuerza Lumiare Regular; ignora pesos solicitados.
  static TextStyle enforce(TextStyle style) {
    final usesLumiare =
        style.fontFamily == null || style.fontFamily == family;
    if (!usesLumiare) {
      return style;
    }
    return style.copyWith(
      fontFamily: family,
      fontWeight: weight,
      fontVariations: const <FontVariation>[],
    );
  }

  static TextStyle? enforceNullable(TextStyle? style) =>
      style == null ? null : enforce(style);

  static TextTheme sanitizeTextTheme(TextTheme theme) {
    TextStyle? s(TextStyle? style) => enforceNullable(style);
    return TextTheme(
      displayLarge: s(theme.displayLarge),
      displayMedium: s(theme.displayMedium),
      displaySmall: s(theme.displaySmall),
      headlineLarge: s(theme.headlineLarge),
      headlineMedium: s(theme.headlineMedium),
      headlineSmall: s(theme.headlineSmall),
      titleLarge: s(theme.titleLarge),
      titleMedium: s(theme.titleMedium),
      titleSmall: s(theme.titleSmall),
      bodyLarge: s(theme.bodyLarge),
      bodyMedium: s(theme.bodyMedium),
      bodySmall: s(theme.bodySmall),
      labelLarge: s(theme.labelLarge),
      labelMedium: s(theme.labelMedium),
      labelSmall: s(theme.labelSmall),
    );
  }

  static ThemeData sanitizeTheme(ThemeData theme) {
    return theme.copyWith(
      textTheme: sanitizeTextTheme(theme.textTheme),
      primaryTextTheme: sanitizeTextTheme(theme.primaryTextTheme),
      appBarTheme: theme.appBarTheme.copyWith(
        titleTextStyle: enforceNullable(theme.appBarTheme.titleTextStyle),
        toolbarTextStyle: enforceNullable(theme.appBarTheme.toolbarTextStyle),
      ),
      dialogTheme: theme.dialogTheme.copyWith(
        titleTextStyle: enforceNullable(theme.dialogTheme.titleTextStyle),
        contentTextStyle: enforceNullable(theme.dialogTheme.contentTextStyle),
      ),
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        hintStyle: enforceNullable(theme.inputDecorationTheme.hintStyle),
        labelStyle: enforceNullable(theme.inputDecorationTheme.labelStyle),
        floatingLabelStyle:
            enforceNullable(theme.inputDecorationTheme.floatingLabelStyle),
        helperStyle: enforceNullable(theme.inputDecorationTheme.helperStyle),
        errorStyle: enforceNullable(theme.inputDecorationTheme.errorStyle),
      ),
      chipTheme: theme.chipTheme.copyWith(
        labelStyle: enforceNullable(theme.chipTheme.labelStyle),
        secondaryLabelStyle:
            enforceNullable(theme.chipTheme.secondaryLabelStyle),
      ),
      tabBarTheme: theme.tabBarTheme.copyWith(
        labelStyle: enforceNullable(theme.tabBarTheme.labelStyle),
        unselectedLabelStyle:
            enforceNullable(theme.tabBarTheme.unselectedLabelStyle),
      ),
    );
  }

  static TextStyle lumiare({
    double? fontSize,
    Color? color,
    double? letterSpacing,
    double? height,
    List<Shadow>? shadows,
    TextDecoration? decoration,
  }) {
    return enforce(
      TextStyle(
        fontFamily: family,
        fontWeight: weight,
        fontSize: fontSize,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
        shadows: shadows,
        decoration: decoration,
      ),
    );
  }

  static TextStyle brandWordmark({
    required Color color,
    double fontSize = 22,
    double letterSpacing = 0.6,
    List<Shadow>? shadows,
  }) =>
      lumiare(
        fontSize: fontSize,
        color: color,
        letterSpacing: letterSpacing,
        height: 1.05,
        shadows: shadows,
      );

  static TextStyle sectionEyebrow({
    required Color color,
    double fontSize = 10,
    double letterSpacing = 2.2,
  }) =>
      lumiare(
        fontSize: fontSize,
        color: color,
        letterSpacing: letterSpacing,
        height: 1.2,
      );

  static TextStyle emphasis(
    TextStyle base, {
    double fontSizeDelta = 0,
    double letterSpacingDelta = 0.4,
    Color? color,
  }) =>
      enforce(base).copyWith(
        fontSize: (base.fontSize ?? 14) + fontSizeDelta,
        letterSpacing: (base.letterSpacing ?? 0) + letterSpacingDelta,
        color: color ?? base.color,
        fontWeight: weight,
      );
}

extension XiLumiareTextStyle on TextStyle {
  TextStyle get lumiareNative => XiTypography.enforce(this);
}

/// Envuelve la app para sanear tipograf�a heredada del [Theme].
class XiTypographyScope extends StatelessWidget {
  const XiTypographyScope({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: XiTypography.sanitizeTheme(theme),
      child: DefaultTextStyle(
        style: XiTypography.enforce(
          theme.textTheme.bodyMedium ?? const TextStyle(),
        ),
        child: child,
      ),
    );
  }
}

/// Texto de marca. Usar en lugar de [Text] con Lumiare suelto.
class XiText extends StatelessWidget {
  const XiText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
  });

  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;

  @override
  Widget build(BuildContext context) {
    final merged = DefaultTextStyle.of(context).style.merge(style);
    return Text(
      data,
      style: XiTypography.enforce(merged),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );
  }
}

/// Sustituto global de [Text] que sanea Lumiare en cada render.
class SafeText extends StatelessWidget {
  const SafeText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.textDirection,
    this.locale,
    this.semanticsLabel,
  });

  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final TextDirection? textDirection;
  final Locale? locale;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final merged = DefaultTextStyle.of(context).style.merge(style);
    return Text(
      data,
      style: XiTypography.enforce(merged),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      textDirection: textDirection,
      locale: locale,
      semanticsLabel: semanticsLabel,
    );
  }
}
