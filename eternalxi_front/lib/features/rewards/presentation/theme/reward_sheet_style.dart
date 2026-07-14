import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:flutter/material.dart';

/// Colores de hojas modales de cartas (detalle / canje) según tema global.
class RewardSheetStyle {
  RewardSheetStyle._(this._context);

  factory RewardSheetStyle.of(BuildContext context) =>
      RewardSheetStyle._(context);

  final BuildContext _context;

  bool get _dark => _context.isXiDark;

  Color get sheetBackground => _context.xiCardSurface;
  Color get cardBackground => _context.xiSurfaceInset;
  Color get cardBlocked =>
      _dark ? const Color(0xFF151A28) : const Color(0xFFE0D6C4);
  Color get title => _context.xiTextPrimary;
  Color get body =>
      _dark ? Colors.white.withValues(alpha: 0.92) : XiColors.nightBlue.withValues(alpha: 0.9);
  Color get subtitle => _dark ? Colors.white70 : XiColors.steelGray;
  Color get muted => _dark ? Colors.white54 : XiColors.steelGray.withValues(alpha: 0.88);
  Color get faint => _dark ? Colors.white38 : XiColors.steelGray.withValues(alpha: 0.62);
  Color get veryFaint => _dark ? Colors.white30 : XiColors.steelGray.withValues(alpha: 0.45);
  Color get border => _context.xiBorderSubtle;
  Color get chipFill =>
      _dark ? Colors.white.withValues(alpha: 0.08) : XiColors.steelGray.withValues(alpha: 0.12);
  Color get avatarBackground =>
      _dark ? const Color(0xFF1A2233) : const Color(0xFFE8DFCC);
  Color get badgeIcon =>
      _dark ? Colors.white24 : XiColors.steelGray.withValues(alpha: 0.4);
  Color get effectChipBg =>
      _dark ? Colors.white.withValues(alpha: 0.08) : XiColors.steelGray.withValues(alpha: 0.1);
  Color get disabledBg =>
      _dark ? Colors.white.withValues(alpha: 0.05) : XiColors.steelGray.withValues(alpha: 0.08);
  Color get accentLabel => XiColors.classicGold;
  Color get info => _dark ? const Color(0xFF81D4FA) : XiColors.royalBlue;
  Color get warning => _dark ? const Color(0xFFFFAB91) : const Color(0xFFE65100);
  Color get success => _dark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
  Color get availableDot => success;

  TextStyle titleStyle(TextTheme theme, {double? size}) =>
      (theme.titleMedium ?? const TextStyle()).copyWith(
        color: title,
        fontSize: size,
      );

  TextStyle playerNameStyle() => TextStyle(
        color: title,
        fontSize: 13,
        height: 1.15,
      );

  TextStyle metaStyle() => TextStyle(color: muted, fontSize: 10, height: 1.2);

  TextStyle chipTextStyle() =>
      TextStyle(color: subtitle, fontSize: 9);
}

ThemeData rewardSheetTheme(BuildContext context) {
  final base = Theme.of(context);
  final style = RewardSheetStyle.of(context);
  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      surface: style.sheetBackground,
      onSurface: style.title,
      onSurfaceVariant: style.subtitle,
      surfaceContainerHighest: style.cardBackground,
    ),
    cardTheme: CardThemeData(
      color: style.cardBackground,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: style.border),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: style.sheetBackground,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: style.title,
        fontSize: 20,
      ),
      contentTextStyle: TextStyle(color: style.subtitle, height: 1.4),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: XiColors.classicGold,
        foregroundColor: XiColors.nightBlue,
        textStyle: const TextStyle(fontWeight: FontWeight.w400),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: XiColors.royalBlue),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: XiColors.royalBlue,
    ),
    iconTheme: IconThemeData(color: style.subtitle),
    textTheme: base.textTheme.copyWith(
      titleLarge: base.textTheme.titleLarge?.copyWith(
        color: style.title,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        color: style.title,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(color: style.body),
      bodySmall: base.textTheme.bodySmall?.copyWith(color: style.muted),
      labelLarge: base.textTheme.labelLarge?.copyWith(color: style.subtitle),
      labelSmall: base.textTheme.labelSmall?.copyWith(color: style.faint),
    ),
  );
}
