import 'package:flutter/material.dart';

/// Icono de compra directa en historial de mercado.
class MarketDirectBuyIcon extends StatelessWidget {
  const MarketDirectBuyIcon({super.key, this.size = 22});

  static const asset = 'assets/app/market_direct_buy.png';

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
