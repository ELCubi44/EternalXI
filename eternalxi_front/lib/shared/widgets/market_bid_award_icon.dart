import 'package:flutter/material.dart';

/// Icono de adjudicación por puja en historial de mercado.
class MarketBidAwardIcon extends StatelessWidget {
  const MarketBidAwardIcon({super.key, this.size = 22});

  static const asset = 'assets/app/market_bid_award.png';

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
