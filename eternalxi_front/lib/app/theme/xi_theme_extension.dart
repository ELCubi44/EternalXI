import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Colores y superficies que respetan modo claro/oscuro en toda la app.
extension XiThemeExtension on BuildContext {
  bool get isXiDark => Theme.of(this).brightness == Brightness.dark;

  // ── Fondos base ───────────────────────────────────────────────────────────
  /// En oscuro es transparente para dejar ver el fondo atmosferico global.
  Color get xiBackground =>
      isXiDark ? Colors.transparent : XiColors.ivoryUniform;

  Color get xiCardSurface => isXiDark ? XiColors.navyBlue : XiColors.warmWhite;

  Color get xiCardElevated =>
      isXiDark ? XiColors.surfaceElevated : XiColors.warmWhite;

  Color get xiSurfaceContainer =>
      isXiDark ? XiColors.surfaceContainer : const Color(0xFFF0E6D2);

  Color get xiSurfaceInset =>
      isXiDark ? const Color(0xFF0E0E0E) : const Color(0xFFEDE4D0);

  Color get xiChipBackground =>
      isXiDark ? XiColors.navyBlue.withValues(alpha: 0.8) : XiColors.warmWhite;

  // ── Texto ─────────────────────────────────────────────────────────────────
  Color get xiTextPrimary =>
      isXiDark ? XiColors.warmWhite : XiColors.nightBlue;

  Color get xiTextSecondary => isXiDark
      ? XiColors.warmWhite.withValues(alpha: 0.72)
      : XiColors.steelGray;

  Color get xiHeaderTitle => isXiDark ? XiColors.warmWhite : XiColors.nightBlue;

  /// Texto de acento legible (evita azul clarito en labels).
  Color get xiAccentText =>
      isXiDark ? XiColors.warmWhite : XiColors.nightBlue;

  // ── Bordes y divisores ────────────────────────────────────────────────────
  Color get xiDivider =>
      isXiDark ? XiColors.divider : const Color(0xFFD8CEBC);

  Color get xiBorderSubtle => isXiDark
      ? XiColors.steelGray.withValues(alpha: 0.18)
      : XiColors.steelGray.withValues(alpha: 0.22);

  // ── Gradientes ──────────────────────────────────────────────────────────
  List<Color> get xiHeaderGradient => isXiDark
      ? [XiColors.navyBlue, XiColors.nightBlue]
      : [XiColors.warmWhite, XiColors.ivoryUniform];

  List<Color> get xiNavGradient => isXiDark
      ? [XiColors.surfaceElevated, XiColors.nightBlue]
      : [XiColors.warmWhite, const Color(0xFFF5EDD8)];

  List<Color> get xiCompactCardGradient => isXiDark
      ? [const Color(0xFF1A1A1A), const Color(0xFF0A0A0A)]
      : [XiColors.warmWhite, const Color(0xFFFFF3DC)];

  List<Color> get xiBudgetBarGradient => isXiDark
      ? [const Color(0xFF1A1A1A), XiColors.surfaceContainer]
      : [XiColors.warmWhite, const Color(0xFFFFF0D4)];

  List<Color> get xiStandingDefaultGradient => isXiDark
      ? [const Color(0xFF141414), const Color(0xFF0A0A0A)]
      : [XiColors.warmWhite, const Color(0xFFFFF6E8)];

  List<Color> get xiStandingGoldGradient => isXiDark
      ? [const Color(0xFF1E1A10), const Color(0xFF12100A)]
      : [const Color(0xFFFFF8E8), const Color(0xFFFFEEC8)];

  List<Color> get xiStandingSilverGradient => isXiDark
      ? [const Color(0xFF18191E), const Color(0xFF0F1014)]
      : [const Color(0xFFF4F6F8), const Color(0xFFE8ECF0)];

  List<Color> get xiStandingBronzeGradient => isXiDark
      ? [const Color(0xFF1A1208), const Color(0xFF100C06)]
      : [const Color(0xFFFFF4E8), const Color(0xFFFFE8D0)];

  List<Color> get xiStandingMeGradient => isXiDark
      ? [const Color(0xFF1C1C1C), const Color(0xFF0E0E0E)]
      : [const Color(0xFFEEF3FF), const Color(0xFFE0E9FF)];

  // ── Nav / iconos ──────────────────────────────────────────────────────────
  Color get xiNavSelected => XiColors.royalBlue;
  Color get xiNavUnselected =>
      isXiDark ? XiColors.warmWhite : XiColors.nightBlue;
  Color get xiNavBorder => isXiDark
      ? XiColors.royalBlue.withValues(alpha: 0.28)
      : XiColors.royalBlue.withValues(alpha: 0.15);

  // ── Chat ──────────────────────────────────────────────────────────────────
  Color get xiChatIncomingBubble =>
      isXiDark ? XiColors.navyBlue : XiColors.warmWhite;

  Color get xiChatInputFill =>
      isXiDark ? XiColors.surfaceContainer : const Color(0xFFF5EDD8);

  List<BoxShadow> get xiCardShadow => isXiDark
      ? [
          BoxShadow(
            color: XiColors.royalBlue.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ]
      : [
          BoxShadow(
            color: XiColors.royalBlue.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: XiColors.steelGray.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ];
}
