import 'package:flutter/material.dart';

/// Icono de tarjeta roja (cronología y estadísticas).
class RedCardIcon extends StatelessWidget {
  const RedCardIcon({super.key, this.size = 22});

  static const asset = 'assets/app/red_card.png';

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
