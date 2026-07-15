import 'package:flutter/material.dart';

/// Fondo atmosferico (estadio N) con tinte negro para la prueba de look oscuro.
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
          ColorFiltered(
            colorFilter: const ColorFilter.matrix(<double>[
              // Desatura y oscurece el azul del estadio hacia negro.
              0.22, 0.22, 0.22, 0, 0,
              0.22, 0.22, 0.22, 0, 0,
              0.22, 0.22, 0.22, 0, 0,
              0, 0, 0, 1, 0,
            ]),
            child: Image.asset(
              assetPath,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.medium,
            ),
          ),
          const ColoredBox(color: Color(0x99000000)),
        ],
      ),
    );
  }
}
