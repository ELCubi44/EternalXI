import 'package:flutter/material.dart';

/// Icono de monedas (valor de mercado / dinero en liga).
class MoneyCoinsIcon extends StatelessWidget {
  const MoneyCoinsIcon({super.key, this.size = 16});

  static const asset = 'assets/app/money_coins.png';

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
