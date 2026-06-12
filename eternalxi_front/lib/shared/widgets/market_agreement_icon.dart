import 'package:flutter/material.dart';

/// Icono de acuerdo entre usuarios en historial del mercado.
class MarketAgreementIcon extends StatelessWidget {
  const MarketAgreementIcon({super.key, this.size = 22});

  static const asset = 'assets/app/market_agreement.png';

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
