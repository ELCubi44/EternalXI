import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/features/clash/cards/presentation/epic/clash_epic_assets.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Acceso a Historia sobre el banco del hub Inicio.
class ClashHomeStoryMapButton extends StatefulWidget {
  const ClashHomeStoryMapButton({super.key});

  @override
  State<ClashHomeStoryMapButton> createState() =>
      _ClashHomeStoryMapButtonState();
}

class _ClashHomeStoryMapButtonState extends State<ClashHomeStoryMapButton> {
  double _scale = 1;

  void _goStory() => context.push(AppRoutes.clashStory);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Semantics(
      button: true,
      label: l10n.clashHomeStory,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _scale = 0.96),
        onTapUp: (_) => setState(() => _scale = 1),
        onTapCancel: () => setState(() => _scale = 1),
        onTap: _goStory,
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: AspectRatio(
            aspectRatio: 900 / 431,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  ClashEpicAssets.clashStoryMapButton,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xE608101C),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: XiColors.classicGold.withValues(alpha: 0.6),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: XiColors.techCyan.withValues(alpha: 0.25),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        l10n.clashHomeStory,
                        style: const TextStyle(
                          fontFamily: 'Lumiare',
                          fontSize: 16,
                          color: XiColors.classicGold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
                // Cubre el texto bakeado del asset y pone el label localizado.
                Align(
                  alignment: const Alignment(0, 0.72),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xCC0A1220),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: XiColors.classicGold.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      l10n.clashHomeStory.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Lumiare',
                        fontSize: 13,
                        letterSpacing: 1.6,
                        color: XiColors.classicGold,
                        shadows: [
                          Shadow(
                            color: XiColors.techCyan.withValues(alpha: 0.45),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
