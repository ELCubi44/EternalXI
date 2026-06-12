import 'package:flutter/material.dart';

/// Icono de ruleta de entrenador (tienda e historial).
class CoachRouletteIcon extends StatelessWidget {
  const CoachRouletteIcon({super.key, this.size = 32});

  static const asset = 'assets/app/coach_roulette.png';

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
  }
}
