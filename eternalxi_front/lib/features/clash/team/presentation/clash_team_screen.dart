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
            fontSize: 17,
            height: 1.15,
          ),
          onTap: () => context.push(AppRoutes.clashCards),
        ),
      ],
    );
  }
}

/// Icono un poco mayor que la barra; la barra empieza bajo el icono.
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

  static const double _iconSize = 58;
  static const double _barHeight = 48;
  static const double _iconOverlap = 22;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: _iconSize + 4,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              Positioned(
                left: _iconOverlap,
                right: 0,
                top: (_iconSize + 4 - _barHeight) / 2,
                height: _barHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    image: const DecorationImage(
                      image: AssetImage(ClashEpicAssets.teamPersonajesBarBg),
                      fit: BoxFit.fill,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(left: _iconSize - _iconOverlap + 8),
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
                ),
              ),
              Positioned(
                left: 0,
                top: 2,
                child: Container(
                  width: _iconSize,
                  height: _iconSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: XiColors.classicGold.withValues(alpha: 0.65),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 8,
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
            ],
          ),
        ),
      ),
    );
  }
}
