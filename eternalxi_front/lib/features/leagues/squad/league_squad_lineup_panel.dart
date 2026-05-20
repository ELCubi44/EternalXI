import 'package:eternal_xi/core/network/api_exception.dart';
import 'package:eternal_xi/core/utils/league_coach_photo.dart';
import 'package:eternal_xi/data/models/league_coach_assignment.dart';
import 'package:eternal_xi/data/models/league_editable_lineup.dart';
import 'package:eternal_xi/data/models/league_lineup_empty_slot.dart';
import 'package:eternal_xi/data/models/league_squad_player.dart';
import 'package:eternal_xi/data/services/leagues_api_service.dart';
import 'package:eternal_xi/features/leagues/squad/league_squad_position_bucket.dart';
import 'package:eternal_xi/features/leagues/utils/league_display_strings.dart';
import 'package:eternal_xi/features/leagues/utils/league_player_availability_icons.dart';
import 'package:eternal_xi/features/leagues/utils/league_player_estado_titularidad.dart';
import 'package:eternal_xi/features/leagues/utils/league_player_visible_estado.dart';
import 'package:eternal_xi/features/leagues/utils/league_starter_probability_ui.dart';
import 'package:eternal_xi/features/leagues/widgets/league_player_avatar.dart';
import 'package:eternal_xi/features/leagues/widgets/league_team_logo.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Fallback `4-3-3` si [raw] es null, vacío o `def + mid + fwd != 10`.
({int defCount, int midCount, int fwdCount}) _parseFormationCounts(
  String? raw,
) {
  const fd = 4;
  const fm = 3;
  const fw = 3;
  final trimmed = raw?.trim() ?? '';
  if (trimmed.isEmpty) {
    return (defCount: fd, midCount: fm, fwdCount: fw);
  }
  final parts = trimmed
      .split(RegExp(r'[-\s,/]+'))
      .where((s) => s.isNotEmpty)
      .map((s) => int.tryParse(s.trim()))
      .toList();
  if (parts.length != 3) {
    return (defCount: fd, midCount: fm, fwdCount: fw);
  }
  final d = parts[0];
  final m = parts[1];
  final f = parts[2];
  if (d == null || m == null || f == null || d < 0 || m < 0 || f < 0) {
    return (defCount: fd, midCount: fm, fwdCount: fw);
  }
  if (d + m + f != 10) {
    return (defCount: fd, midCount: fm, fwdCount: fw);
  }
  return (defCount: d, midCount: m, fwdCount: f);
}

/// Reparte [count] huecos en X de forma uniforme (estilo anterior ~±0.82).
List<Alignment> _pitchRowAlignments(
  int count,
  double y, {
  double halfSpan = 0.82,
}) {
  if (count <= 0) {
    return const [];
  }
  if (count == 1) {
    return [Alignment(0, y)];
  }
  return List<Alignment>.generate(count, (i) {
    final t = i / (count - 1);
    final x = -halfSpan + t * (2 * halfSpan);
    return Alignment(x, y);
  });
}

const double _pitchDefY = -0.52;
const double _pitchMidY = 0.02;
const double _pitchFwdY = 0.65;

bool _emptySlotLineMatches(LeagueSquadLine line, String rawPosicion) {
  var bucket = LeagueSquadPositionBucket.forPosition(rawPosicion);
  if (bucket == LeagueSquadLine.otros) {
    final u = rawPosicion.trim().toUpperCase();
    if (u.startsWith('DEF')) {
      bucket = LeagueSquadLine.defensas;
    } else if (u.startsWith('MED') || u.startsWith('MC')) {
      bucket = LeagueSquadLine.mediocentros;
    } else if (u.startsWith('DEL')) {
      bucket = LeagueSquadLine.delanteros;
    } else if (u.startsWith('POR') || u == 'GK') {
      bucket = LeagueSquadLine.porteros;
    }
  }
  return bucket == line;
}

/// [orden] backend puede ser 1-based (preferido) o 0-based.
bool _emptySlotOrdenMatches(int ordenBackend, int slotIndex0Based) {
  final oneBased = slotIndex0Based + 1;
  return ordenBackend == oneBased || ordenBackend == slotIndex0Based;
}

class LeagueSquadLineupPanel extends StatefulWidget {
  const LeagueSquadLineupPanel({
    super.key,
    required this.squad,
    required this.lineup,
    required this.lineupRevision,
    required this.idLiga,
    required this.idUsuario,
    required this.onLineupReloaded,
    required this.entrenadorAsignado,
    this.entrenadoresDisponibles = const [],
    required this.entrenadorActivo,
    required this.formacionEfectiva,
    this.coachToggleLoading = false,
    this.fetchCoachInventory,
    this.onCoachSelectionChanged,
    this.coachDirty = false,
    this.implicitLineupDirty = false,
    this.onSaveCoachChanges,
    this.onLineupSaveSuccess,
    this.onProfileLongPress,
    this.readOnly = false,
    this.onReadOnlyPlayerTap,
    this.onHistoryTap,
  });

  final List<LeagueSquadPlayer> squad;
  final LeagueEditableLineup lineup;
  final int lineupRevision;
  final int idLiga;
  final int idUsuario;
  final LeagueCoachAssignment? entrenadorAsignado;
  final List<LeagueCoachAssignment> entrenadoresDisponibles;
  final bool entrenadorActivo;
  final String formacionEfectiva;
  final bool coachToggleLoading;

  /// Inventario remoto al abrir el selector (`GET .../coach/inventory`).
  final Future<List<LeagueCoachAssignment>> Function()? fetchCoachInventory;

  final void Function(bool active, LeagueCoachAssignment? coach)?
  onCoachSelectionChanged;
  final bool coachDirty;
  final bool implicitLineupDirty;
  final Future<bool> Function()? onSaveCoachChanges;

  /// Tras POST de alineación correcto (antes o después de [onLineupReloaded]).
  final VoidCallback? onLineupSaveSuccess;

  /// Tras guardar OK: el padre vuelve a pedir GET /lineup y sube [lineupRevision].
  final Future<void> Function() onLineupReloaded;

  final void Function(LeagueSquadPlayer player)? onProfileLongPress;

  /// Solo lectura: sin guardar, capitán ni cambios; opcional tap en jugador (p. ej. ficha).
  final bool readOnly;

  final void Function(LeagueSquadPlayer player)? onReadOnlyPlayerTap;
  final VoidCallback? onHistoryTap;

  @override
  State<LeagueSquadLineupPanel> createState() => _LeagueSquadLineupPanelState();
}

class _LineState {
  _LineState(this.slotCount);

  final int slotCount;
  final List<LeagueSquadPlayer?> slots = [];
  final List<LeagueSquadPlayer> bench = [];

  static void fillFromLineup({
    required _LineState target,
    required LeagueSquadLine line,
    required Set<int> titularIds,
    required Set<int> reserveIds,
    required Map<int, LeagueSquadPlayer> byId,
  }) {
    List<LeagueSquadPlayer?> pickStarters(LeagueSquadLine ln, int count) {
      final found =
          titularIds
              .map((id) => byId[id])
              .whereType<LeagueSquadPlayer>()
              .where(
                (p) => LeagueSquadPositionBucket.forPosition(p.posicion) == ln,
              )
              .toList()
            ..sort((a, b) => b.valor.compareTo(a.valor));
      return List<LeagueSquadPlayer?>.generate(
        count,
        (i) => i < found.length ? found[i] : null,
      );
    }

    LeagueSquadPlayer? pickOnePortero() {
      final found =
          titularIds
              .map((id) => byId[id])
              .whereType<LeagueSquadPlayer>()
              .where(
                (p) =>
                    LeagueSquadPositionBucket.forPosition(p.posicion) ==
                    LeagueSquadLine.porteros,
              )
              .toList()
            ..sort((a, b) => b.valor.compareTo(a.valor));
      return found.isEmpty ? null : found.first;
    }

    List<LeagueSquadPlayer> pickBench(LeagueSquadLine ln) {
      return reserveIds
          .map((id) => byId[id])
          .whereType<LeagueSquadPlayer>()
          .where((p) => LeagueSquadPositionBucket.forPosition(p.posicion) == ln)
          .toList()
        ..sort((a, b) => b.valor.compareTo(a.valor));
    }

    target.slots.clear();
    target.bench.clear();

    switch (line) {
      case LeagueSquadLine.porteros:
        target.slots.add(pickOnePortero());
        target.bench.addAll(pickBench(LeagueSquadLine.porteros));
        break;
      case LeagueSquadLine.defensas:
        target.slots.addAll(
          pickStarters(LeagueSquadLine.defensas, target.slotCount),
        );
        target.bench.addAll(pickBench(LeagueSquadLine.defensas));
        break;
      case LeagueSquadLine.mediocentros:
        target.slots.addAll(
          pickStarters(LeagueSquadLine.mediocentros, target.slotCount),
        );
        target.bench.addAll(pickBench(LeagueSquadLine.mediocentros));
        break;
      case LeagueSquadLine.delanteros:
        target.slots.addAll(
          pickStarters(LeagueSquadLine.delanteros, target.slotCount),
        );
        target.bench.addAll(pickBench(LeagueSquadLine.delanteros));
        break;
      case LeagueSquadLine.otros:
        break;
    }
  }
}

class _PitchLineupModel {
  _PitchLineupModel({
    required this.gk,
    required this.defLine,
    required this.midLine,
    required this.fwdLine,
    required this.emptySlots,
  });

  final _LineState gk;
  final _LineState defLine;
  final _LineState midLine;
  final _LineState fwdLine;
  final List<LeagueLineupEmptySlot> emptySlots;

  factory _PitchLineupModel.fromLineup(
    LeagueEditableLineup lu,
    Map<int, LeagueSquadPlayer> byId,
    String? formationOverride,
  ) {
    final tit = lu.titulares.toSet();
    final res = lu.reservas.toSet();

    final counts = _parseFormationCounts(
      (formationOverride ?? lu.formacionEfectiva).trim(),
    );

    final gk = _LineState(1);
    final defLine = _LineState(counts.defCount);
    final midLine = _LineState(counts.midCount);
    final fwdLine = _LineState(counts.fwdCount);

    _LineState.fillFromLineup(
      target: gk,
      line: LeagueSquadLine.porteros,
      titularIds: tit,
      reserveIds: res,
      byId: byId,
    );
    _LineState.fillFromLineup(
      target: defLine,
      line: LeagueSquadLine.defensas,
      titularIds: tit,
      reserveIds: res,
      byId: byId,
    );
    _LineState.fillFromLineup(
      target: midLine,
      line: LeagueSquadLine.mediocentros,
      titularIds: tit,
      reserveIds: res,
      byId: byId,
    );
    _LineState.fillFromLineup(
      target: fwdLine,
      line: LeagueSquadLine.delanteros,
      titularIds: tit,
      reserveIds: res,
      byId: byId,
    );

    return _PitchLineupModel(
      gk: gk,
      defLine: defLine,
      midLine: midLine,
      fwdLine: fwdLine,
      emptySlots: lu.emptySlots,
    );
  }
}

class _LeagueSquadLineupPanelState extends State<LeagueSquadLineupPanel> {
  late _PitchLineupModel _model;
  int? _captainId;
  List<int> _baselineTitulares = [];
  List<int> _baselineReservas = [];
  int? _baselineCaptain;
  bool _saving = false;

  Map<int, LeagueSquadPlayer> _byLigaJugadorId() {
    final m = <int, LeagueSquadPlayer>{};
    for (final p in widget.squad) {
      m[p.idLigaJugador] = p;
    }
    return m;
  }

  /// Plantilla real del usuario: excluye jugadores del pool de mercado (owner 1).
  Iterable<LeagueSquadPlayer> _squadPoolForUserLineup() sync* {
    for (final p in widget.squad) {
      if (p.idUsuarioDueno == LeagueSquadPlayer.usuarioMercadoId) {
        continue;
      }
      yield p;
    }
  }

  bool get _blocked => widget.lineup.bloqueada;

  @override
  void initState() {
    super.initState();
    _applyLineupFromProps(resetBaseline: true);
  }

  @override
  void didUpdateWidget(covariant LeagueSquadLineupPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lineupRevision != widget.lineupRevision ||
        oldWidget.lineup.idJornada != widget.lineup.idJornada ||
        oldWidget.lineup.bloqueada != widget.lineup.bloqueada ||
        oldWidget.lineup.formacionEfectiva != widget.lineup.formacionEfectiva ||
        oldWidget.formacionEfectiva != widget.formacionEfectiva ||
        oldWidget.entrenadorActivo != widget.entrenadorActivo ||
        oldWidget.entrenadorAsignado?.idEntrenador !=
            widget.entrenadorAsignado?.idEntrenador ||
        !_sameEmptySlotsSnapshot(
          oldWidget.lineup.emptySlots,
          widget.lineup.emptySlots,
        ) ||
        !_sameSquadSnapshot(oldWidget.squad, widget.squad)) {
      _applyLineupFromProps(resetBaseline: true);
    }
  }

  bool _sameEmptySlotsSnapshot(
    List<LeagueLineupEmptySlot> a,
    List<LeagueLineupEmptySlot> b,
  ) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    String key(LeagueLineupEmptySlot e) =>
        '${e.posicion}|${e.orden}|${e.penalizacion}|${e.emptySlot}';
    final ka = a.map(key).toList()..sort();
    final kb = b.map(key).toList()..sort();
    return listEquals(ka, kb);
  }

  bool _sameSquadSnapshot(
    List<LeagueSquadPlayer> previous,
    List<LeagueSquadPlayer> current,
  ) {
    if (identical(previous, current)) {
      return true;
    }
    if (previous.length != current.length) {
      return false;
    }
    final prevIds = previous.map((p) => p.idLigaJugador).toSet();
    final currIds = current.map((p) => p.idLigaJugador).toSet();
    return prevIds.length == currIds.length && prevIds.containsAll(currIds);
  }

  void _applyLineupFromProps({required bool resetBaseline}) {
    final byId = _byLigaJugadorId();
    _model = _PitchLineupModel.fromLineup(
      widget.lineup,
      byId,
      widget.formacionEfectiva,
    );
    _rebuildBenchFromFullSquad();
    if (!widget.readOnly) {
      _autofillEmptyStarterSlots();
    }
    _captainId = widget.lineup.idCapitan ?? _fallbackCaptainId();
    if (resetBaseline) {
      final p = _packIds();
      _baselineTitulares = [...p.titulares]..sort();
      _baselineReservas = [...p.reservas]..sort();
      _baselineCaptain = _captainId;
    }
  }

  void _rebuildBenchFromFullSquad() {
    final starterIds = _orderedStarters().map((p) => p.idLigaJugador).toSet();
    void assignLineBench(_LineState line, LeagueSquadLine targetLine) {
      final list =
          _squadPoolForUserLineup()
              .where(
                (p) =>
                    LeagueSquadPositionBucket.forPosition(p.posicion) ==
                        targetLine &&
                    !starterIds.contains(p.idLigaJugador),
              )
              .toList()
            ..sort((a, b) => b.valor.compareTo(a.valor));
      line.bench
        ..clear()
        ..addAll(list);
    }

    assignLineBench(_model.gk, LeagueSquadLine.porteros);
    assignLineBench(_model.defLine, LeagueSquadLine.defensas);
    assignLineBench(_model.midLine, LeagueSquadLine.mediocentros);
    assignLineBench(_model.fwdLine, LeagueSquadLine.delanteros);
  }

  void _autofillEmptyStarterSlots() {
    bool fillLine(_LineState line) {
      var changed = false;
      for (var i = 0; i < line.slots.length; i++) {
        if (line.slots[i] != null) {
          continue;
        }
        if (line.bench.isEmpty) {
          continue;
        }
        line.slots[i] = line.bench.removeAt(0);
        changed = true;
      }
      return changed;
    }

    final changed =
        fillLine(_model.gk) |
        fillLine(_model.defLine) |
        fillLine(_model.midLine) |
        fillLine(_model.fwdLine);
    if (changed) {
      _rebuildBenchFromFullSquad();
    }
  }

  int? _fallbackCaptainId() {
    final starters = _orderedStarters();
    if (starters.isEmpty) {
      return null;
    }
    starters.sort((a, b) => b.valor.compareTo(a.valor));
    return starters.first.idLigaJugador;
  }

  /// Titulares en orden de envío al backend: POR + DEF + MED + DEL (conteos dinámicos).
  List<LeagueSquadPlayer> _orderedStarters() {
    final out = <LeagueSquadPlayer?>[
      if (_model.gk.slots.isNotEmpty) _model.gk.slots[0],
      ..._model.defLine.slots,
      ..._model.midLine.slots,
      ..._model.fwdLine.slots,
    ];
    return out.whereType<LeagueSquadPlayer>().toList();
  }

  ({List<int> titulares, List<int> reservas}) _packIds() {
    final tit = <int>[
      if (_model.gk.slots.isNotEmpty && _model.gk.slots[0] != null)
        _model.gk.slots[0]!.idLigaJugador,
      for (final s in _model.defLine.slots)
        if (s != null) s.idLigaJugador,
      for (final s in _model.midLine.slots)
        if (s != null) s.idLigaJugador,
      for (final s in _model.fwdLine.slots)
        if (s != null) s.idLigaJugador,
    ];
    final resAll = <int>[
      for (final p in _model.gk.bench) p.idLigaJugador,
      for (final p in _model.defLine.bench) p.idLigaJugador,
      for (final p in _model.midLine.bench) p.idLigaJugador,
      for (final p in _model.fwdLine.bench) p.idLigaJugador,
    ];
    final res = resAll.take(4).toList(growable: false);
    if (kDebugMode) {
      debugPrint('[save-debug] titularesPacked=$tit');
      debugPrint('[save-debug] reservasPacked=$res');
    }
    return (titulares: tit, reservas: res);
  }

  bool _isLineupDirty() {
    final p = _packIds();
    final t = [...p.titulares]..sort();
    final r = [...p.reservas]..sort();
    final dirty =
        !listEquals(t, _baselineTitulares) ||
        !listEquals(r, _baselineReservas) ||
        _captainId != _baselineCaptain;
    if (kDebugMode) {
      debugPrint('[save-debug] dirty=$dirty');
      debugPrint('[save-debug] baselineTitulares=$_baselineTitulares');
      debugPrint('[save-debug] baselineReservas=$_baselineReservas');
      debugPrint('[save-debug] captain=$_captainId');
      debugPrint('[save-debug] baselineCaptain=$_baselineCaptain');
    }
    return dirty;
  }

  bool get _lineupComplete {
    final p = _packIds();
    return p.titulares.length == 11 && p.reservas.length <= 4;
  }

  bool get _canSaveIncludingCoach =>
      !_blocked &&
      _lineupComplete &&
      (_isLineupDirty() ||
          widget.coachDirty ||
          widget.implicitLineupDirty);

  static String _shortName(LeagueSquadPlayer? p) {
    if (p == null) {
      return '—';
    }
    return LeagueDisplayStrings.playerShortName(pila: p.pila, nombre: p.nombre);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _sheetPick({
    String? title,
    String? subtitle,
    required List<Widget> children,
  }) async {
    final safeTitle = (title ?? '').trim();
    final safeSubtitle = (subtitle ?? '').trim();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        final bottom = MediaQuery.paddingOf(ctx).bottom;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (safeTitle.isNotEmpty)
                  Text(
                    safeTitle,
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (safeSubtitle.isNotEmpty) ...[
                  if (safeTitle.isNotEmpty) const SizedBox(height: 6),
                  const SizedBox(height: 6),
                  Text(
                    safeSubtitle,
                    style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (safeTitle.isNotEmpty || safeSubtitle.isNotEmpty)
                  const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(ctx).height * 0.55,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: children,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _onTitularTap({
    required _LineState line,
    required int slotIndex,
    required String demarcacion,
  }) async {
    if (widget.readOnly) {
      final p = slotIndex < line.slots.length ? line.slots[slotIndex] : null;
      if (p != null) {
        widget.onReadOnlyPlayerTap?.call(p);
      }
      return;
    }
    if (_blocked) {
      return;
    }
    final candidates = _candidatesForSlot(line: line, slotIndex: slotIndex);
    await _sheetPick(
      title: '',
      subtitle: '',
      children: candidates.isEmpty
          ? [
              _sheetEmptyState(
                'No hay más jugadores disponibles para esta demarcación',
              ),
            ]
          : [
              for (final b in candidates)
                _lineupSwapOptionTile(
                  player: b,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _assignPlayerToSlot(
                        line: line,
                        slotIndex: slotIndex,
                        incoming: b,
                      );
                      _ensureCaptainStillValid();
                    });
                  },
                ),
            ],
    );
  }

  List<LeagueSquadPlayer> _candidatesForSlot({
    required _LineState line,
    required int slotIndex,
  }) {
    if (slotIndex < 0 || slotIndex >= line.slotCount) {
      return const [];
    }
    final current = line.slots[slotIndex];
    final currentId = current?.idLigaJugador;
    final occupiedStarterIds = _orderedStarters()
        .map((p) => p.idLigaJugador)
        .toSet();

    final out = <LeagueSquadPlayer>[];
    for (final p in _squadPoolForUserLineup()) {
      final sameLine =
          LeagueSquadPositionBucket.forPosition(p.posicion) ==
          _lineForState(line);
      if (!sameLine) {
        continue;
      }
      if (p.idLigaJugador == currentId) {
        continue;
      }
      if (occupiedStarterIds.contains(p.idLigaJugador) &&
          p.idLigaJugador != currentId) {
        continue;
      }
      out.add(p);
    }
    out.sort((a, b) => b.valor.compareTo(a.valor));
    return out;
  }

  Widget _sheetEmptyState(String message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  LeagueSquadLine _lineForState(_LineState line) {
    if (identical(line, _model.gk)) {
      return LeagueSquadLine.porteros;
    }
    if (identical(line, _model.defLine)) {
      return LeagueSquadLine.defensas;
    }
    if (identical(line, _model.midLine)) {
      return LeagueSquadLine.mediocentros;
    }
    return LeagueSquadLine.delanteros;
  }

  Widget _playerSheetTeamRow(LeagueSquadPlayer p) {
    final theme = Theme.of(context);
    final teamName = p.nombreEquipo.trim().isEmpty
        ? 'Equipo'
        : p.nombreEquipo.trim();
    return Row(
      children: [
        LeagueTeamLogo(
          idEquipo: p.idEquipo,
          size: 20,
          networkImageUrl: p.resolvedFotoEquipoUrl(),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            teamName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _ratingLabelSheet(LeagueSquadPlayer p) {
    return p.valoracion % 1 == 0
        ? p.valoracion.toInt().toString()
        : p.valoracion.toStringAsFixed(1);
  }

  void _assignPlayerToSlot({
    required _LineState line,
    required int slotIndex,
    required LeagueSquadPlayer incoming,
  }) {
    if (slotIndex < 0 || slotIndex >= line.slotCount) {
      return;
    }
    final outgoing = line.slots[slotIndex];
    final incomingBenchIndex = line.bench.indexWhere(
      (p) => p.idLigaJugador == incoming.idLigaJugador,
    );
    if (incomingBenchIndex >= 0) {
      line.bench.removeAt(incomingBenchIndex);
      if (outgoing != null &&
          outgoing.idLigaJugador != incoming.idLigaJugador) {
        line.bench.add(outgoing);
      }
      line.bench.sort((a, b) => b.valor.compareTo(a.valor));
    }
    line.slots[slotIndex] = incoming;
    _rebuildBenchFromFullSquad();
  }

  void _ensureCaptainStillValid() {
    final tit = _packIds().titulares.toSet();
    final c = _captainId;
    if (c != null && !tit.contains(c)) {
      _captainId = _fallbackCaptainId();
    }
  }

  Future<void> _onBenchPlayerTap({
    required _LineState line,
    required LeagueSquadPlayer benchPlayer,
    required String demarcacion,
  }) async {
    if (widget.readOnly) {
      widget.onReadOnlyPlayerTap?.call(benchPlayer);
      return;
    }
    if (_blocked) {
      return;
    }
    final reserveCandidates = line.bench
        .where((p) => p.idLigaJugador != benchPlayer.idLigaJugador)
        .toList(growable: false);
    final starterCandidates = line.slots
        .whereType<LeagueSquadPlayer>()
        .where((p) => p.idLigaJugador != benchPlayer.idLigaJugador)
        .toList(growable: false);
    final swapCandidates = <LeagueSquadPlayer>[
      ...starterCandidates,
      ...reserveCandidates,
    ];
    await _sheetPick(
      title: '',
      subtitle: '',
      children: [
        for (final candidate in swapCandidates)
          _lineupSwapOptionTile(
            player: candidate,
            onTap: () {
              Navigator.pop(context);
              setState(() {
                final slotIndex = line.slots.indexWhere(
                  (p) => p?.idLigaJugador == candidate.idLigaJugador,
                );
                if (slotIndex >= 0) {
                  _assignPlayerToSlot(
                    line: line,
                    slotIndex: slotIndex,
                    incoming: benchPlayer,
                  );
                  _ensureCaptainStillValid();
                  return;
                }
                final idxA = line.bench.indexWhere(
                  (p) => p.idLigaJugador == benchPlayer.idLigaJugador,
                );
                final idxB = line.bench.indexWhere(
                  (p) => p.idLigaJugador == candidate.idLigaJugador,
                );
                if (idxA >= 0 && idxB >= 0) {
                  final tmp = line.bench[idxA];
                  line.bench[idxA] = line.bench[idxB];
                  line.bench[idxB] = tmp;
                }
              });
            },
          ),
      ],
    );
  }

  Widget _lineupSwapOptionTile({
    required LeagueSquadPlayer player,
    required VoidCallback onTap,
  }) {
    if (kDebugMode) {
      debugPrint(
        '[starter-prob][swap-tile] idLigaJugador=${player.idLigaJugador} '
        'probabilidadTitular=${player.probabilidadTitular}',
      );
    }
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pct = player.probabilidadTitular;
    final showPctInline =
        pct != null &&
        !leaguePlayerEstadoIsLesionado(
          leaguePlayerEffectiveEstado(
            estado: player.estado,
            estadoVisible: player.estadoVisible,
          ),
        ) &&
        !leaguePlayerEstadoIsSancionado(
          leaguePlayerEffectiveEstado(
            estado: player.estado,
            estadoVisible: player.estadoVisible,
          ),
        );
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      leading: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: LeaguePlayerAvatar(player: player, size: 52, circular: true),
      ),
      minLeadingWidth: 52,
      title: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _shortName(player),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (showPctInline) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: starterTitularidadScaleBackgroundSolid(pct),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$pct%',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: starterTitularidadScaleOnBackground(pct),
                  ),
                ),
              ),
            ],
            const SizedBox(width: 8),
            Icon(
              Icons.star_rounded,
              size: 22,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 2),
            Text(
              _ratingLabelSheet(player),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _playerSheetTeamRow(player),
            if (leaguePlayerEstadoIsLesionado(
              leaguePlayerEffectiveEstado(
                estado: player.estado,
                estadoVisible: player.estadoVisible,
              ),
            )) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LeaguePlayerAvailabilityIcons.injured,
                      size: 16,
                      color: colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Lesionado',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (leaguePlayerEstadoIsSancionado(
              leaguePlayerEffectiveEstado(
                estado: player.estado,
                estadoVisible: player.estadoVisible,
              ),
            )) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LeaguePlayerAvailabilityIcons.sanctioned,
                      size: 16,
                      color: colorScheme.onTertiaryContainer,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Sancionado',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      trailing: Icon(
        Icons.swap_horiz_rounded,
        color: theme.colorScheme.primary,
      ),
      onTap: onTap,
    );
  }

  Future<void> _openCaptainPicker() async {
    if (_blocked) {
      return;
    }
    final starters = _orderedStarters();
    if (starters.length != 11) {
      _toast('La alineación debe tener 11 titulares para elegir capitán.');
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        final maxH = MediaQuery.sizeOf(ctx).height * 0.55;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 8,
              right: 8,
              bottom: MediaQuery.paddingOf(ctx).bottom + 12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Text(
                    'Capitán',
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(
                  height: maxH.clamp(120.0, 420.0),
                  child: ListView.separated(
                    itemCount: starters.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final p = starters[i];
                      final sel = _captainId == p.idLigaJugador;
                      return ListTile(
                        leading: LeaguePlayerAvatar(
                          player: p,
                          size: 40,
                          circular: true,
                        ),
                        title: Text(_shortName(p)),
                        trailing: sel
                            ? Icon(
                                Icons.check,
                                color: Theme.of(ctx).colorScheme.primary,
                              )
                            : null,
                        onTap: () {
                          setState(() => _captainId = p.idLigaJugador);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int _requireCaptainIdForSave() {
    final c = _captainId;
    if (c != null && _packIds().titulares.contains(c)) {
      return c;
    }
    return _fallbackCaptainId()!;
  }

  Future<void> _save() async {
    if (kDebugMode) {
      final blocked = _blocked;
      final lineupComplete = _lineupComplete;
      final dirty = _isLineupDirty();
      final canSave = !blocked && lineupComplete && dirty;
      debugPrint('[save-debug] blocked=$blocked');
      debugPrint('[save-debug] lineupComplete=$lineupComplete');
      debugPrint('[save-debug] dirty=$dirty');
      debugPrint('[save-debug] canSave=$canSave');
    }
    if (!_canSaveIncludingCoach) {
      return;
    }
    final api = context.read<LeaguesApiService>();
    setState(() => _saving = true);
    try {
      if (widget.onSaveCoachChanges != null) {
        final coachOk = await widget.onSaveCoachChanges!.call();
        if (!coachOk) {
          return;
        }
      }
      final packed = _packIds();
      final idCapitan = _requireCaptainIdForSave();
      final body = <String, dynamic>{
        'idUsuario': widget.idUsuario,
        'idJornada': widget.lineup.idJornada,
        'titulares': packed.titulares,
        'reservas': packed.reservas,
        'idCapitan': idCapitan,
      };
      if (kDebugMode) {
        debugPrint('SAVE LINEUP');
        debugPrint('entrenadorActivo=${widget.entrenadorActivo}');
        debugPrint('idEntrenador=${widget.entrenadorAsignado?.idEntrenador}');
        debugPrint('formacionEfectiva=${widget.formacionEfectiva.trim()}');
        debugPrint('titulares=${packed.titulares}');
        debugPrint('reservas=${packed.reservas}');
        debugPrint('body=$body');
      }
      await api.saveLineup(
        idLiga: widget.idLiga,
        idUsuario: widget.idUsuario,
        idJornada: widget.lineup.idJornada,
        titulares: packed.titulares,
        reservas: packed.reservas,
        idCapitan: idCapitan,
      );
      if (!mounted) {
        return;
      }
      _toast('Alineación guardada');
      await widget.onLineupReloaded();
      widget.onLineupSaveSuccess?.call();
    } catch (e) {
      if (mounted) {
        final msg = e is ApiException
            ? e.message
            : e.toString().replaceFirst('Exception: ', '');
        _toast(msg);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Widget _headerRow(ThemeData theme) {
    final historyButton = widget.onHistoryTap == null
        ? null
        : OutlinedButton.icon(
            icon: const Icon(Icons.history_rounded, size: 18),
            onPressed: widget.onHistoryTap,
            label: const Text('Historial'),
          );
    if (widget.readOnly) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            _headerFormationLabel(),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          historyButton ?? const SizedBox.shrink(),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          _headerFormationLabel(),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        if (historyButton != null) ...[
          historyButton,
          const SizedBox(width: 10),
        ],
        OutlinedButton.icon(
          icon: const Icon(Icons.verified_outlined, size: 18),
          onPressed: (_blocked || _saving) ? null : _openCaptainPicker,
          label: const Text('Capitán'),
        ),
        const SizedBox(width: 10),
        if (kDebugMode) ...[
          Builder(
            builder: (_) {
              final blocked = _blocked;
              final lineupComplete = _lineupComplete;
              final dirty = _isLineupDirty();
              final canSave = !blocked && lineupComplete && dirty;
              debugPrint('[save-debug] blocked=$blocked');
              debugPrint('[save-debug] lineupComplete=$lineupComplete');
              debugPrint('[save-debug] dirty=$dirty');
              debugPrint('[save-debug] canSave=$canSave');
              return const SizedBox.shrink();
            },
          ),
        ],
        ElevatedButton.icon(
          icon: Icon(
            _saving ? Icons.hourglass_top_rounded : Icons.save_rounded,
            size: 18,
          ),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(126, 44),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            textStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest,
            disabledForegroundColor: theme.colorScheme.onSurfaceVariant,
          ),
          onPressed: _saving ? null : (_canSaveIncludingCoach ? _save : null),
          label: _saving ? const Text('Guardando...') : const Text('Guardar'),
        ),
      ],
    );
  }

  Widget _benchHorizontalBar() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Banquillo',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _benchRoleCell(
                roleLabel: 'POR',
                line: _model.gk,
                demarcacion: 'portería',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _benchRoleCell(
                roleLabel: 'DEF',
                line: _model.defLine,
                demarcacion: 'defensa',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _benchRoleCell(
                roleLabel: 'MC',
                line: _model.midLine,
                demarcacion: 'mediocentro',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _benchRoleCell(
                roleLabel: 'DEL',
                line: _model.fwdLine,
                demarcacion: 'delantera',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _benchRoleCell({
    required String roleLabel,
    required _LineState line,
    required String demarcacion,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              roleLabel,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 108,
              child: line.bench.isEmpty
                  ? Center(
                      child: Text(
                        '—',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: line.bench.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemBuilder: (context, i) {
                        final p = line.bench[i];
                        return Align(
                          alignment: Alignment.center,
                          child: _benchPlayerChip(
                            player: p,
                            line: line,
                            demarcacion: demarcacion,
                            onProfileLongPress: widget.onProfileLongPress,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _benchPlayerChip({
    required LeagueSquadPlayer player,
    required _LineState line,
    required String demarcacion,
    void Function(LeagueSquadPlayer player)? onProfileLongPress,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final rating = player.valoracion % 1 == 0
        ? player.valoracion.toInt().toString()
        : player.valoracion.toStringAsFixed(1).replaceAll('.', ',');
    return SizedBox(
      width: 76,
      child: Center(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: widget.readOnly
                    ? () => _onBenchPlayerTap(
                        line: line,
                        benchPlayer: player,
                        demarcacion: demarcacion,
                      )
                    : _blocked
                    ? null
                    : () => _onBenchPlayerTap(
                        line: line,
                        benchPlayer: player,
                        demarcacion: demarcacion,
                      ),
                onLongPress: widget.readOnly || onProfileLongPress == null
                    ? null
                    : () => onProfileLongPress(player),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 8,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                          child: LeaguePlayerAvatar(
                            player: player,
                            size: 40,
                            circular: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        LeagueDisplayStrings.shortNickname(
                          _shortName(player),
                          maxLen: 11,
                        ),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: colorScheme.surfaceContainerHighest,
                    width: 1.2,
                  ),
                ),
                child: Text(
                  rating,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isCaptain(LeagueSquadPlayer? p) =>
      p != null && _captainId != null && p.idLigaJugador == _captainId;

  LeagueLineupEmptySlot? _penalizedEmptyMeta({
    required LeagueSquadLine line,
    required int slotIndex0Based,
    required LeagueSquadPlayer? player,
  }) {
    if (player != null) {
      return null;
    }
    for (final es in _model.emptySlots) {
      if (!es.emptySlot) {
        continue;
      }
      if (!_emptySlotLineMatches(line, es.posicion)) {
        continue;
      }
      if (!_emptySlotOrdenMatches(es.orden, slotIndex0Based)) {
        continue;
      }
      return es;
    }
    return null;
  }

  String _headerFormationLabel() {
    final s = widget.formacionEfectiva.trim();
    return s.isEmpty ? '4-3-3' : s;
  }

  String _effectiveFormationForCoachBubble() {
    final raw = widget.formacionEfectiva.trim();
    if (raw.isNotEmpty) {
      return raw;
    }
    final coachFormation = widget.entrenadorAsignado?.formacion?.trim() ?? '';
    if (coachFormation.isNotEmpty) {
      return coachFormation;
    }
    final lu = widget.lineup.formacionEfectiva.trim();
    return lu.isEmpty ? '4-3-3' : lu;
  }

  String _assignedCoachFormation() {
    final coachFormation = widget.entrenadorAsignado?.formacion?.trim() ?? '';
    if (coachFormation.isNotEmpty) {
      return coachFormation;
    }
    return _effectiveFormationForCoachBubble();
  }

  List<LeagueCoachAssignment> _mergeCoachListsForPicker(
    List<LeagueCoachAssignment> primary,
    List<LeagueCoachAssignment> secondary,
    LeagueCoachAssignment? assigned,
  ) {
    final map = <int, LeagueCoachAssignment>{};
    void addAll(List<LeagueCoachAssignment> list) {
      for (final c in list) {
        final id = c.idEntrenador;
        if (id != null && id > 0) {
          map[id] = c;
        }
      }
    }

    addAll(primary);
    addAll(secondary);
    final a = assigned;
    if (a != null) {
      final id = a.idEntrenador;
      if (id != null && id > 0) {
        map[id] = a;
      }
    }
    return map.values.toList();
  }

  Future<void> _onCoachBubbleTap() async {
    if (widget.readOnly || widget.coachToggleLoading || _saving) {
      return;
    }
    var coaches = List<LeagueCoachAssignment>.from(
      widget.entrenadoresDisponibles,
    );

    if (widget.fetchCoachInventory != null) {
      var dialogShown = false;
      try {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 18),
                Expanded(
                  child: Text(
                    'Cargando entrenadores…',
                    style: Theme.of(ctx).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        );
        dialogShown = true;
        final fetched = await widget.fetchCoachInventory!();
        coaches = _mergeCoachListsForPicker(
          fetched,
          coaches,
          widget.entrenadorAsignado,
        );
      } catch (_) {
        coaches = _mergeCoachListsForPicker(
          const [],
          coaches,
          widget.entrenadorAsignado,
        );
      } finally {
        if (dialogShown && mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      }
    } else if (coaches.isEmpty && widget.entrenadorAsignado != null) {
      coaches = [widget.entrenadorAsignado!];
    }

    coaches.sort((a, b) {
      final na = (a.entrenadorNombre ?? a.entrenadorPila ?? '')
          .trim()
          .toLowerCase();
      final nb = (b.entrenadorNombre ?? b.entrenadorPila ?? '')
          .trim()
          .toLowerCase();
      return na.compareTo(nb);
    });

    final options = <_CoachPickerOption>[
      _CoachPickerOption(
        coach: null,
        isNoCoach: true,
        title: 'Sin entrenador',
        formation: '4-3-3',
        teamId: null,
        selected: !widget.entrenadorActivo,
      ),
      for (final coach in coaches)
        _CoachPickerOption.assignedCoach(
          coach: coach,
          formation: (coach.formacion?.trim().isNotEmpty ?? false)
              ? coach.formacion!.trim()
              : _assignedCoachFormation(),
          isSelected:
              widget.entrenadorActivo &&
              widget.entrenadorAsignado?.idEntrenador == coach.idEntrenador,
        ),
    ];
    await _sheetPick(
      title: 'Entrenador',
      subtitle: 'Selecciona cómo quieres jugar esta jornada.',
      children: [for (final option in options) _coachPickerOptionTile(option)],
    );
  }

  Widget _coachPickerOptionTile(_CoachPickerOption option) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selected = option.selected;
    final canToggle = widget.onCoachSelectionChanged != null;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: selected
          ? colorScheme.primaryContainer.withValues(alpha: 0.35)
          : colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.9)
              : colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        enabled: !widget.coachToggleLoading,
        leading: _CoachAvatar(
          imageUrl: option.imageUrl,
          icon: option.isNoCoach
              ? Icons.person_off_rounded
              : Icons.sports_soccer_rounded,
          size: 48,
          isActive: selected,
          teamId: option.teamId,
        ),
        minLeadingWidth: 48,
        title: Text(
          option.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _metaChip(
                icon: Icons.grid_view_rounded,
                text: option.formation,
                highlighted: selected,
              ),
              if (option.bonusLabel != null)
                _metaChip(
                  icon: Icons.add_chart_rounded,
                  text: option.bonusLabel!,
                  highlighted: selected,
                ),
              if (option.equippedBadge)
                _metaChip(
                  icon: Icons.shield_outlined,
                  text: 'Equipado',
                  highlighted: true,
                ),
            ],
          ),
        ),
        trailing: widget.coachToggleLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                color: selected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
        onTap: (!canToggle || widget.coachToggleLoading)
            ? null
            : () {
                Feedback.forTap(context);
                Navigator.of(context).pop();
                widget.onCoachSelectionChanged!.call(
                  !option.isNoCoach,
                  option.coach,
                );
              },
      ),
    );
  }

  Widget _metaChip({
    required IconData icon,
    required String text,
    required bool highlighted,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: highlighted
            ? colorScheme.primary.withValues(alpha: 0.15)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: highlighted
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.labelMedium?.copyWith(
              color: highlighted
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final defAlignments = _pitchRowAlignments(
      _model.defLine.slotCount,
      _pitchDefY,
    );
    final isFormation424 =
        _model.defLine.slotCount == 4 &&
        _model.midLine.slotCount == 2 &&
        _model.fwdLine.slotCount == 4;
    final midAlignments = _pitchRowAlignments(
      _model.midLine.slotCount,
      _pitchMidY,
      halfSpan: isFormation424 ? 0.5 : 0.82,
    );
    final fwdAlignments = _pitchRowAlignments(
      _model.fwdLine.slotCount,
      _pitchFwdY,
    );
    final gkPlayer = _model.gk.slots.isEmpty ? null : _model.gk.slots[0];

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight.isFinite
                  ? constraints.maxHeight
                  : 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _headerRow(theme),
                const SizedBox(height: 14),
                AspectRatio(
                  aspectRatio: 0.72,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colorScheme.primary.withValues(alpha: 0.35),
                          const Color(0xFF1B4D32),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          const CustomPaint(painter: _PitchMarkingsPainter()),
                          Align(
                            alignment: const Alignment(0, -0.88),
                            child: _PitchPlayerBubble(
                              player: gkPlayer,
                              penalizedEmpty: _penalizedEmptyMeta(
                                line: LeagueSquadLine.porteros,
                                slotIndex0Based: 0,
                                player: gkPlayer,
                              ),
                              label: 'POR',
                              size: 46,
                              isCaptain: _isCaptain(gkPlayer),
                              onTap: () => _onTitularTap(
                                line: _model.gk,
                                slotIndex: 0,
                                demarcacion: 'portería',
                              ),
                              onLongPressPlayer: widget.onProfileLongPress,
                            ),
                          ),
                          Align(
                            alignment: const Alignment(0.93, -0.91),
                            child: _CoachPitchBubble(
                              coach: widget.entrenadorAsignado,
                              isActive: widget.entrenadorActivo,
                              isLoading: widget.coachToggleLoading,
                              formation: _effectiveFormationForCoachBubble(),
                              onTap: _onCoachBubbleTap,
                            ),
                          ),
                          ...defAlignments.asMap().entries.map(
                            (e) => Align(
                              alignment: e.value,
                              child: _PitchPlayerBubble(
                                player: _model.defLine.slots[e.key],
                                penalizedEmpty: _penalizedEmptyMeta(
                                  line: LeagueSquadLine.defensas,
                                  slotIndex0Based: e.key,
                                  player: _model.defLine.slots[e.key],
                                ),
                                label: 'DEF',
                                size: 44,
                                isCaptain: _isCaptain(
                                  _model.defLine.slots[e.key],
                                ),
                                onTap: () => _onTitularTap(
                                  line: _model.defLine,
                                  slotIndex: e.key,
                                  demarcacion: 'defensa',
                                ),
                                onLongPressPlayer: widget.onProfileLongPress,
                              ),
                            ),
                          ),
                          ...midAlignments.asMap().entries.map(
                            (e) => Align(
                              alignment: e.value,
                              child: _PitchPlayerBubble(
                                player: _model.midLine.slots[e.key],
                                penalizedEmpty: _penalizedEmptyMeta(
                                  line: LeagueSquadLine.mediocentros,
                                  slotIndex0Based: e.key,
                                  player: _model.midLine.slots[e.key],
                                ),
                                label: 'MC',
                                size: 44,
                                isCaptain: _isCaptain(
                                  _model.midLine.slots[e.key],
                                ),
                                onTap: () => _onTitularTap(
                                  line: _model.midLine,
                                  slotIndex: e.key,
                                  demarcacion: 'mediocentro',
                                ),
                                onLongPressPlayer: widget.onProfileLongPress,
                              ),
                            ),
                          ),
                          ...fwdAlignments.asMap().entries.map(
                            (e) => Align(
                              alignment: e.value,
                              child: _PitchPlayerBubble(
                                player: _model.fwdLine.slots[e.key],
                                penalizedEmpty: _penalizedEmptyMeta(
                                  line: LeagueSquadLine.delanteros,
                                  slotIndex0Based: e.key,
                                  player: _model.fwdLine.slots[e.key],
                                ),
                                label: 'DEL',
                                size: 44,
                                isCaptain: _isCaptain(
                                  _model.fwdLine.slots[e.key],
                                ),
                                onTap: () => _onTitularTap(
                                  line: _model.fwdLine,
                                  slotIndex: e.key,
                                  demarcacion: 'delantera',
                                ),
                                onLongPressPlayer: widget.onProfileLongPress,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _benchHorizontalBar(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CoachPickerOption {
  const _CoachPickerOption({
    required this.coach,
    required this.isNoCoach,
    required this.title,
    required this.formation,
    required this.teamId,
    required this.selected,
    this.imageUrl,
    this.bonusLabel,
    this.equippedBadge = false,
  });

  factory _CoachPickerOption.assignedCoach({
    required LeagueCoachAssignment coach,
    required String formation,
    required bool isSelected,
  }) {
    final bonus = coach.bonusPuntos > 0 ? '+${coach.bonusPuntos}' : null;
    final nombre = coach.entrenadorNombre?.trim() ?? '';
    final pila = coach.entrenadorPila?.trim() ?? '';
    final title = nombre.isNotEmpty
        ? nombre
        : (pila.isNotEmpty ? pila : 'Entrenador');
    return _CoachPickerOption(
      coach: coach,
      isNoCoach: false,
      title: title,
      formation: formation,
      teamId: coach.idEquipo,
      selected: isSelected,
      imageUrl: LeagueCoachPhoto.resolveUrl(
        idEntrenador: coach.idEntrenador,
        foto: coach.foto,
      ),
      bonusLabel: bonus,
      equippedBadge: coach.activo,
    );
  }

  final LeagueCoachAssignment? coach;
  final bool isNoCoach;
  final String title;
  final String formation;
  final int? teamId;
  final bool selected;
  final String? imageUrl;
  final String? bonusLabel;
  final bool equippedBadge;
}

class _CoachPitchBubble extends StatelessWidget {
  const _CoachPitchBubble({
    required this.coach,
    required this.isActive,
    required this.isLoading,
    required this.formation,
    required this.onTap,
  });

  final LeagueCoachAssignment? coach;
  final bool isActive;
  final bool isLoading;
  final String formation;
  final VoidCallback onTap;

  String get _pilaName {
    final pila = coach?.entrenadorPila?.trim() ?? '';
    if (pila.isNotEmpty) {
      final first = pila.split(RegExp(r'\s+')).first;
      if (first.isEmpty) {
        return '';
      }
      return first.length > 10 ? '${first.substring(0, 9)}…' : first;
    }
    final nombre = coach?.entrenadorNombre?.trim() ?? '';
    if (nombre.isNotEmpty) {
      final short = nombre.split(RegExp(r'\s+')).first;
      return short.length > 10 ? '${short.substring(0, 9)}…' : short;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
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
                        color: isActive
                            ? colorScheme.primary.withValues(alpha: 0.95)
                            : Colors.white.withValues(alpha: 0.5),
                        width: isActive ? 2.4 : 2,
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
                        color: isActive
                            ? colorScheme.primaryContainer.withValues(
                                alpha: 0.4,
                              )
                            : Colors.black.withValues(alpha: 0.25),
                      ),
                      child: _CoachAvatar(
                        imageUrl: () {
                          final c = coach;
                          if (c == null) {
                            return null;
                          }
                          return LeagueCoachPhoto.resolveUrl(
                            idEntrenador: c.idEntrenador,
                            foto: c.foto,
                          );
                        }(),
                        icon: coach == null
                            ? Icons.person_add_alt_1_rounded
                            : Icons.sports_soccer_rounded,
                        size: 44,
                        isActive: isActive,
                        teamId: coach?.idEquipo,
                      ),
                    ),
                  ),
                  if (isLoading)
                    Positioned(
                      right: -3,
                      bottom: -3,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: CircularProgressIndicator(
                            strokeWidth: 1.8,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (isActive && _pilaName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _pilaName,
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
        ),
      ),
    );
  }
}

class _CoachAvatar extends StatelessWidget {
  const _CoachAvatar({
    required this.imageUrl,
    required this.icon,
    required this.size,
    required this.isActive,
    required this.teamId,
  });

  final String? imageUrl;
  final IconData icon;
  final double size;
  final bool isActive;
  final int? teamId;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final safeUrl = imageUrl?.trim() ?? '';
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (safeUrl.isNotEmpty)
            CircleAvatar(
              radius: size / 2,
              backgroundImage: NetworkImage(safeUrl),
              onBackgroundImageError: (_, _) {},
            )
          else
            Center(
              child: Icon(
                icon,
                size: size * 0.45,
                color: isActive
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
              ),
            ),
          if ((teamId ?? 0) > 0)
            Positioned(
              right: -4,
              bottom: -4,
              child: LeagueTeamLogo(idEquipo: teamId!, size: 22),
            ),
        ],
      ),
    );
  }
}

class _PitchMarkingsPainter extends CustomPainter {
  const _PitchMarkingsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.006;

    final r = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, Radius.circular(size.shortestSide * 0.03)),
      line,
    );

    canvas.drawLine(
      Offset(0, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
      line,
    );

    final c = Offset(size.width * 0.5, size.height * 0.5);
    final rad = size.width * 0.18;
    canvas.drawCircle(c, rad, line);

    final boxW = size.width * 0.42;
    final boxH = size.height * 0.22;
    canvas.drawRect(
      Rect.fromLTWH((size.width - boxW) / 2, 0, boxW, boxH),
      line,
    );
    canvas.drawRect(
      Rect.fromLTWH((size.width - boxW) / 2, size.height - boxH, boxW, boxH),
      line,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PitchPlayerBubble extends StatelessWidget {
  const _PitchPlayerBubble({
    required this.player,
    this.penalizedEmpty,
    required this.label,
    required this.size,
    required this.onTap,
    this.onLongPressPlayer,
    this.isCaptain = false,
  });

  final LeagueSquadPlayer? player;
  final LeagueLineupEmptySlot? penalizedEmpty;
  final String label;
  final double size;
  final VoidCallback onTap;
  final void Function(LeagueSquadPlayer player)? onLongPressPlayer;
  final bool isCaptain;

  static String _penaltyVisualLabel(LeagueLineupEmptySlot e) {
    final p = e.penalizacion;
    if (p < 0) {
      return '$p';
    }
    if (p > 0) {
      return '-$p';
    }
    return '0';
  }

  static String _ratingLabel(LeagueSquadPlayer p) {
    final value = p.valoracion;
    if (value.isNaN || value.isInfinite) {
      return '—';
    }
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1).replaceAll('.', ',');
  }

  static String _name(LeagueSquadPlayer? p, String label) {
    if (p == null) {
      return label;
    }
    final nick = p.pila.trim();
    if (nick.isNotEmpty) {
      return nick.length > 10 ? '${nick.substring(0, 9)}…' : nick;
    }
    final n = p.nombre.trim();
    if (n.isEmpty) {
      return label;
    }
    final f = n.split(RegExp(r'\s+')).first;
    return f.length > 10 ? '${f.substring(0, 9)}…' : f;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final penalized =
        player == null && penalizedEmpty != null && penalizedEmpty!.emptySlot;
    final isProtected = player?.jugadorProtegido ?? false;
    const protectedColor = Color(0xFF64B5F6);

    if (kDebugMode && player != null) {
      debugPrint(
        '[starter-prob][pitch] idLigaJugador=${player!.idLigaJugador} '
        'probabilidadTitular=${player!.probabilidadTitular}',
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: player == null || onLongPressPlayer == null
            ? null
            : () => onLongPressPlayer!(player!),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
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
                        color: penalized
                            ? colorScheme.error.withValues(alpha: 0.65)
                            : isProtected
                                ? protectedColor.withValues(alpha: 0.85)
                                : Colors.white.withValues(alpha: 0.55),
                        width: isProtected ? 2.5 : 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isProtected
                              ? protectedColor.withValues(alpha: 0.35)
                              : Colors.black.withValues(alpha: 0.25),
                          blurRadius: isProtected ? 8 : 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: player != null
                        ? LeaguePlayerAvatar(
                            player: player!,
                            size: size,
                            circular: true,
                          )
                        : penalized
                        ? Container(
                            width: size,
                            height: size,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colorScheme.error.withValues(alpha: 0.22),
                            ),
                            child: Icon(
                              Icons.warning_amber_rounded,
                              color: colorScheme.error.withValues(alpha: 0.92),
                              size: size * 0.42,
                            ),
                          )
                        : Container(
                            width: size,
                            height: size,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withValues(alpha: 0.22),
                            ),
                            child: Icon(
                              Icons.add_rounded,
                              color: Colors.white.withValues(alpha: 0.75),
                              size: size * 0.38,
                            ),
                          ),
                  ),
                  if (isCaptain)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.tertiary,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        child: Text(
                          'C',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onTertiary,
                            fontWeight: FontWeight.w800,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),
                  if (isProtected)
                    Positioned(
                      left: -2,
                      top: -2,
                      child: Tooltip(
                        message: player!.proteccionHastaFinTemporada
                            ? 'Protegido temporada'
                            : player!.proteccionJornadaFin != null
                                ? 'Protegido hasta J${player!.proteccionJornadaFin}'
                                : 'Protegido',
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: protectedColor,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.9),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: protectedColor.withValues(alpha: 0.45),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.shield_rounded, size: 10, color: Colors.white),
                        ),
                      ),
                    ),
                  if (player != null &&
                      (leaguePlayerEstadoIsLesionado(
                            leaguePlayerEffectiveEstado(
                              estado: player!.estado,
                              estadoVisible: player!.estadoVisible,
                            ),
                          ) ||
                          leaguePlayerEstadoIsSancionado(
                            leaguePlayerEffectiveEstado(
                              estado: player!.estado,
                              estadoVisible: player!.estadoVisible,
                            ),
                          )))
                    Positioned(
                      left: -3,
                      bottom: -14,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (leaguePlayerEstadoIsLesionado(
                            leaguePlayerEffectiveEstado(
                              estado: player!.estado,
                              estadoVisible: player!.estadoVisible,
                            ),
                          ))
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.88),
                                  width: 1.1,
                                ),
                              ),
                              child: Icon(
                                LeaguePlayerAvailabilityIcons.injured,
                                size: 11,
                                color: colorScheme.onErrorContainer,
                              ),
                            ),
                          if (leaguePlayerEstadoIsLesionado(
                                leaguePlayerEffectiveEstado(
                                  estado: player!.estado,
                                  estadoVisible: player!.estadoVisible,
                                ),
                              ) &&
                              leaguePlayerEstadoIsSancionado(
                                leaguePlayerEffectiveEstado(
                                  estado: player!.estado,
                                  estadoVisible: player!.estadoVisible,
                                ),
                              ))
                            const SizedBox(width: 3),
                          if (leaguePlayerEstadoIsSancionado(
                            leaguePlayerEffectiveEstado(
                              estado: player!.estado,
                              estadoVisible: player!.estadoVisible,
                            ),
                          ))
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: colorScheme.tertiaryContainer,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.88),
                                  width: 1.1,
                                ),
                              ),
                              child: Icon(
                                LeaguePlayerAvailabilityIcons.sanctioned,
                                size: 11,
                                color: colorScheme.onTertiaryContainer,
                              ),
                            ),
                        ],
                      ),
                    )
                  else if (player != null &&
                      player!.probabilidadTitular != null)
                    Positioned(
                      left: -3,
                      bottom: -14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: starterTitularidadScaleBackgroundSolid(
                            player!.probabilidadTitular!,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.88),
                            width: 1.1,
                          ),
                        ),
                        child: Text(
                          '${player!.probabilidadTitular}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: starterTitularidadScaleOnBackground(
                              player!.probabilidadTitular!,
                            ),
                            fontWeight: FontWeight.w900,
                            fontSize: 9,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  if (player != null)
                    Positioned(
                      right: -3,
                      bottom: -14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.9),
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          _ratingLabel(player!),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 9,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  if (penalized)
                    Positioned(
                      right: -3,
                      bottom: -14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.error,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.88),
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          _penaltyVisualLabel(penalizedEmpty!),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onError,
                            fontWeight: FontWeight.w900,
                            fontSize: 9,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: penalized
                      ? colorScheme.error.withValues(alpha: 0.42)
                      : Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                  border: penalized
                      ? Border.all(
                          color: colorScheme.error.withValues(alpha: 0.55),
                        )
                      : null,
                ),
                child: Text(
                  penalized ? label : _name(player, label),
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
          ),
        ),
      ),
    );
  }
}
