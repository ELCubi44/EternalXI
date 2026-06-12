import 'package:flutter/material.dart';

/// Icono de historial de alineación (campo + reloj).
class LineupHistoryIcon extends StatelessWidget {
  const LineupHistoryIcon({super.key, this.size = 28});

  static const asset = 'assets/app/lineup_history.png';

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
