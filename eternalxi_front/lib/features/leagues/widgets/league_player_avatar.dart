import 'package:eternal_xi/data/models/league_squad_player.dart';
import 'package:eternal_xi/features/leagues/utils/league_player_photo.dart';
import 'package:flutter/material.dart';

/// Avatar de jugador: foto desde asset por id; si falla la red, placeholder elegante.
class LeaguePlayerAvatar extends StatelessWidget {
  const LeaguePlayerAvatar({
    super.key,
    required this.player,
    this.size = 48,
    this.circular = false,
  });

  final LeagueSquadPlayer player;
  final double size;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final uri = LeaguePlayerPhoto.resolve(player);

    final placeholder = _PhotoPlaceholder(
      size: size,
      circular: circular,
      colorScheme: colorScheme,
    );

    if (uri == null) {
      return placeholder;
    }

    final imgAlignment = circular ? Alignment.center : Alignment.topCenter;

    final img = Image.network(
      uri.toString(),
      width: size,
      height: size,
      fit: BoxFit.cover,
      alignment: imgAlignment,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return SizedBox(
          width: size,
          height: size,
          child: Center(
            child: SizedBox(
              width: size * 0.4,
              height: size * 0.4,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            ),
          ),
        );
      },
      errorBuilder: (_, _, _) => placeholder,
    );

    if (circular) {
      return ClipOval(child: img);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: img,
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({
    required this.size,
    required this.circular,
    required this.colorScheme,
  });

  final double size;
  final bool circular;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      shape: circular ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: circular ? null : BorderRadius.circular(size * 0.22),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          colorScheme.surfaceContainerHigh,
          colorScheme.surfaceContainerHighest,
        ],
      ),
      border: Border.all(
        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
      ),
    );

    return Container(
      width: size,
      height: size,
      decoration: decoration,
      alignment: Alignment.center,
      child: Icon(
        Icons.person_outline_rounded,
        size: size * 0.52,
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
      ),
    );
  }
}
