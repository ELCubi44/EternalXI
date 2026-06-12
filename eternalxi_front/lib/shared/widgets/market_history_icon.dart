import 'package:flutter/material.dart';

/// Icono de historial de mercado (barra de presupuesto).
class MarketHistoryIcon extends StatelessWidget {
  const MarketHistoryIcon({super.key, this.size = 28});

  static const asset = 'assets/app/market_history.png';

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
