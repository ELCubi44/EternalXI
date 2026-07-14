import 'package:eternal_xi/app/theme/xi_typography.dart';
import 'package:flutter/material.dart';

/// Texto de marca �Eternal XI� con el peso nativo de Lumiare (sin negrita falsa).
class XiBrandWordmark extends StatelessWidget {
  const XiBrandWordmark({
    super.key,
    this.uppercase = true,
    this.fontSize = 22,
    this.color,
    this.letterSpacing = 0.6,
    this.shadows,
    this.textAlign,
  });

  final bool uppercase;
  final double fontSize;
  final Color? color;
  final double letterSpacing;
  final List<Shadow>? shadows;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final label = uppercase ? 'ETERNAL XI' : 'Eternal XI';
    return Text(
      label,
      textAlign: textAlign,
      style: XiTypography.brandWordmark(
        color: color ?? DefaultTextStyle.of(context).style.color ?? Colors.white,
        fontSize: fontSize,
        letterSpacing: letterSpacing,
        shadows: shadows,
      ),
    );
  }
}
