import 'package:flutter/material.dart';

/// Icono de sobre de recompensa (tienda e historial).
class PackEnvelopeIcon extends StatelessWidget {
  const PackEnvelopeIcon({super.key, this.size = 28});

  static const asset = 'assets/app/pack_envelope.png';

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
