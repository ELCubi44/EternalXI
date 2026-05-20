import 'package:eternal_xi/core/constants/api_constants.dart';
import 'package:eternal_xi/core/network/api_exception.dart';
import 'package:eternal_xi/data/models/league_participant_squad_payload.dart';
import 'package:eternal_xi/data/models/league_squad_player.dart';
import 'package:eternal_xi/data/services/leagues_api_service.dart';
import 'package:eternal_xi/features/leagues/navigation/league_inner_navigation.dart';
import 'package:eternal_xi/features/leagues/shell/league_shell_data.dart';
import 'package:eternal_xi/features/leagues/squad/league_squad_lineup_panel.dart';
import 'package:eternal_xi/features/leagues/squad/league_squad_position_bucket.dart';
import 'package:eternal_xi/features/leagues/widgets/league_squad_player_slot.dart';
import 'package:eternal_xi/features/leagues/widgets/league_squad_player_tile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Plantilla y pestaña «Alineación» desde `GET .../participants/{id}/squad` (última alineación en `alineacion`).
class LeagueParticipantSquadScreen extends StatefulWidget {
  const LeagueParticipantSquadScreen({
    super.key,
    required this.leagueId,
    required this.idUsuarioViewer,
    required this.idUsuarioTarget,
    required this.idLigaParticipante,
    required this.nickname,
    this.idJornadaForSquad,
  });

  final int leagueId;
  final int idUsuarioViewer;
  final int idUsuarioTarget;

  /// Si es 0, se resuelve con `GET .../participants`.
  final int idLigaParticipante;
  final String nickname;

  /// Hint opcional para perfiles al abrir jugadores desde plantilla (no filtra la respuesta de `/squad`).
  final int? idJornadaForSquad;

  @override
  State<LeagueParticipantSquadScreen> createState() =>
      _LeagueParticipantSquadScreenState();
}

class _LeagueParticipantSquadScreenState
    extends State<LeagueParticipantSquadScreen> {
  LeagueParticipantSquadPayload? _payload;
  int _lineupRevision = 0;
  bool _loading = true;
  String? _error;
  int _segment = 0;

  String _humanError(Object e) {
    if (e is ApiException) {
      return e.message;
    }
    return e.toString().replaceFirst('Exception: ', '');
  }

  @override
  void initState() {
    super.initState();
    if (widget.idUsuarioViewer == widget.idUsuarioTarget) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        final shell = LeagueShellData.maybeOf(context);
        shell?.selectTab(2);
        Navigator.of(context).maybePop();
      });
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<int> _resolveLigaParticipanteId(LeaguesApiService api) async {
    if (widget.idLigaParticipante > 0) {
      return widget.idLigaParticipante;
    }
    if (widget.idUsuarioTarget <= 0) {
      return 0;
    }
    final list = await api.getParticipants(
      idLiga: widget.leagueId,
      idUsuario: widget.idUsuarioViewer,
    );
    for (final p in list) {
      if (p.idUsuario == widget.idUsuarioTarget && p.idLigaParticipante > 0) {
        return p.idLigaParticipante;
      }
    }
    return 0;
  }

  Future<void> _debugParticipantLineupAudit({
    required int idLigaParticipante,
    required LeagueParticipantSquadPayload payload,
  }) async {
    if (!kDebugMode) {
      return;
    }
    final idLiga = widget.leagueId;
    final idSol = widget.idUsuarioViewer;
    final idPart = widget.idUsuarioTarget;
    final apiRoot = ApiConstants.baseUrl.endsWith('/')
        ? ApiConstants.baseUrl.substring(0, ApiConstants.baseUrl.length - 1)
        : ApiConstants.baseUrl;
    debugPrint(
      '[participant-lineup][load] idLiga=$idLiga '
      'idLigaParticipante=$idLigaParticipante '
      'idUsuarioSolicitante=$idSol idUsuarioParticipante=$idPart',
    );
    final squadPath =
        '$apiRoot${ApiConstants.leagues}/$idLiga/participants/$idLigaParticipante/squad?idUsuario=$idSol';
    debugPrint('[participant-lineup][squad-url] $squadPath');
    final al = payload.alineacion;
    debugPrint(
      '[participant-lineup][squad-response] '
      'alineacion.disponible=${al.disponible} '
      'idJornadaOrigen=${al.idJornadaOrigen} numeroJornadaOrigen=${al.numeroJornadaOrigen} '
      'titulares=${al.titulares.length} reservas=${al.reservas.length} '
      'emptySlots=${al.emptySlots.length}',
    );
    debugPrint(
      '[participant-lineup][note] lineup-history solo en pantalla Historial; '
      'esta pantalla no lo llama.',
    );
    final lu = payload.toEditableLineupOrNull();
    debugPrint(
      '[participant-lineup][editable-from-squad] '
      'toEditableLineupOrNull=${lu != null} '
      'emptySlots=${lu?.emptySlots.length ?? 0}',
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<LeaguesApiService>();
      final pid = await _resolveLigaParticipanteId(api);
      if (pid <= 0) {
        throw Exception(
          'No se encontró el participante en la liga (falta idLigaParticipante en el servidor o en clasificación).',
        );
      }
      final data = await api.getParticipantSquad(
        idLiga: widget.leagueId,
        idLigaParticipante: pid,
        idUsuario: widget.idUsuarioViewer,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _payload = data;
        _lineupRevision++;
        _loading = false;
      });
      await _debugParticipantLineupAudit(
        idLigaParticipante: pid,
        payload: data,
      );
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

  List<LeagueSquadPlayer> _squadMergedForLineup(LeagueParticipantSquadPayload p) {
    final map = <int, LeagueSquadPlayer>{
      for (final x in p.plantilla) x.idLigaJugador: x,
    };
    for (final x in [...p.alineacion.titulares, ...p.alineacion.reservas]) {
      if (x.idLigaJugador > 0) {
        map[x.idLigaJugador] = x;
      }
    }
    return map.values.toList();
  }

  int? _idJornadaParaPerfilLineupAjeno() {
    final p = _payload;
    if (p == null) {
      return null;
    }
    final id = p.alineacion.idJornadaOrigen;
    return id > 0 ? id : null;
  }

  Map<LeagueSquadLine, List<LeagueSquadPlayer>> _group(
    List<LeagueSquadPlayer> all,
  ) {
    final map = <LeagueSquadLine, List<LeagueSquadPlayer>>{
      for (final line in LeagueSquadPositionBucket.displayOrder) line: [],
    };
    for (final p in all) {
      final line = LeagueSquadPositionBucket.forPosition(p.posicion);
      map[line]!.add(p);
    }
    for (final line in LeagueSquadPositionBucket.displayOrder) {
      map[line]!.sort((a, b) => b.valor.compareTo(a.valor));
    }
    return map;
  }

  /// Perfil desde pestaña Plantilla: jornada de la última alineación guardada; hint solo si falta.
  int? _idJornadaParaPerfilPlantilla(LeagueParticipantSquadPayload p) {
    final id = p.alineacion.idJornadaOrigen;
    if (id > 0) {
      return id;
    }
    final hint = widget.idJornadaForSquad;
    return hint != null && hint > 0 ? hint : null;
  }

  List<Widget> _buildRosterSlivers(ThemeData theme, ColorScheme colorScheme) {
    final players = _payload!.plantilla;
    final grouped = _group(players);
    final slivers = <Widget>[];

    for (final line in LeagueSquadPositionBucket.displayOrder) {
      final list = grouped[line]!;
      if (list.isEmpty) {
        continue;
      }

      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Icon(
                  Icons.layers_outlined,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    LeagueSquadPositionBucket.sectionTitle(line),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${list.length}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          sliver: SliverList.separated(
            itemCount: list.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final player = list[index];
              return LeagueSquadPlayerSlot(
                player: player,
                child: LeagueSquadPlayerTile(
                  player: player,
                  onTap: () {
                    LeagueInnerNavigation.openPlayerProfile(
                      context: context,
                      player: player,
                      leagueId: widget.leagueId,
                      idLigaJugador: player.idLigaJugador,
                      idUsuario: widget.idUsuarioViewer,
                      idJornada: _idJornadaParaPerfilPlantilla(_payload!),
                      isOwnPlayerHint: false,
                      isMarketPlayerHint: false,
                    );
                  },
                ),
              );
            },
          ),
        ),
      );
    }

    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 24)));
    return slivers;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final nick = widget.nickname.trim().isEmpty
        ? 'Participante'
        : widget.nickname.trim();

    return Scaffold(
      appBar: AppBar(title: Text(nick)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : _error != null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  Icon(
                    Icons.cloud_off_outlined,
                    size: 48,
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(_error!, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 20),
                  FilledButton.tonalIcon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              )
            : _payload == null
            ? const SizedBox.shrink()
            : CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    sliver: SliverToBoxAdapter(
                      child: SegmentedButton<int>(
                        segments: const [
                          ButtonSegment<int>(
                            value: 0,
                            label: Text('Alineación'),
                            icon: Icon(Icons.grid_on_outlined),
                          ),
                          ButtonSegment<int>(
                            value: 1,
                            label: Text('Plantilla'),
                            icon: Icon(Icons.groups_2_outlined),
                          ),
                        ],
                        selected: {_segment},
                        onSelectionChanged: (s) {
                          setState(() => _segment = s.first);
                        },
                      ),
                    ),
                  ),
                  if (_segment == 0)
                    SliverToBoxAdapter(
                      child: _buildLineupSection(theme, colorScheme),
                    )
                  else ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          'Jugadores de $nick en esta liga, agrupados por demarcación.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    ..._buildRosterSlivers(theme, colorScheme),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildLineupSection(ThemeData theme, ColorScheme colorScheme) {
    final p = _payload!;
    final al = p.alineacion;

    if (!al.disponible) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
        child: Column(
          children: [
            Icon(
              Icons.sports_soccer_outlined,
              size: 52,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Este participante todavía no tiene una alineación guardada',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Cuando guarde una alineación en una jornada, podrás verla aquí.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final lu = p.toEditableLineupOrNull();
    if (lu == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 14),
            Text(
              'No se pudo mostrar la alineación.',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final squad = _squadMergedForLineup(p);
    final jNum = al.numeroJornadaOrigen;
    final bannerText = jNum > 0
        ? 'Última alineación guardada · Jornada $jNum'
        : 'Última alineación guardada';
    final jBanner = Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Text(
        bannerText,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        jBanner,
        LeagueSquadLineupPanel(
          squad: squad,
          lineup: lu,
          lineupRevision: _lineupRevision,
          idLiga: widget.leagueId,
          idUsuario: widget.idUsuarioViewer,
          entrenadorAsignado: lu.entrenadorAsignado,
          entrenadorActivo:
              lu.entrenadorActivo || lu.entrenadorAsignado != null,
          formacionEfectiva: lu.formacionEfectiva,
          coachToggleLoading: false,
          onCoachSelectionChanged: null,
          readOnly: true,
          onHistoryTap: () {
            LeagueInnerNavigation.openParticipantLineupHistory(
              context: context,
              idLiga: widget.leagueId,
              idLigaParticipante: p.idLigaParticipante,
              idUsuarioSolicitante: widget.idUsuarioViewer,
              idUsuarioParticipante: p.idUsuarioParticipante,
              nickname: p.nickname,
            );
          },
          onReadOnlyPlayerTap: (player) {
            LeagueInnerNavigation.openPlayerProfile(
              context: context,
              player: player,
              leagueId: widget.leagueId,
              idLigaJugador: player.idLigaJugador,
              idUsuario: widget.idUsuarioViewer,
              idJornada: _idJornadaParaPerfilLineupAjeno(),
              isOwnPlayerHint: false,
              isMarketPlayerHint: false,
            );
          },
          onLineupReloaded: () async {},
        ),
      ],
    );
  }
}
