import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/features/clash/cards/presentation/epic/clash_epic_assets.dart';
import 'package:eternal_xi/features/clash/home/clash_home_hub_gates.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Acceso a Eventos (abajo-derecha). Puede quedar bloqueado por gate.
class ClashHomeEventsButton extends StatefulWidget {
  const ClashHomeEventsButton({super.key});

  @override
  State<ClashHomeEventsButton> createState() => _ClashHomeEventsButtonState();
}

class _ClashHomeEventsButtonState extends State<ClashHomeEventsButton> {
  double _scale = 1;

  bool get _unlocked => ClashHomeHubGates.eventsUnlocked;

  void _onTap() {
    if (!_unlocked) {
      final l10n = context.l10n;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.clashHomeEventsLocked),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    context.go(AppRoutes.clashEvents);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final unlocked = _unlocked;

    return Semantics(
      button: true,
      enabled: unlocked,
      label: unlocked
          ? l10n.clashHomeEvents
          : '${l10n.clashHomeEvents}. ${l10n.clashHomeEventsLocked}',
      child: GestureDetector(
        onTapDown: unlocked ? (_) => setState(() => _scale = 0.96) : null,
        onTapUp: (_) {
          setState(() => _scale = 1);
          _onTap();
        },
        onTapCancel: () => setState(() => _scale = 1),
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: AspectRatio(
            aspectRatio: 900 / 431,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (unlocked)
                  Image.asset(
                    ClashEpicAssets.clashEventsButton,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.high,
                    gaplessPlayback: true,
                    errorBuilder: (_, __, ___) => DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xE608101C),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: XiColors.classicGold.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                  )
                else
                  ColorFiltered(
                    colorFilter: const ColorFilter.matrix(<double>[
                      0.35, 0.45, 0.10, 0, 0,
                      0.35, 0.45, 0.10, 0, 0,
                      0.35, 0.45, 0.10, 0, 0,
                      0, 0, 0, 0.92, 0,
                    ]),
                    child: Image.asset(
                      ClashEpicAssets.clashEventsButton,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.high,
                      gaplessPlayback: true,
                      errorBuilder: (_, __, ___) => DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xE608101C),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: XiColors.steelGray.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                Align(
                  alignment: const Alignment(0, 0.72),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xCC0A1220),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: (unlocked
                                ? XiColors.classicGold
                                : XiColors.steelGray)
                            .withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      l10n.clashHomeEvents.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Lumiare',
                        fontSize: 12,
                        letterSpacing: 1.4,
                        color: unlocked
                            ? XiColors.classicGold
                            : XiColors.steelGray,
                      ),
                    ),
                  ),
                ),
                if (!unlocked)
                  const Align(
                    alignment: Alignment(0.78, -0.15),
                    child: Icon(
                      Icons.lock_rounded,
                      color: XiColors.classicGold,
                      size: 22,
                      shadows: [
                        Shadow(color: Colors.black87, blurRadius: 6),
                      ],
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
