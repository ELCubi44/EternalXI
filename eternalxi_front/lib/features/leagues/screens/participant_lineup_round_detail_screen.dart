import 'package:eternal_xi/core/network/api_exception.dart';
import 'package:eternal_xi/data/models/league_participant_lineup_history.dart';
import 'package:eternal_xi/data/services/leagues_api_service.dart';
import 'package:eternal_xi/features/leagues/utils/league_saves_stat_visibility.dart';
import 'package:eternal_xi/features/leagues/utils/league_spanish_datetime.dart';
import 'package:eternal_xi/features/leagues/widgets/league_participant_lineup_round_pitch.dart';
import 'package:eternal_xi/features/leagues/widgets/league_player_avatar.dart';
import 'package:eternal_xi/features/leagues/widgets/league_round_fantasy_substitution_badge.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ParticipantLineupRoundDetailScreen extends StatefulWidget {
  const ParticipantLineupRoundDetailScreen({
    super.key,
    required this.idLiga,
    required this.idLigaParticipante,
    required this.idUsuarioSolicitante,
    required this.idJornada,
    this.idUsuarioParticipante,
    this.nickname,
  });

  final int idLiga;
  final int idLigaParticipante;
  final int idUsuarioSolicitante;
  final int idJornada;
  final int? idUsuarioParticipante;
  final String? nickname;

  @override
  State<ParticipantLineupRoundDetailScreen> createState() =>
      _ParticipantLineupRoundDetailScreenState();
}

class _ParticipantLineupRoundDetailScreenState
    extends State<ParticipantLineupRoundDetailScreen> {
  bool _loading = true;
  String? _error;
  LeagueParticipantLineupRoundDetail? _data;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  String _humanError(Object e) {
    if (e is ApiException) {
      return e.message;
    }
    return e.toString().replaceFirst('Exception: ', '');
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<LeaguesApiService>();
      final detail = await api.getParticipantLineupRoundDetail(
        idLiga: widget.idLiga,
        idLigaParticipante: widget.idLigaParticipante,
        idJornada: widget.idJornada,
        idUsuario: widget.idUsuarioSolicitante,
        fallbackParticipantUserId: widget.idUsuarioParticipante,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _data = detail;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _humanError(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de alineación')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 140),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : _error != null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 52,
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No se pudo cargar la jornada',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(_error!, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reintentar'),
                  ),
                ],
              )
            : _data == null
            ? const SizedBox.shrink()
            : _DetailBody(data: _data!, fallbackNickname: widget.nickname),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.data, required this.fallbackNickname});

  final LeagueParticipantLineupRoundDetail data;
  final String? fallbackNickname;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final nick = data.nickname.trim().isNotEmpty
        ? data.nickname.trim()
        : (fallbackNickname?.trim().isNotEmpty ?? false)
        ? fallbackNickname!.trim()
        : 'Participante';
    final status = data.estadoJornada.toUpperCase();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
      children: [
        Text(
          nick,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _MetaChip(label: 'Jornada ${data.numeroJornada}', icon: Icons.event),
            _MetaChip(label: status, icon: Icons.flag_circle_outlined),
            _MetaChip(
              label:
                  '${data.puntosTotales.toStringAsFixed(data.puntosTotales % 1 == 0 ? 0 : 1)} pts',
              icon: Icons.star_rounded,
            ),
          ],
        ),
        if (data.inicioJornada != null) ...[
          const SizedBox(height: 8),
          Text(
            '${LeagueSpanishDateTime.formatDateLong(data.inicioJornada)} · ${LeagueSpanishDateTime.formatTimeHm(data.inicioJornada)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (_hasOptionalPointsBreakdown(data)) ...[
          const SizedBox(height: 12),
          _OptionalPointsBreakdownCard(data: data),
        ],
        const SizedBox(height: 14),
        LeagueParticipantLineupRoundPitch(
          titulares: data.titulares,
          idCapitan: data.idCapitan,
          formacionEfectiva: data.formacionEfectiva,
          emptySlots: data.emptySlots,
          showJornadaPitchBadges: data.shouldShowJornadaPitchBadges,
          entrenadorAsignado: data.entrenadorAsignado,
        ),
        const SizedBox(height: 16),
        Text(
          'Titulares',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        for (final p in data.titulares) ...[
          _LineupRoundPlayerStatsCard(
            player: p,
            showJornadaPitchBadges: data.shouldShowJornadaPitchBadges,
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),
        Text(
          'Reservas',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (data.reservas.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                'No hay reservas en esta alineación.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          for (final p in data.reservas) ...[
            _LineupRoundPlayerStatsCard(
              player: p,
              showJornadaPitchBadges: data.shouldShowJornadaPitchBadges,
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

bool _hasOptionalPointsBreakdown(LeagueParticipantLineupRoundDetail data) {
  return data.puntosJugadoresFormacion != null ||
      data.penalizacionHuecosFantasy != null ||
      data.puntosEntrenadorFantasy != null;
}

String _fmtBreakdownDouble(double v) =>
    v.toStringAsFixed(v % 1 == 0 ? 0 : 1);

class _OptionalPointsBreakdownCard extends StatelessWidget {
  const _OptionalPointsBreakdownCard({required this.data});

  final LeagueParticipantLineupRoundDetail data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lines = <Widget>[];
    final pj = data.puntosJugadoresFormacion;
    if (pj != null) {
      lines.add(
        Text(
          'Puntos jugadores (formación): ${_fmtBreakdownDouble(pj)}',
          style: theme.textTheme.bodySmall,
        ),
      );
    }
    final pen = data.penalizacionHuecosFantasy;
    if (pen != null) {
      lines.add(
        Text(
          'Penalización huecos fantasy: ${_fmtBreakdownDouble(pen)}',
          style: theme.textTheme.bodySmall,
        ),
      );
    }
    final pe = data.puntosEntrenadorFantasy;
    if (pe != null) {
      lines.add(
        Text(
          'Puntos entrenador (fantasy): ${_fmtBreakdownDouble(pe)}',
          style: theme.textTheme.bodySmall,
        ),
      );
    }
    if (lines.isEmpty) {
      return const SizedBox.shrink();
    }
    final bodyChildren = <Widget>[
      Text(
        'Desglose (referencia del servidor)',
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 8),
    ];
    for (var i = 0; i < lines.length; i++) {
      if (i > 0) {
        bodyChildren.add(const SizedBox(height: 4));
      }
      bodyChildren.add(lines[i]);
    }
    return Card(
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: bodyChildren,
        ),
      ),
    );
  }
}

class _LineupRoundPlayerStatsCard extends StatelessWidget {
  const _LineupRoundPlayerStatsCard({
    required this.player,
    required this.showJornadaPitchBadges,
  });

  final LeagueParticipantLineupRoundPlayer player;
  final bool showJornadaPitchBadges;

  String _formatNote(double value) {
    if (value <= 0) {
      return '0';
    }
    return value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
  }

  String _boolLabel(bool value) => value ? 'Sí' : 'No';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final listBadge =
        leagueRoundPlayerListBadgeLabel(player, showJornadaPitchBadges);
    final fantasySubMsg = !showJornadaPitchBadges
        ? null
        : player.fantasyTitularSinConteoPorBanquillo
        ? 'Titular sin puntos fantasy en esta jornada: cuentan los del '
              'suplente de tu banquillo.'
        : player.fantasyBanquilloContandoPorSuplencia
        ? 'Puntos del banquillo que sí cuentan en el fantasy por sustituir '
              'al titular.'
        : null;
    if (kDebugMode) {
      debugPrint(
        '[lineup-history-detail][render] idLigaJugador=${player.idLigaJugador} posicion=${player.posicion} golesEncajados=${player.golesEncajados} impact=0',
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    LeaguePlayerAvatar(
                      player: player.toSquadPlayer(),
                      size: 42,
                      circular: true,
                    ),
                    if (fantasySubMsg != null)
                      Positioned(
                        right: -5,
                        top: -6,
                        child: LeagueRoundFantasySubstitutionBadge(
                          message: fantasySubMsg,
                          iconSize: 13,
                          padding: const EdgeInsets.all(2.5),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    player.nombreMostrado.trim().isNotEmpty
                        ? player.nombreMostrado
                        : player.nombre,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (listBadge.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      listBadge,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _StatChip(label: 'Minutos', value: '${player.minutosJugados}'),
                _StatChip(label: 'Goles', value: '${player.goles}'),
                _StatChip(label: 'Asistencias', value: '${player.asistencias}'),
                _StatChip(
                  label: 'Tarjetas amarillas',
                  value: '${player.tarjetasAmarillas}',
                ),
                _StatChip(label: 'Tarjetas rojas', value: '${player.tarjetasRojas}'),
                _StatChip(
                  label: 'Nota del periódico',
                  value: _formatNote(player.notaPeriodico),
                ),
                _StatChip(
                  label: 'Goles encajados',
                  value: '${player.golesEncajados}',
                ),
                _StatChip(
                  label: 'Portería a cero',
                  value: _boolLabel(player.porteriaCero),
                ),
                _StatChip(
                  label: 'Lesionado en partido',
                  value: _boolLabel(player.lesionadoEnPartido),
                ),
                if (leagueShouldShowSavesStat(player.posicion, player.paradas))
                  _StatChip(
                    label: 'Paradas',
                    value: leagueParadasStatDisplayValue(
                      player.paradas,
                      officialPoints: player.puntosFantasyParadasOficial,
                    ),
                  ),
                _StatChip(label: 'Regates', value: '${player.regates}'),
                _StatChip(
                  label: 'Balones recuperados',
                  value: '${player.balonesRecuperados}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurface,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
