import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/presentation/epic/clash_epic_assets.dart';
import 'package:eternal_xi/features/clash/presentation/widgets/clash_section_tile.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ClashTeamScreen extends StatelessWidget {
  const ClashTeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return ClashScreenScaffold(
      title: l10n.clashTabTeam,
      children: [
        _TeamSectionBar(
          iconAsset: ClashEpicAssets.teamPersonajesIcon,
          title: l10n.clashTeamCharacters,
          titleStyle: theme.textTheme.titleMedium?.copyWith(
            color: context.xiTextPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 16,
            height: 1.0,
          ),
          onTap: () => context.push(AppRoutes.clashCards),
        ),
      ],
    );
  }
}

/// Barra compacta; el círculo queda más grande y sobresale por arriba/abajo.
class _TeamSectionBar extends StatelessWidget {
  const _TeamSectionBar({
    required this.iconAsset,
    required this.title,
    required this.onTap,
    this.titleStyle,
  });

  final String iconAsset;
  final String title;
  final VoidCallback onTap;
  final TextStyle? titleStyle;

  static const double _barHeight = 42;
  static const double _iconSize = 58;
  /// Empieza bajo el icono para ocultar el borde vertical del hueco.
  static const double _barLeftInset = 22;

  @override
  Widget build(BuildContext context) {
    final rowHeight = _iconSize;
    final barTop = (rowHeight - _barHeight) / 2;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: rowHeight,
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              Positioned(
                left: _barLeftInset,
                right: 0,
                top: barTop,
                height: _barHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    ClashEpicAssets.teamPersonajesBarBg,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.high,
                    alignment: const Alignment(-0.15, 0),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  width: _iconSize,
                  height: _iconSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: XiColors.classicGold.withValues(alpha: 0.7),
                      width: 1.6,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    iconAsset,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ),
              Positioned(
                left: _iconSize + 8,
                right: 16,
                top: barTop,
                height: _barHeight,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
