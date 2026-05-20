import 'package:flutter/material.dart';

/// Marca visual de sustitución fantasy (titular sin conteo / banquillo que sí cuenta).
class LeagueRoundFantasySubstitutionBadge extends StatelessWidget {
  const LeagueRoundFantasySubstitutionBadge({
    super.key,
    required this.message,
    this.iconSize = 14,
    this.padding = const EdgeInsets.all(3),
  });

  final String message;
  final double iconSize;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: message,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          shape: BoxShape.circle,
          border: Border.all(
            color: colorScheme.onSecondaryContainer.withValues(alpha: 0.35),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x38000000),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: padding,
          child: Icon(
            Icons.swap_horiz_rounded,
            size: iconSize,
            color: colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}
