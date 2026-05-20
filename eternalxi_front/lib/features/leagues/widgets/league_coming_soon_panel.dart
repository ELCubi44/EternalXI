import 'package:flutter/material.dart';

/// Placeholder M3 reutilizable para secciones aún no implementadas.
class LeagueComingSoonPanel extends StatelessWidget {
  const LeagueComingSoonPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.accentColor,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = accentColor ?? colorScheme.primary;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withValues(alpha: 0.18),
                      colorScheme.tertiary.withValues(alpha: 0.12),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Icon(icon, size: 48, color: accent),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
