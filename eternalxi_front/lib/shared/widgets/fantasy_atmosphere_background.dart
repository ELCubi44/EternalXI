import 'package:flutter/material.dart';

/// Fondo atmosferico (estadio N) para Fantasy, selector de modo y perfil.
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
              color: Color(0xFF0A0A0A),
            ),
          ),
          // Velo ligero: el estadio se lee bien detrás de la UI.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x40000000),
                  Color(0x22000000),
                  Color(0x55000000),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Envuelve una pantalla con el estadio N detrás (Fantasy / modo / perfil).
class WithFantasyAtmosphere extends StatelessWidget {
  const WithFantasyAtmosphere({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const FantasyAtmosphereBackground(),
        child,
      ],
    );
  }
}
