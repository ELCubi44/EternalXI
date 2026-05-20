import 'package:eternal_xi/core/utils/league_money_format.dart';
import 'package:eternal_xi/data/models/league_standing_row.dart';
import 'package:flutter/material.dart';

/// Tarjeta de clasificación: posición, nickname, puntos (protagonistas) y valor de equipo.
class LeagueStandingRowCard extends StatelessWidget {
  const LeagueStandingRowCard({
    super.key,
    required this.row,
    required this.isFirstPlace,
    required this.isCurrentUser,
    this.onPeerTap,
  });

  final LeagueStandingRow row;
  final bool isFirstPlace;
  final bool isCurrentUser;
  final VoidCallback? onPeerTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final firstDecoration = isFirstPlace
        ? BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.tertiaryContainer.withValues(alpha: 0.65),
                colorScheme.primaryContainer.withValues(alpha: 0.45),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colorScheme.tertiary.withValues(alpha: 0.45),
              width: 1.2,
            ),
          )
        : null;

    final userTint = isCurrentUser && !isFirstPlace
        ? BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.35),
            ),
          )
        : null;

    final decoration = firstDecoration ?? userTint;
    final ptsLabel = LeagueMoneyFormat.points(row.puntosTotales);
    final valorLabel = LeagueMoneyFormat.teamValue(row.valorTotalEquipo);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: decoration == null
            ? colorScheme.surfaceContainerHighest
            : Colors.transparent,
        elevation: 0,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPeerTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: decoration,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _UserBadge(
                    nickname: row.nickname,
                    imageUrl: row.resolvedFotoUsuarioUrl(),
                    isFirstPlace: isFirstPlace,
                    colorScheme: colorScheme,
                    theme: theme,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                row.nickname.isEmpty ? '—' : row.nickname,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                valorLabel,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          ptsLabel,
                          textAlign: TextAlign.end,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                            color: isFirstPlace
                                ? colorScheme.onTertiaryContainer
                                : colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UserBadge extends StatelessWidget {
  const _UserBadge({
    required this.nickname,
    required this.imageUrl,
    required this.isFirstPlace,
    required this.colorScheme,
    required this.theme,
  });

  final String nickname;
  final String? imageUrl;
  final bool isFirstPlace;
  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final initial = nickname.trim().isEmpty
        ? '?'
        : nickname.trim().substring(0, 1).toUpperCase();
    return SizedBox(
      width: 52,
      height: 52,
      child: ClipOval(
        child: imageUrl != null
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _AvatarFallback(
                  initial: initial,
                  colorScheme: colorScheme,
                  theme: theme,
                ),
              )
            : _AvatarFallback(
                initial: initial,
                colorScheme: colorScheme,
                theme: theme,
              ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({
    required this.initial,
    required this.colorScheme,
    required this.theme,
  });

  final String initial;
  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.primaryContainer.withValues(alpha: 0.8),
      ),
      child: Center(
        child: Text(
          initial,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}
