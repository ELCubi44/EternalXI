import 'package:eternal_xi/core/utils/league_asset_urls.dart';
import 'package:eternal_xi/core/utils/league_coach_photo.dart';
import 'package:eternal_xi/features/rewards/data/models/reward_coach_item.dart';
import 'package:eternal_xi/features/rewards/utils/reward_formatters.dart';
import 'package:flutter/material.dart';

String coachBonusExplanation(RewardCoachItem coach) {
  final bonus = coach.bonusPuntos > 0 ? coach.bonusPuntos : 3;
  final team = (coach.nombreEquipo ?? '').trim();
  if (team.isEmpty) {
    return 'Si lo activas y alineas jugadores de su equipo con minutos, '
        'recibes +$bonus pts por cada uno en tu once.';
  }
  return 'Si lo activas y alineas jugadores de $team con minutos, '
      'recibes +$bonus pts por cada uno en tu once.';
}

String coachBonusShortLine(RewardCoachItem coach) {
  final bonus = coach.bonusPuntos > 0 ? coach.bonusPuntos : 3;
  final team = (coach.nombreEquipo ?? '').trim();
  if (team.isEmpty) {
    return '+$bonus pts por jugador de su equipo alineado';
  }
  return '+$bonus pts por jugador de $team alineado';
}

class RewardCoachDetailCard extends StatelessWidget {
  const RewardCoachDetailCard({
    super.key,
    required this.coach,
    this.onDarkGradient = true,
  });

  final RewardCoachItem coach;
  final bool onDarkGradient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photoUrl = LeagueCoachPhoto.resolveUrl(
      idEntrenador: coach.idEntrenador,
      foto: coach.foto,
    );
    final hasTeam = coach.idEquipo != null && coach.idEquipo! > 0;
    final teamBadgeUrl = hasTeam
        ? LeagueAssetUrls.teamBadge(coach.idEquipo!).toString()
        : null;
    final teamName = (coach.nombreEquipo ?? '').trim();
    final panelColor = onDarkGradient
        ? Colors.black.withValues(alpha: 0.22)
        : const Color(0xFF1A2233);
    final panelBorder = onDarkGradient
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.08);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: panelColor,
        border: Border.all(color: panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CoachPhotoAvatar(url: photoUrl, initials: coach.initials),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coach.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (teamName.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (teamBadgeUrl != null)
                            _TeamBadge(url: teamBadgeUrl),
                          if (teamBadgeUrl != null) const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              teamName,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFFFD54F).withValues(alpha: 0.12),
              border: Border.all(
                color: const Color(0xFFFFD54F).withValues(alpha: 0.28),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.bolt_rounded,
                  size: 20,
                  color: const Color(0xFFFFD54F).withValues(alpha: 0.95),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    coachBonusExplanation(coach),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachPhotoAvatar extends StatelessWidget {
  const _CoachPhotoAvatar({required this.url, required this.initials});

  final String? url;
  final String initials;

  @override
  Widget build(BuildContext context) {
    const size = 56.0;
    if (url == null || url!.isEmpty) {
      return _InitialsAvatar(size: size, initials: initials);
    }
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          url!,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              _InitialsAvatar(size: size, initials: initials),
        ),
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.size, required this.initials});

  final double size;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.32,
        ),
      ),
    );
  }
}

class _TeamBadge extends StatelessWidget {
  const _TeamBadge({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 24,
        height: 24,
        child: Image.network(
          url,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class CoachRouletteInfoButton extends StatelessWidget {
  const CoachRouletteInfoButton({
    super.key,
    required this.costePuntos,
  });

  final int costePuntos;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.1),
      shape: const CircleBorder(side: BorderSide(color: Colors.white24)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showCoachRouletteInfoSheet(
          context,
          costePuntos: costePuntos,
        ),
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(
            Icons.info_outline_rounded,
            color: Colors.white70,
            size: 20,
          ),
        ),
      ),
    );
  }
}

Future<void> showCoachRouletteInfoSheet(
  BuildContext context, {
  required int costePuntos,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF0E121C),
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final bottom = MediaQuery.paddingOf(ctx).bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ruleta de entrenador',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            _InfoBlock(
              title: 'Una sola tirada',
              body:
                  'Solo puedes girar la ruleta una vez por liga. Obtendrás un entrenador libre al azar.',
            ),
            const SizedBox(height: 12),
            _InfoBlock(
              title: 'Coste',
              body: costePuntos > 0
                  ? 'Girar cuesta ${formatRewardPoints(costePuntos)}.'
                  : 'Girar no tiene coste en puntos.',
            ),
            const SizedBox(height: 12),
            _InfoBlock(
              title: 'Bonus por alineación',
              body: 'Cada entrenador otorga puntos extra por jugador de su club '
                  'que alinees en tu once y que juegue minutos. El bonus concreto '
                  'depende del entrenador que consigas (p. ej. +3 pts por jugador). '
                  'Actívalo desde Alineación para aplicarlo en la jornada.',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Cerrar'),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> showCoachWonSheet({
  required BuildContext context,
  required RewardCoachItem coach,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF0E121C),
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final bottom = MediaQuery.paddingOf(ctx).bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¡Entrenador conseguido!',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            RewardCoachDetailCard(coach: coach, onDarkGradient: false),
            const SizedBox(height: 12),
            Text(
              'Equípalo y actívalo desde Alineación para sumar el bonus en cada jornada.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white54,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Continuar'),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF1A2233),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white70,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
