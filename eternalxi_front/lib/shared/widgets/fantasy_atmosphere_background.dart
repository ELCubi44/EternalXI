import 'package:flutter/material.dart';

/// Fondo atmosferico (estadio N) visible en toda la app.
class FantasyAtmosphereBackground extends StatelessWidget {
  const FantasyAtmosphereBackground({super.key});

  static const String assetPath =
      'assets/images/clash/epic/backgrounds/bg_detail_n.png';

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0xFF000000)),
          Image.asset(
            assetPath,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, __, ___) => const ColoredBox(
              color: Color(0xFF0A1020),
            ),
          ),
          // Velo suave: oscurece un poco sin matar el estadio.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66000000),
                  Color(0x33000000),
                  Color(0x88000000),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
