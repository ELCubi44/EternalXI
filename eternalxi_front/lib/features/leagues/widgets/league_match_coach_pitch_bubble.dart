import 'package:eternal_xi/app/localization/league_l10n.dart';
import 'package:eternal_xi/core/utils/league_coach_photo.dart';
import 'package:eternal_xi/data/models/league_coach_assignment.dart';
import 'package:eternal_xi/features/leagues/widgets/league_team_logo.dart';
import 'package:flutter/material.dart';

Uri? _coachAssignmentUri(LeagueCoachAssignment coach) {
  final s = LeagueCoachPhoto.resolveUrl(
    idEntrenador: coach.idEntrenador,
    foto: coach.foto,
  );
  if (s == null || s.isEmpty) {
    return null;
  }
  return Uri.tryParse(s);
}

/// Entrenador del equipo real en la vista de partido (solo informativo).
///
/// Por defecto no abre ningún panel: no es gestión fantasy ni selector de míster.
class LeagueMatchCoachPitchBubble extends StatelessWidget {
  const LeagueMatchCoachPitchBubble({
    super.key,
    required this.coach,
    required this.teamFormationLabel,
    required this.teamNameDisplay,
    required this.teamId,
    this.enableDetailOnTap = false,
  });

  final LeagueCoachAssignment coach;
  final String teamFormationLabel;
  final String teamNameDisplay;
  final int teamId;

  /// Si es true, al pulsar se muestra la ficha resumen (formación + equipo). En alineación
  /// de partido debe ser false: solo decorativo.
  final bool enableDetailOnTap;

  String get _shortLabel {
    final pila = coach.entrenadorPila?.trim() ?? '';
    if (pila.isNotEmpty) {
      return pila.length > 10 ? '${pila.substring(0, 9)}…' : pila;
    }
    final nombre = coach.entrenadorNombre?.trim() ?? '';
    if (nombre.isEmpty) {
      return '';
    }
    final first = nombre.split(RegExp(r'\s+')).first;
    return first.length > 10 ? '${first.substring(0, 9)}…' : first;
  }

  void _openDetail(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final uri = _coachAssignmentUri(coach);
    final fullName = coach.entrenadorNombre?.trim().isNotEmpty == true
        ? coach.entrenadorNombre!.trim()
        : (coach.entrenadorPila?.trim() ??
            context.leagueL10n.coachLabel);
    final pila = coach.entrenadorPila?.trim() ?? '';
    final equipo = coach.equipoNombre?.trim().isNotEmpty == true
        ? coach.equipoNombre!.trim()
        : teamNameDisplay.trim();

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ctx.leagueL10n.coachLabel,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CoachFace(uri: uri, size: 56),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (pila.isNotEmpty && pila != fullName) ...[
                            const SizedBox(height: 4),
                            Text(
                              pila,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _chip(
                                theme,
                                colorScheme,
                                Icons.grid_view_rounded,
                                teamFormationLabel.trim().isEmpty
                                    ? '—'
                                    : teamFormationLabel.trim(),
                              ),
                              if (equipo.isNotEmpty)
                                _chip(
                                  theme,
                                  colorScheme,
                                  Icons.shield_outlined,
                                  equipo,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _chip(
    ThemeData theme,
    ColorScheme colorScheme,
    IconData icon,
    String text,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubbleVisual(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final uri = _coachAssignmentUri(coach);
    final label = _shortLabel;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.92),
                    width: 2.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primaryContainer.withValues(alpha: 0.35),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Center(child: _CoachFace(uri: uri, size: 44)),
                      if (teamId > 0)
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: LeagueTeamLogo(
                            idEquipo: teamId,
                            size: 22,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!enableDetailOnTap) {
      return _buildBubbleVisual(context);
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openDetail(context),
        borderRadius: BorderRadius.circular(16),
        child: _buildBubbleVisual(context),
      ),
    );
  }
}

class _CoachFace extends StatelessWidget {
  const _CoachFace({required this.uri, required this.size});

  final Uri? uri;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (uri == null) {
      return SizedBox(
        width: size,
        height: size,
        child: Icon(
          Icons.sports_soccer_rounded,
          size: size * 0.45,
          color: colorScheme.primary,
        ),
      );
    }
    final img = ClipOval(
      child: Image.network(
        uri!.toString(),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Icon(
          Icons.sports_soccer_rounded,
          size: size * 0.45,
          color: colorScheme.primary,
        ),
      ),
    );
    return SizedBox(width: size, height: size, child: img);
  }
}
