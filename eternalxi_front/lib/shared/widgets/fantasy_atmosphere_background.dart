import 'package:flutter/material.dart';

/// Fondo atmosferico compartido del modo Fantasy (prueba con el estadio N).
class FantasyAtmosphereBackground extends StatelessWidget {
  const FantasyAtmosphereBackground({super.key});

  /// Misma imagen que el detalle de carta Clash rareza N.
  static const String assetPath =
      'assets/images/clash/epic/backgrounds/bg_detail_n.png';

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0xFF06101F)),
          Image.asset(
            assetPath,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.medium,
          ),
          // En claro, velo suave para que textos/cartas actuales sigan legibles.
          if (isLight)
            const ColoredBox(color: Color(0x55F4EFE3))
          else
            const ColoredBox(color: Color(0x33000000)),
        ],
      ),
    );
  }
}
