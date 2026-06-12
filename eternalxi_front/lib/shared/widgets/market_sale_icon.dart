import 'package:flutter/material.dart';

/// Icono de venta al mercado en historial de compras.
class MarketSaleIcon extends StatelessWidget {
  const MarketSaleIcon({super.key, this.size = 22});

  static const asset = 'assets/app/market_sale.png';

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
