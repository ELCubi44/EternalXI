import 'package:eternal_xi/app/localization/league_l10n.dart';
import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'dart:async';

import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/core/network/api_exception.dart';
import 'package:eternal_xi/data/models/league_coach_assignment.dart';
import 'package:eternal_xi/data/models/league_editable_lineup.dart';
import 'package:eternal_xi/data/models/league_squad_player.dart';
import 'package:eternal_xi/data/models/league_squad_response.dart';
import 'package:eternal_xi/data/services/leagues_api_service.dart';
import 'package:eternal_xi/features/leagues/navigation/league_inner_navigation.dart';
import 'package:eternal_xi/features/leagues/utils/league_nav_refresh.dart';
import 'package:eternal_xi/features/leagues/shell/league_shell_data.dart';
import 'package:eternal_xi/features/leagues/shell/league_shell_tabs.dart';
import 'package:eternal_xi/features/leagues/squad/league_squad_lineup_panel.dart';
import 'package:eternal_xi/features/leagues/squad/league_squad_position_bucket.dart';
import 'package:eternal_xi/features/leagues/widgets/league_squad_player_slot.dart';
import 'package:eternal_xi/features/leagues/widgets/league_squad_player_tile.dart';
import 'package:eternal_xi/shared/widgets/lineup_history_icon.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LeagueTabSquad extends StatefulWidget {
  const LeagueTabSquad({super.key});

  static final ValueNotifier<int?> externalSegmentRequest = ValueNotifier<int?>(
    null,
  );

  @override
  State<LeagueTabSquad> createState() => _LeagueTabSquadState();
}

class _LeagueTabSquadState extends State<LeagueTabSquad>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<LeagueSquadPlayer>? _players;
  LeagueSquadResponse? _squadResponse;
  LeagueEditableLineup? _lineup;
  String? _lineupError;
  int _lineupRevision = 0;

  bool _loading = true;
  String? _error;
  bool _coachToggleLoading = false;
  bool _implicitLineupDirty = false;
  bool _lineupPanelReportsUnsaved = false;
  final GlobalKey<LeagueSquadLineupPanelState> _lineupPanelKey =
      GlobalKey<LeagueSquadLineupPanelState>();
  bool? _pendingCoachActive;
  int? _pendingCoachId;

  /// Objeto del picker (inventario); [_availableCoaches] del squad no incluye esa lista.
  LeagueCoachAssignment? _pendingCoachSnapshot;

  int _segment = 0;
  Object? _lastShellDetailRef;
  int? _handledRefreshGeneration;
  int? _lastSquadTabIndex;
  bool _hasLoadedAtLeastOnce = false;
  bool _loadScheduled = false;
  LeagueShellData? _registeredShell;

  void _handleExternalSegmentRequest() {
    final request = LeagueTabSquad.externalSegmentRequest.value;
    if (!mounted || request == null) {
      return;
    }
    LeagueTabSquad.externalSegmentRequest.value = null;
    if (request < 0 || request > 1) {
      return;
    }
    if (_segment != request) {
      setState(() => _segment = request);
    }
  }

  @override
  void initState() {
    super.initState();
    LeagueTabSquad.externalSegmentRequest.addListener(
      _handleExternalSegmentRequest,
    );
  }

  String _humanError(Object e) {
    if (e is ApiException) {
      return e.message;
    }
    return e.toString().replaceFirst('Exception: ', '');
  }

  void _starterProbLogLineupJornada(LeagueEditableLineup lu) {
    if (!kDebugMode) {
      return;
    }
    debugPrint(
      '[starter-prob][lineup-editable] idJornada=${lu.idJornada} numeroJornada=${lu.numeroJornada}',
    );
  }

  /// Misma línea en _load / recargas para correlacionar con [starter-prob][squad-url].
  void _starterProbLogSquadLoad(LeagueShellData shell, int? idJornadaSquad) {
    if (!kDebugMode) {
      return;
    }
    debugPrint(
      '[starter-prob][squad-load] idLiga=${shell.leagueId} idUsuario=${shell.idUsuario} idJornada=$idJornadaSquad',
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _handleExternalSegmentRequest();
    final shell = LeagueShellData.maybeOf(context);
    if (shell != null && !identical(shell, _registeredShell)) {
      _registeredShell?.registerLineupLeaveGuard(null);
      _registeredShell = shell;
      shell.registerLineupLeaveGuard(_confirmLeaveLineupEditor);
    }
    final detailRef = shell?.detail;
    final detailChanged = !identical(_lastShellDetailRef, detailRef);
    _lastShellDetailRef = detailRef;
    final gen = shell?.refreshGeneration;
    final refreshChanged = gen != null &&
        _handledRefreshGeneration != null &&
        gen != _handledRefreshGeneration;
    if (gen != null) {
      _handledRefreshGeneration = gen;
    }
    final tabIndex = shell?.currentTabIndex;
    final squadTabActivated =
        tabIndex == LeagueShellTabs.squad &&
        _lastSquadTabIndex != null &&
        _lastSquadTabIndex != LeagueShellTabs.squad;
    _lastSquadTabIndex = tabIndex;
    if (!_hasLoadedAtLeastOnce ||
        detailChanged ||
        refreshChanged ||
        squadTabActivated) {
      _hasLoadedAtLeastOnce = true;
      _scheduleLoad();
    }
  }

  void _scheduleLoad() {
    if (_loadScheduled) {
      return;
    }
    _loadScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _loadScheduled = false;
      if (!mounted) {
        return;
      }
      await _load();
    });
  }

  @override
  void dispose() {
    _registeredShell?.registerLineupLeaveGuard(null);
    LeagueTabSquad.externalSegmentRequest.removeListener(
      _handleExternalSegmentRequest,
    );
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) {
      return;
    }
    final shell = LeagueShellData.maybeOf(context);
    if (shell == null) {
      setState(() {
        _loading = false;
        _error = context.leagueL10n.couldNotLoadLeagueContext;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = context.read<LeaguesApiService>();

      LeagueEditableLineup? lu;
      String? lineupErr;
      try {
        lu = await api.getEditableLineup(
          idLiga: shell.leagueId,
          idUsuario: shell.idUsuario,
        );
        lineupErr = null;
      } catch (e) {
        lu = null;
        lineupErr = _humanError(e);
      }

      final idJornadaSquad = (lu != null && lu.idJornada > 0)
          ? lu.idJornada
          : null;

      if (lu != null) {
        _starterProbLogLineupJornada(lu);
      }
      _starterProbLogSquadLoad(shell, idJornadaSquad);

      LeagueSquadResponse? squadResponse;
      late List<LeagueSquadPlayer> players;
      try {
        squadResponse = await api.getSquadResponse(
          idLiga: shell.leagueId,
          idUsuario: shell.idUsuario,
          idJornada: idJornadaSquad,
        );
        players = squadResponse.plantilla;
      } catch (_) {
        squadResponse = null;
        players = await api.getSquad(
          idLiga: shell.leagueId,
          idUsuario: shell.idUsuario,
          idJornada: idJornadaSquad,
        );
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _players = players;
        _squadResponse = squadResponse;
        _lineup = lu;
        _lineupError = lineupErr;
        _lineupRevision++;
        _pendingCoachActive = null;
        _pendingCoachId = null;
        _pendingCoachSnapshot = null;
        _loading = false;
        _implicitLineupDirty = false;
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

  Future<void> _reloadSquadAndLineupAfterCoachToggle() async {
    final shell = LeagueShellData.maybeOf(context);
    if (shell == null) {
      return;
    }
    final api = context.read<LeaguesApiService>();
    try {
      final lu = await api.getEditableLineup(
        idLiga: shell.leagueId,
        idUsuario: shell.idUsuario,
      );
      _starterProbLogLineupJornada(lu);
      final idJ = lu.idJornada > 0 ? lu.idJornada : null;
      _starterProbLogSquadLoad(shell, idJ);
      LeagueSquadResponse? squadResponse;
      late List<LeagueSquadPlayer> players;
      try {
        squadResponse = await api.getSquadResponse(
          idLiga: shell.leagueId,
          idUsuario: shell.idUsuario,
          idJornada: idJ,
        );
        players = squadResponse.plantilla;
      } catch (_) {
        squadResponse = null;
        players = await api.getSquad(
          idLiga: shell.leagueId,
          idUsuario: shell.idUsuario,
          idJornada: idJ,
        );
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _players = players;
        _squadResponse = squadResponse;
        _lineup = lu;
        _lineupError = null;
        _lineupRevision++;
        _pendingCoachActive = null;
        _pendingCoachId = null;
        _pendingCoachSnapshot = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_humanError(e))));
    }
  }

  bool get _coachDirty {
    final pendingActive = _pendingCoachActive;
    final pendingCoachId = _pendingCoachId;
    final originalActive = _entrenadorActivoForSummary();
    final originalCoachId = _coachForSummary()?.idEntrenador;
    final activeDirty =
        pendingActive != null && pendingActive != originalActive;
    final coachDirty =
        pendingCoachId != null && pendingCoachId != originalCoachId;
    return activeDirty || coachDirty;
  }

  bool _entrenadorActivoVisual() {
    return _pendingCoachActive ?? _entrenadorActivoForSummary();
  }

  List<LeagueCoachAssignment> _availableCoaches() {
    final fromResponse = _squadResponse?.entrenadoresDisponibles ?? const [];
    final fromLineup = _lineup?.entrenadoresDisponibles ?? const [];
    final assigned = _coachForSummary();
    final map = <int, LeagueCoachAssignment>{};
    for (final c in [...fromResponse, ...fromLineup]) {
      final id = c.idEntrenador;
      if (id != null && id > 0) {
        map[id] = c;
      }
    }
    if (assigned != null) {
      final id = assigned.idEntrenador;
      if (id != null && id > 0) {
        map[id] = assigned;
      }
    }
    return map.values.toList(growable: false);
  }

  LeagueCoachAssignment? _selectedCoachVisual() {
    final pendingActive = _pendingCoachActive;
    if (pendingActive != null) {
      if (!pendingActive) {
        return null;
      }
      final pendingId = _pendingCoachId;
      if (pendingId != null && pendingId > 0) {
        final snap = _pendingCoachSnapshot;
        if (snap != null && snap.idEntrenador == pendingId) {
          return snap;
        }
        for (final c in _availableCoaches()) {
          if (c.idEntrenador == pendingId) {
            return c;
          }
        }
        return snap;
      }
    }
    return _coachForSummary();
  }

  String _formacionEfectivaVisual() {
    final active = _entrenadorActivoVisual();
    if (active) {
      final coachFormation = _selectedCoachVisual()?.formacion?.trim() ?? '';
      if (coachFormation.isNotEmpty) {
        return coachFormation;
      }
    }
    // Transición a "sin entrenador": la UI usa 4-3-3 hasta que GET lineup devuelva formacionEfectiva.
    if (_pendingCoachActive == false) {
      return '4-3-3';
    }
    return _formacionEfectivaForSummary();
  }

  void _onCoachSelectionChanged(bool active, LeagueCoachAssignment? coach) {
    if (!active) {
      if (!_entrenadorActivoForSummary()) {
        return;
      }
      setState(() {
        _pendingCoachActive = false;
        _pendingCoachId = null;
        _pendingCoachSnapshot = null;
        _implicitLineupDirty = false;
      });
      unawaited(_applyNoCoachSelection());
      return;
    }
    final newCoachId = coach?.idEntrenador;
    setState(() {
      _pendingCoachActive = true;
      _pendingCoachId = newCoachId;
      _pendingCoachSnapshot = coach;
      _implicitLineupDirty = false;
    });
    unawaited(_applyCoachSelection(coach));
  }

  Future<void> _applyCoachSelection(LeagueCoachAssignment? coach) async {
    final shell = LeagueShellData.maybeOf(context);
    if (shell == null) {
      return;
    }
    setState(() => _coachToggleLoading = true);
    try {
      final api = context.read<LeaguesApiService>();
      final idLp = await _resolveOwnLigaParticipanteId(
        api: api,
        leagueId: shell.leagueId,
        idUsuario: shell.idUsuario,
      );
      if (!mounted) {
        return;
      }
      if (idLp <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.leagueL10n.couldNotResolveParticipant)),
        );
        return;
      }
      await api.setCoachActive(
        idLiga: shell.leagueId,
        idLigaParticipante: idLp,
        idUsuarioSolicitante: shell.idUsuario,
        activo: true,
        idEntrenador: coach?.idEntrenador,
      );
      if (!mounted) {
        return;
      }
      await _reloadSquadAndLineupAfterCoachToggle();
      _lineupPanelKey.currentState?.markCoachLayoutApplied();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_humanError(e))));
      }
    } finally {
      if (mounted) {
        setState(() => _coachToggleLoading = false);
      }
    }
  }

  Future<void> _applyNoCoachSelection() async {
    final shell = LeagueShellData.maybeOf(context);
    if (shell == null) {
      return;
    }
    setState(() => _coachToggleLoading = true);
    try {
      final api = context.read<LeaguesApiService>();
      final idLp = await _resolveOwnLigaParticipanteId(
        api: api,
        leagueId: shell.leagueId,
        idUsuario: shell.idUsuario,
      );
      if (!mounted) {
        return;
      }
      if (idLp <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.leagueL10n.couldNotResolveParticipant)),
        );
        return;
      }
      await api.setCoachActive(
        idLiga: shell.leagueId,
        idLigaParticipante: idLp,
        idUsuarioSolicitante: shell.idUsuario,
        activo: false,
        idEntrenador: null,
      );
      if (!mounted) {
        return;
      }
      await _reloadSquadAndLineupAfterCoachToggle();
      _lineupPanelKey.currentState?.markCoachLayoutApplied();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_humanError(e))));
      }
    } finally {
      if (mounted) {
        setState(() => _coachToggleLoading = false);
      }
    }
  }

  Future<bool> _persistCoachIfDirty() async {
    if (!_coachDirty) {
      return true;
    }
    final shell = LeagueShellData.maybeOf(context);
    if (shell == null || _pendingCoachActive == null) {
      return false;
    }
    setState(() => _coachToggleLoading = true);
    try {
      final api = context.read<LeaguesApiService>();
      final idLp = await _resolveOwnLigaParticipanteId(
        api: api,
        leagueId: shell.leagueId,
        idUsuario: shell.idUsuario,
      );
      if (!mounted) {
        return false;
      }
      if (idLp <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.leagueL10n.couldNotResolveParticipant)),
        );
        return false;
      }
      await api.setCoachActive(
        idLiga: shell.leagueId,
        idLigaParticipante: idLp,
        idUsuarioSolicitante: shell.idUsuario,
        activo: _pendingCoachActive!,
        idEntrenador: (_pendingCoachActive ?? false) ? _pendingCoachId : null,
      );
      if (mounted) {
        setState(() {
          _pendingCoachActive = null;
          _pendingCoachId = null;
          _pendingCoachSnapshot = null;
        });
      }
      return true;
    } catch (e) {
      if (!mounted) {
        return false;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_humanError(e))));
      return false;
    } finally {
      if (mounted) {
        setState(() => _coachToggleLoading = false);
      }
    }
  }

  Future<void> _reloadLineup() async {
    final shell = LeagueShellData.maybeOf(context);
    if (shell == null) {
      return;
    }
    try {
      final api = context.read<LeaguesApiService>();
      final lu = await api.getEditableLineup(
        idLiga: shell.leagueId,
        idUsuario: shell.idUsuario,
      );
      _starterProbLogLineupJornada(lu);
      final idJ = lu.idJornada > 0 ? lu.idJornada : null;
      _starterProbLogSquadLoad(shell, idJ);
      LeagueSquadResponse? squadResponse;
      late List<LeagueSquadPlayer> players;
      try {
        squadResponse = await api.getSquadResponse(
          idLiga: shell.leagueId,
          idUsuario: shell.idUsuario,
          idJornada: idJ,
        );
        players = squadResponse.plantilla;
      } catch (_) {
        squadResponse = null;
        players = await api.getSquad(
          idLiga: shell.leagueId,
          idUsuario: shell.idUsuario,
          idJornada: idJ,
        );
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _lineup = lu;
        _lineupError = null;
        _lineupRevision++;
        _players = players;
        _squadResponse = squadResponse;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _lineupError = _humanError(e);
      });
    }
  }

  Future<List<LeagueCoachAssignment>> _fetchCoachInventoryForPicker() async {
    final shell = LeagueShellData.maybeOf(context);
    if (shell == null || _lineup == null) {
      return _availableCoaches();
    }
    final api = context.read<LeaguesApiService>();
    final idLp = await _resolveOwnLigaParticipanteId(
      api: api,
      leagueId: shell.leagueId,
      idUsuario: shell.idUsuario,
    );
    if (idLp <= 0) {
      return _availableCoaches();
    }
    try {
      return await api.getCoachInventory(
        idLiga: shell.leagueId,
        idLigaParticipante: idLp,
        idUsuarioSolicitante: shell.idUsuario,
      );
    } catch (_) {
      return _availableCoaches();
    }
  }

  Future<int> _resolveOwnLigaParticipanteId({
    required LeaguesApiService api,
    required int leagueId,
    required int idUsuario,
  }) async {
    final fromLineup = _lineup?.idLigaParticipante ?? 0;
    if (fromLineup > 0) {
      return fromLineup;
    }
    final participants = await api.getParticipants(
      idLiga: leagueId,
      idUsuario: idUsuario,
    );
    for (final p in participants) {
      if (p.idUsuario == idUsuario && p.idLigaParticipante > 0) {
        return p.idLigaParticipante;
      }
    }
    return 0;
  }

  bool get _lineupHasUnsavedChanges {
    if (_segment != 0) {
      return false;
    }
    return _lineupPanelReportsUnsaved;
  }

  Future<bool> _confirmLeaveLineupEditor() async {
    final panel = _lineupPanelKey.currentState;
    if (panel == null) {
      return true;
    }
    return panel.confirmLeaveUnsaved();
  }

  Future<void> _openOwnHistory() async {
    if (!await _confirmLeaveLineupEditor()) {
      return;
    }
    final shell = LeagueShellData.maybeOf(context);
    if (shell == null) {
      return;
    }
    try {
      final api = context.read<LeaguesApiService>();
      final idLigaParticipante = await _resolveOwnLigaParticipanteId(
        api: api,
        leagueId: shell.leagueId,
        idUsuario: shell.idUsuario,
      );
      if (!mounted) {
        return;
      }
      if (idLigaParticipante <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.leagueL10n.couldNotResolveParticipant)),
        );
        return;
      }
      await LeagueInnerNavigation.openParticipantLineupHistory(
        context: context,
        idLiga: shell.leagueId,
        idLigaParticipante: idLigaParticipante,
        idUsuarioSolicitante: shell.idUsuario,
        idUsuarioParticipante: shell.idUsuario,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_humanError(e))));
    }
  }

  LeagueCoachAssignment? _coachForSummary() {
    return _squadResponse?.entrenadorAsignado ?? _lineup?.entrenadorAsignado;
  }

  bool _entrenadorActivoForSummary() {
    return _squadResponse?.entrenadorActivo ??
        _lineup?.entrenadorActivo ??
        false;
  }

  String _formacionEfectivaForSummary() {
    final raw =
        (_squadResponse?.formacionEfectiva ?? _lineup?.formacionEfectiva ?? '')
            .trim();
    if (raw.isEmpty) {
      return '4-3-3';
    }
    return raw;
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

  List<Widget> _buildRosterSlivers() {
    final grouped = _group(_players!);
    final slivers = <Widget>[];

    for (final line in LeagueSquadPositionBucket.displayOrder) {
      final list = grouped[line]!;
      if (list.isEmpty) continue;

      final lineColor = LeagueSquadPositionBucket.lineColor(line);

      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: lineColor,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [BoxShadow(color: lineColor.withValues(alpha: 0.5), blurRadius: 6)],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    LeagueSquadPositionBucket.sectionTitle(line).toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Lumiare',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: lineColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: lineColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: lineColor.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    '${list.length}',
                    style: TextStyle(
                      fontFamily: 'Lumiare',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: lineColor,
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
                  onTap: () async {
                    final s = LeagueShellData.maybeOf(context);
                    await leagueAfterPush(
                      context,
                      LeagueInnerNavigation.openPlayerProfile(
                        context: context,
                        player: player,
                        leagueId: s?.leagueId,
                        idLigaJugador: player.idLigaJugador,
                        idUsuario: s?.idUsuario,
                        isOwnPlayerHint: true,
                        isMarketPlayerHint: false,
                      ),
                      _load,
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
    final l10n = context.l10n;
    super.build(context);
    final shell = LeagueShellData.maybeOf(context);

    return PopScope(
      canPop: !_lineupHasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        final leave = await _confirmLeaveLineupEditor();
        if (leave && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header fijo: acento + título + historial
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: context.xiAccentText,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.squad.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Lumiare',
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: context.xiTextPrimary,
                    letterSpacing: 2,
                  ),
                ),
                if (_segment == 0 && _lineup != null) ...[
                  const SizedBox(width: 12),
                  Text(
                    _formacionEfectivaVisual(),
                    style: TextStyle(
                      fontFamily: 'Lumiare',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: context.xiTextPrimary,
                      letterSpacing: 0.5,
                      height: 1.1,
                    ),
                  ),
                ],
                const Spacer(),
                Tooltip(
                  message: l10n.history,
                  child: GestureDetector(
                    onTap: _openOwnHistory,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: context.xiChipBackground,
                        border: Border.all(color: context.xiBorderSubtle),
                      ),
                      child: const LineupHistoryIcon(size: 30),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Selector Alineación/Plantilla — custom XiColors
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _XiSquadTabSelector(
              key: ValueKey<int>(_segment),
              selected: _segment,
              lineupLabel: l10n.lineup,
              squadLabel: l10n.squad,
              onSelect: (next) async {
                if (next == _segment) return;
                if (_segment == 0 && next != 0) {
                  final leave = await _confirmLeaveLineupEditor();
                  if (!leave) return;
                }
                if (!mounted) return;
                setState(() => _segment = next);
                _scheduleLoad();
              },
            ),
          ),
          // Barra de acciones fija: capitán, autocompletar, guardar (solo tab alineación)
          if (_segment == 0 && !_loading && _error == null && _players != null && _players!.isNotEmpty)
            _LineupActionBar(panelKey: _lineupPanelKey, unsaved: _lineupPanelReportsUnsaved),
          // Contenido desplazable
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                final shell = LeagueShellData.maybeOf(context);
                if (shell != null) {
                  await shell.reload();
                }
                await _load();
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (_loading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _SquadError(
                        message: _error!,
                        onRetry: _load,
                      ),
                    )
                  else if (_players == null || _players!.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _SquadEmpty(),
                    )
                  else if (_segment == 0)
                    _lineupError != null
                        ? SliverFillRemaining(
                            hasScrollBody: false,
                            child: _LineupFetchError(
                              message: _lineupError!,
                              onRetry: _reloadLineup,
                            ),
                          )
                        : SliverFillRemaining(
                            hasScrollBody: true,
                            child: shell == null || _lineup == null
                                ? const Center(child: CircularProgressIndicator())
                                : LeagueSquadLineupPanel(
                                    key: _lineupPanelKey,
                                    squad: _players!,
                                    lineup: _lineup!,
                                    lineupRevision: _lineupRevision,
                                    idLiga: shell.leagueId,
                                    idUsuario: shell.idUsuario,
                                    onLineupReloaded:
                                        _reloadSquadAndLineupAfterCoachToggle,
                                    entrenadorAsignado: _selectedCoachVisual(),
                                    entrenadoresDisponibles: _availableCoaches(),
                                    entrenadorActivo: _entrenadorActivoVisual(),
                                    formacionEfectiva: _formacionEfectivaVisual(),
                                    coachToggleLoading: _coachToggleLoading,
                                    fetchCoachInventory: _fetchCoachInventoryForPicker,
                                    onCoachSelectionChanged: _onCoachSelectionChanged,
                                    coachDirty: _coachDirty,
                                    implicitLineupDirty: _implicitLineupDirty,
                                    onSaveCoachChanges: _persistCoachIfDirty,
                                    onLineupSaveSuccess: () {
                                      setState(() => _implicitLineupDirty = false);
                                    },
                                    onDiscardPendingCoachChanges: () {
                                      setState(() {
                                        _pendingCoachActive = null;
                                        _pendingCoachId = null;
                                        _pendingCoachSnapshot = null;
                                        _implicitLineupDirty = false;
                                      });
                                    },
                                    onUnsavedStateChanged: (dirty) {
                                      if (_lineupPanelReportsUnsaved == dirty) {
                                        return;
                                      }
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        if (!mounted ||
                                            _lineupPanelReportsUnsaved == dirty) {
                                          return;
                                        }
                                        setState(
                                          () => _lineupPanelReportsUnsaved = dirty,
                                        );
                                      });
                                    },
                                    onProfileLongPress: (p) async {
                                      if (!await _confirmLeaveLineupEditor()) {
                                        return;
                                      }
                                      if (!context.mounted) {
                                        return;
                                      }
                                      await leagueAfterPush(
                                        context,
                                        LeagueInnerNavigation.openPlayerProfile(
                                          context: context,
                                          player: p,
                                          leagueId: shell.leagueId,
                                          idLigaJugador: p.idLigaJugador,
                                          idUsuario: shell.idUsuario,
                                          isOwnPlayerHint: true,
                                          isMarketPlayerHint: false,
                                        ),
                                        _load,
                                      );
                                    },
                                  ),
                          )
                  else
                    ..._buildRosterSlivers(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineupActionBar extends StatelessWidget {
  const _LineupActionBar({
    required this.panelKey,
    required this.unsaved,
  });

  final GlobalKey<LeagueSquadLineupPanelState> panelKey;
  final bool unsaved;

  @override
  Widget build(BuildContext context) {
    final panel = panelKey.currentState;
    final blocked = panel?.isLineupBlocked ?? false;
    final saving = panel?.isSavingForParent ?? false;
    final canSave = panel?.canSaveForParent ?? false;
    final l10n = context.l10n;
    final ll = context.leagueL10n;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _SquadActionChip(
              icon: Icons.verified_outlined,
              label: l10n.captain,
              color: XiColors.classicGold,
              enabled: !blocked && !saving,
              onTap: () => panelKey.currentState?.triggerCaptainPicker(),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _SquadActionChip(
              icon: Icons.auto_fix_high_rounded,
              label: ll.autoFill,
              color: context.xiAccentText,
              enabled: !blocked,
              onTap: () => panelKey.currentState?.triggerAutofill(),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _SquadActionChip(
              icon: saving ? Icons.hourglass_top_rounded : Icons.save_rounded,
              label: saving ? l10n.saving : l10n.save,
              color: canSave ? XiColors.emeraldGreen : XiColors.steelGray,
              enabled: !saving && canSave,
              onTap: () => panelKey.currentState?.triggerSave(),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineupFetchError extends StatelessWidget {
  const _LineupFetchError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sports_soccer_outlined, size: 48, color: XiColors.heroRed),
          const SizedBox(height: 16),
          Text(
            context.leagueL10n.couldNotLoadLineupTitle,
            style: const TextStyle(
              fontFamily: 'Lumiare',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: XiColors.warmWhite,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(
              fontFamily: 'Lumiare',
              fontSize: 12,
              color: XiColors.steelGray.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _XiActionButton(label: context.l10n.retry, onTap: onRetry, color: XiColors.royalBlue),
        ],
      ),
    );
  }
}

class _SquadError extends StatelessWidget {
  const _SquadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48, color: XiColors.heroRed),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontFamily: 'Lumiare',
              fontSize: 12,
              color: XiColors.steelGray.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _XiActionButton(label: context.l10n.retry, onTap: onRetry, color: XiColors.royalBlue),
        ],
      ),
    );
  }
}

class _SquadEmpty extends StatelessWidget {
  const _SquadEmpty();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sports_soccer_outlined, size: 52, color: XiColors.royalBlue),
          const SizedBox(height: 16),
          Text(
            context.leagueL10n.emptySquadTitle,
            style: const TextStyle(
              fontFamily: 'Lumiare',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: XiColors.warmWhite,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            context.leagueL10n.emptySquadBody,
            style: TextStyle(
              fontFamily: 'Lumiare',
              fontSize: 12,
              color: XiColors.steelGray.withValues(alpha: 0.75),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Custom squad tab selector ────────────────────────────────────────────────

class _XiSquadTabSelector extends StatelessWidget {
  const _XiSquadTabSelector({
    super.key,
    required this.selected,
    required this.lineupLabel,
    required this.squadLabel,
    required this.onSelect,
  });

  final int selected;
  final String lineupLabel;
  final String squadLabel;
  final Future<void> Function(int) onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: context.xiChipBackground,
        border: Border.all(color: context.xiBorderSubtle),
      ),
      child: Row(
        children: [
          _tab(context, 0, Icons.grid_on_outlined, lineupLabel, context.xiAccentText),
          _tab(context, 1, Icons.groups_2_outlined, squadLabel, context.xiAccentText),
        ],
      ),
    );
  }

  Widget _tab(BuildContext context, int index, IconData icon, String label, Color color) {
    final isSelected = index == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
            border: isSelected ? Border.all(color: color.withValues(alpha: 0.4)) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: isSelected ? color : context.xiTextPrimary),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Lumiare',
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? color : context.xiTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shared action button ─────────────────────────────────────────────────────

class _XiActionButton extends StatelessWidget {
  const _XiActionButton({required this.label, required this.onTap, required this.color});
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withValues(alpha: 0.15),
          border: Border.all(color: color.withValues(alpha: 0.4)),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 10)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Lumiare',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SquadActionChip extends StatelessWidget {
  const _SquadActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled ? color : XiColors.steelGray.withValues(alpha: 0.4);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: enabled
              ? effectiveColor.withValues(alpha: 0.12)
              : XiColors.surfaceContainer.withValues(alpha: 0.4),
          border: Border.all(
            color: enabled
                ? effectiveColor.withValues(alpha: 0.35)
                : XiColors.steelGray.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: effectiveColor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Lumiare',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: effectiveColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
