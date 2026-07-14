import 'package:eternal_xi/core/utils/league_coach_photo.dart';
import 'package:eternal_xi/data/models/league_coach_assignment.dart';
import 'package:flutter/material.dart';

/// Cabecera compacta: entrenador asignado, estado activo, formación efectiva y bonus informativo.
class LeagueCoachSummaryCard extends StatelessWidget {
  const LeagueCoachSummaryCard({
    super.key,
    required this.entrenadorActivo,
    required this.formacionEfectiva,
    this.coach,
    this.coachToggleLoading = false,
    this.onCoachActiveChanged,
  });

  final LeagueCoachAssignment? coach;
  final bool entrenadorActivo;
  final String formacionEfectiva;
  final bool coachToggleLoading;
  final ValueChanged<bool>? onCoachActiveChanged;

  String _displayName(LeagueCoachAssignment c) {
    final pila = c.entrenadorPila?.trim() ?? '';
    if (pila.isNotEmpty) {
      return pila;
    }
    final nombre = c.entrenadorNombre?.trim() ?? '';
    return nombre.isEmpty ? 'Entrenador' : nombre;
  }

  String _subtitleName(LeagueCoachAssignment c) {
    final nombre = c.entrenadorNombre?.trim() ?? '';
    final pila = c.entrenadorPila?.trim() ?? '';
    if (nombre.isEmpty) {
      return '';
    }
    if (pila.isEmpty || nombre == pila) {
      return '';
    }
    return nombre;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final formacion =
        formacionEfectiva.trim().isEmpty ? '4-3-3' : formacionEfectiva.trim();

    final coachNonNull = coach;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: coachNonNull == null
            ? _EmptyCoachBody(theme: theme, colorScheme: colorScheme)
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CoachAvatar(
                    url: LeagueCoachPhoto.resolveUrl(
                      idEntrenador: coachNonNull.idEntrenador,
                      foto: coachNonNull.foto,
                    ),
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.sports_soccer_outlined,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _displayName(coachNonNull),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (_subtitleName(coachNonNull).isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            _subtitleName(coachNonNull),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _StatusChip(
                              active: entrenadorActivo,
                              colorScheme: colorScheme,
                              theme: theme,
                            ),
                            _FormationChip(
                              label: formacion,
                              colorScheme: colorScheme,
                              theme: theme,
                            ),
                          ],
                        ),
                        if ((coachNonNull.equipoNombre ?? '').trim().isNotEmpty ||
                            coachNonNull.bonusPuntos != 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            _bonusLine(coachNonNull),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.25,
                            ),
                          ),
                        ],
                        if (onCoachActiveChanged != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Usar entrenador',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    ),
                                ),
                              ),
                              if (coachToggleLoading)
                                Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                              Switch.adaptive(
                                value: entrenadorActivo,
                                onChanged: coachToggleLoading
                                    ? null
                                    : onCoachActiveChanged,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _bonusLine(LeagueCoachAssignment c) {
    final equipo = (c.equipoNombre ?? '').trim();
    final bonus = c.bonusPuntos;
    if (equipo.isEmpty) {
      return 'Bonus informativo: +$bonus por jugador';
    }
    return 'Bonus equipo: $equipo · +$bonus por jugador';
  }
}

class _EmptyCoachBody extends StatelessWidget {
  const _EmptyCoachBody({
    required this.theme,
    required this.colorScheme,
  });

  final ThemeData theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.surfaceContainerHighest,
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.person_outline_rounded,
            size: 22,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sin entrenador asignado',
                style: theme.textTheme.titleSmall?.copyWith(
                  ),
              ),
              const SizedBox(height: 6),
              Text(
                'Formación base 4-3-3',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CoachAvatar extends StatelessWidget {
  const _CoachAvatar({
    required this.url,
    required this.colorScheme,
  });

  final String? url;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    const size = 44.0;
    if (url == null || url!.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.secondaryContainer.withValues(alpha: 0.65),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.tune_rounded,
          size: 24,
          color: colorScheme.onSecondaryContainer,
        ),
      );
    }
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          url!,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            color: colorScheme.secondaryContainer.withValues(alpha: 0.65),
            alignment: Alignment.center,
            child: Icon(
              Icons.tune_rounded,
              size: 24,
              color: colorScheme.onSecondaryContainer,
            ),
          ),
          loadingBuilder: (context, child, progress) {
            if (progress == null) {
              return child;
            }
            return ColoredBox(
              color: colorScheme.surfaceContainerHighest,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.active,
    required this.colorScheme,
    required this.theme,
  });

  final bool active;
  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final bg = active
        ? colorScheme.primaryContainer.withValues(alpha: 0.65)
        : colorScheme.surfaceContainerHighest;
    final fg = active
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;
    final border = active
        ? colorScheme.primary.withValues(alpha: 0.35)
        : colorScheme.outlineVariant.withValues(alpha: 0.55);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        active ? 'Activo' : 'Inactivo',
        style: theme.textTheme.labelSmall?.copyWith(
          color: fg,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _FormationChip extends StatelessWidget {
  const _FormationChip({
    required this.label,
    required this.colorScheme,
    required this.theme,
  });

  final String label;
  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.grid_view_rounded,
            size: 13,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
