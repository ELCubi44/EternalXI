import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/data/models/league_season_wrap.dart';
import 'package:eternal_xi/data/services/leagues_api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LeagueSeasonWrapOverlay {
  LeagueSeasonWrapOverlay._();

  static Future<void> showIfNeeded(
    BuildContext context, {
    required int idLiga,
    required int idUsuario,
  }) async {
    try {
      final wrap = await context.read<LeaguesApiService>().getSeasonWrap(
        idLiga: idLiga,
        idUsuario: idUsuario,
      );
      if (!context.mounted || !wrap.mostrarCinematica || !wrap.temporadaCompleta) {
        return;
      }
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _LeagueSeasonWrapDialog(
          wrap: wrap,
          idLiga: idLiga,
          idUsuario: idUsuario,
        ),
      );
    } catch (_) {
      // Sin bloquear la entrada a la liga si falla el resumen.
    }
  }
}

class _LeagueSeasonWrapDialog extends StatefulWidget {
  const _LeagueSeasonWrapDialog({
    required this.wrap,
    required this.idLiga,
    required this.idUsuario,
  });

  final LeagueSeasonWrap wrap;
  final int idLiga;
  final int idUsuario;

  @override
  State<_LeagueSeasonWrapDialog> createState() => _LeagueSeasonWrapDialogState();
}

class _LeagueSeasonWrapDialogState extends State<_LeagueSeasonWrapDialog> {
  final _pageCtrl = PageController();
  int _page = 0;

  List<_WrapStep> get _steps {
    final w = widget.wrap;
    final steps = <_WrapStep>[
      _WrapStep(
        title: 'Temporada finalizada',
        subtitle: w.nombreLiga,
        body:
            'Has quedado en la posicion ${w.posicion} de ${w.totalParticipantes} con ${w.puntosEfectivos} puntos.',
        icon: Icons.emoji_events_rounded,
      ),
    ];
    if (w.maxPuntos != null) {
      steps.add(_WrapStep.fromPlayer(
        title: 'Tu MVP',
        body: 'Este jugador te ha dado mas puntos esta temporada.',
        player: w.maxPuntos!,
        suffix: ' pts',
      ));
    }
    if (w.maxGoleador != null) {
      steps.add(_WrapStep.fromPlayer(
        title: 'Goleador de tu equipo',
        body: 'El que mas goles te ha marcado.',
        player: w.maxGoleador!,
        suffix: ' goles',
      ));
    }
    if (w.maxAsistente != null) {
      steps.add(_WrapStep.fromPlayer(
        title: 'Rey de las asistencias',
        body: 'El que mas asistencias te ha dado.',
        player: w.maxAsistente!,
        suffix: ' asist.',
      ));
    }
    return steps;
  }

  Future<void> _close() async {
    try {
      await context.read<LeaguesApiService>().markSeasonWrapSeen(
        idLiga: widget.idLiga,
        idUsuario: widget.idUsuario,
      );
    } catch (_) {}
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps;
    final isLast = _page >= steps.length - 1;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      backgroundColor: context.xiBackground,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.72,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  XiColors.royalBlue.withValues(alpha: 0.18),
                  XiColors.classicGold.withValues(alpha: 0.12),
                  context.xiBackground,
                ],
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageCtrl,
                    itemCount: steps.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, index) => _WrapStepView(step: steps[index]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            steps.length,
                            (i) => Container(
                              width: i == _page ? 18 : 7,
                              height: 7,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: i == _page
                                    ? XiColors.royalBlue
                                    : XiColors.royalBlue.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                      ),
                      FilledButton(
                        onPressed: () async {
                          if (isLast) {
                            await _close();
                          } else {
                            await _pageCtrl.nextPage(
                              duration: const Duration(milliseconds: 320),
                              curve: Curves.easeOutCubic,
                            );
                          }
                        },
                        child: Text(isLast ? 'Continuar' : 'Siguiente'),
                      ),
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

class _WrapStep {
  const _WrapStep({
    required this.title,
    required this.subtitle,
    required this.body,
    required this.icon,
    this.playerName,
    this.playerPhoto,
    this.statLine,
  });

  final String title;
  final String subtitle;
  final String body;
  final IconData icon;
  final String? playerName;
  final String? playerPhoto;
  final String? statLine;

  factory _WrapStep.fromPlayer({
    required String title,
    required String body,
    required LeagueSeasonWrapPlayer player,
    required String suffix,
  }) {
    return _WrapStep(
      title: title,
      subtitle: player.nombreMostrado,
      body: body,
      icon: Icons.sports_soccer_rounded,
      playerName: player.nombreMostrado,
      playerPhoto: player.photoUrl,
      statLine: '${player.valor}$suffix',
    );
  }
}

class _WrapStepView extends StatelessWidget {
  const _WrapStepView({required this.step});

  final _WrapStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (step.playerPhoto != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                step.playerPhoto!,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _iconBadge(step.icon),
              ),
            )
          else
            _iconBadge(step.icon),
          const SizedBox(height: 22),
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: context.xiTextPrimary,
            ),
          ),
          if (step.subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              step.subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: XiColors.classicGold,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            step.body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: context.xiTextSecondary,
              height: 1.45,
            ),
          ),
          if (step.statLine != null) ...[
            const SizedBox(height: 16),
            Text(
              step.statLine!,
              style: theme.textTheme.displaySmall?.copyWith(
                color: XiColors.royalBlue,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _iconBadge(IconData icon) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: XiColors.royalBlue.withValues(alpha: 0.14),
        border: Border.all(color: XiColors.classicGold.withValues(alpha: 0.45)),
      ),
      child: Icon(icon, size: 44, color: XiColors.royalBlue),
    );
  }
}
