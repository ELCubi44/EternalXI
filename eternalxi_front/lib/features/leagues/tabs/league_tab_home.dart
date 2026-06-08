import 'package:eternal_xi/app/localization/league_l10n.dart';
import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/data/models/league_calendar_models.dart';
import 'package:eternal_xi/data/models/league_home_feed.dart';
import 'package:eternal_xi/data/models/league_squad_player.dart';
import 'package:eternal_xi/data/models/league_team_standing_row.dart';
import 'package:eternal_xi/data/models/league_unavailable_player.dart';
import 'package:eternal_xi/data/services/leagues_api_service.dart';
import 'package:eternal_xi/features/leagues/navigation/league_inner_navigation.dart';
import 'package:eternal_xi/features/leagues/screens/league_day_matches_screen.dart';
import 'package:eternal_xi/features/leagues/screens/league_stats_list_screen.dart';
import 'package:eternal_xi/features/leagues/screens/league_team_standings_screen.dart';
import 'package:eternal_xi/features/leagues/shell/league_shell_data.dart';
import 'package:eternal_xi/features/leagues/utils/league_player_photo.dart';
import 'package:eternal_xi/features/leagues/utils/league_spanish_datetime.dart';
import 'package:eternal_xi/features/leagues/widgets/league_month_calendar.dart';
import 'package:eternal_xi/features/leagues/widgets/league_team_logo.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum _LeagueHomeSummarySection {
  standings,
  topScorers,
  topAssists,
  cleanSheets,
  injured,
  suspended,
}

/// Agrupa partidos por día calendario local usando la fecha real de cada partido
/// (`inicioEn` → [LeagueMatchSummary.fechaPartido]). No usa rangos de jornada.
Future<Map<DateTime, List<LeagueMatchSummary>>> _indexMatchesByKickoffDay({
  required LeaguesApiService api,
  required int leagueId,
  required int idUsuario,
  required List<LeagueRoundSummary> rounds,
}) async {
  DateTime dayOnly(DateTime d) {
    final l = d.toLocal();
    return DateTime(l.year, l.month, l.day);
  }

  bool shouldPreferKickoff({
    required LeagueMatchSummary incoming,
    required int detailJornada,
    required LeagueMatchSummary current,
  }) {
    final ij = incoming.idJornada ?? 0;
    final cj = current.idJornada ?? 0;
    final dj = detailJornada;
    final incAligned = ij > 0 && ij == dj;
    final curAligned = cj > 0 && cj == dj;
    if (incAligned != curAligned) {
      return incAligned;
    }
    final fi = incoming.fechaPartido!;
    final fc = current.fechaPartido!;
    return fi.isAfter(fc);
  }

  final validRounds = rounds.where((r) => r.id > 0).toList();
  if (validRounds.isEmpty) {
    return {};
  }

  final details = await Future.wait(
    validRounds.map((r) async {
      try {
        return await api.getLeagueRoundDetail(
          idLiga: leagueId,
          idJornada: r.id,
          idUsuario: idUsuario,
        );
      } catch (_) {
        return null;
      }
    }),
  );

  final bestByPartido = <int, LeagueMatchSummary>{};

  for (final detail in details) {
    if (detail == null) {
      continue;
    }
    final dj = detail.idJornada;
    for (final m in detail.partidos) {
      final fp = m.fechaPartido;
      if (fp == null) {
        continue;
      }
      final id = m.idPartido;
      if (id <= 0) {
        continue;
      }
      final enriched = m.copyWith(
        idJornada: dj > 0 ? dj : m.idJornada,
        numeroJornada: detail.numero > 0 ? detail.numero : m.numeroJornada,
      );
      final prev = bestByPartido[id];
      if (prev == null) {
        bestByPartido[id] = enriched;
        continue;
      }
      if (shouldPreferKickoff(
        incoming: enriched,
        detailJornada: dj,
        current: prev,
      )) {
        bestByPartido[id] = enriched;
      }
    }
  }

  final byDay = <DateTime, List<LeagueMatchSummary>>{};
  for (final m in bestByPartido.values) {
    final fp = m.fechaPartido;
    if (fp == null) {
      continue;
    }
    final key = dayOnly(fp);
    byDay.putIfAbsent(key, () => []).add(m);
  }

  for (final list in byDay.values) {
    list.sort((a, b) {
      final ta = a.fechaPartido;
      final tb = b.fechaPartido;
      if (ta == null && tb == null) {
        return 0;
      }
      if (ta == null) {
        return 1;
      }
      if (tb == null) {
        return -1;
      }
      return ta.compareTo(tb);
    });
  }

  return byDay;
}

class LeagueTabHome extends StatefulWidget {
  const LeagueTabHome({super.key});

  @override
  State<LeagueTabHome> createState() => _LeagueTabHomeState();
}

class _LeagueTabHomeState extends State<LeagueTabHome>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static DateTime _monthOnly(DateTime d) => DateTime(d.year, d.month, 1);

  static DateTime _dayOnly(DateTime d) {
    final l = d.toLocal();
    return DateTime(l.year, l.month, l.day);
  }

  late final PageController _monthPageController;
  late final PageController _feedPageController;
  late final PageController _unavailablePageController;
  late DateTime _anchorMonth;

  List<LeagueRoundSummary> _rounds = const [];
  List<LeagueTeamStandingRow> _teamStandings = const [];
  bool _teamStandingsLoading = true;
  String? _teamStandingsError;
  LeagueHomeFeed _homeFeed = const LeagueHomeFeed(
    noticiasLesiones: [],
    goleadores: [],
    asistidores: [],
    porteriasCero: [],
  );
  int _feedPage = 0;
  int _unavailablePage = 0;
  List<LeagueUnavailablePlayer> _unavailablePlayers = const [];
  bool _unavailableLoading = true;
  String? _unavailableError;

  /// Partidos agrupados por día de inicio real (`inicioEn`), misma fuente que marcas y tap.
  Map<DateTime, List<LeagueMatchSummary>> _matchesByDay = const {};
  DateTime? _selectedDay;
  bool _loading = true;
  String? _error;
  int? _scheduleLoadedForLeagueId;
  int? _handledRefreshGeneration;

  @override
  void initState() {
    super.initState();
    _anchorMonth = _monthOnly(DateTime.now());
    _monthPageController = PageController(initialPage: 500, keepPage: false);
    _feedPageController = PageController(initialPage: 0, keepPage: false);
    _unavailablePageController = PageController(
      initialPage: 0,
      keepPage: false,
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _loadSchedule(force: false),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shell = LeagueShellData.maybeOf(context);
    if (shell == null) {
      return;
    }
    final gen = shell.refreshGeneration;
    if (_handledRefreshGeneration == null) {
      _handledRefreshGeneration = gen;
      return;
    }
    if (gen != _handledRefreshGeneration) {
      _handledRefreshGeneration = gen;
      _loadSchedule(force: true);
    }
  }

  @override
  void dispose() {
    _monthPageController.dispose();
    _feedPageController.dispose();
    _unavailablePageController.dispose();
    super.dispose();
  }

  DateTime _monthForPage(int page) {
    final base =
        _anchorMonth.year * 12 + (_anchorMonth.month - 1) + (page - 500);
    return DateTime(base ~/ 12, (base % 12) + 1, 1);
  }

  /// Días con al menos un partido según fecha real de inicio (`inicioEn` de cada partido).
  Set<DateTime> _calendarActivityDays() => _matchesByDay.keys.toSet();

  /// [force] true: tirón manual de actualizar. false: carga inicial si aún no hay datos para esta liga.
  Future<void> _loadSchedule({required bool force}) async {
    final shell = LeagueShellData.maybeOf(context);
    if (shell == null) {
      setState(() {
        _loading = false;
        _error = context.leagueL10n.couldNotResolveLeagueContext;
      });
      return;
    }
    if (!force && _scheduleLoadedForLeagueId == shell.leagueId && !_loading) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<LeaguesApiService>();
      final rounds = await api.getLeagueRounds(
        idLiga: shell.leagueId,
        idUsuario: shell.idUsuario,
      );
      final asyncBundle = await Future.wait<dynamic>([
        _indexMatchesByKickoffDay(
          api: api,
          leagueId: shell.leagueId,
          idUsuario: shell.idUsuario,
          rounds: rounds,
        ),
        api.getHomeFeed(idLiga: shell.leagueId, idUsuario: shell.idUsuario),
      ]);
      List<LeagueTeamStandingRow> teamRows = const [];
      String? teamError;
      List<LeagueUnavailablePlayer> unavailableRows = const [];
      String? unavailableError;
      try {
        teamRows = await api.getTeamStandings(
          idLiga: shell.leagueId,
          idUsuario: shell.idUsuario,
        );
      } catch (e) {
        teamError = e.toString().replaceFirst('Exception: ', '');
      }
      try {
        unavailableRows = await api.fetchUnavailablePlayers(
          leagueId: shell.leagueId,
          userId: shell.idUsuario,
        );
      } catch (e) {
        unavailableError = e.toString().replaceFirst('Exception: ', '');
      }
      final byDay = asyncBundle[0] as Map<DateTime, List<LeagueMatchSummary>>;
      final homeFeed = asyncBundle[1] as LeagueHomeFeed;
      if (!mounted) {
        return;
      }
      setState(() {
        _rounds = rounds;
        _matchesByDay = byDay;
        _homeFeed = homeFeed;
        _teamStandings = teamRows;
        _teamStandingsError = teamError;
        _teamStandingsLoading = false;
        _unavailablePlayers = unavailableRows;
        _unavailableError = unavailableError;
        _unavailableLoading = false;
        _loading = false;
        _scheduleLoadedForLeagueId = shell.leagueId;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _rounds = const [];
        _matchesByDay = const {};
        _homeFeed = const LeagueHomeFeed(
          noticiasLesiones: [],
          goleadores: [],
          asistidores: [],
          porteriasCero: [],
        );
        _teamStandings = const [];
        _teamStandingsError = null;
        _teamStandingsLoading = false;
        _unavailablePlayers = const [];
        _unavailableError = null;
        _unavailableLoading = false;
        _loading = false;
        _scheduleLoadedForLeagueId = shell.leagueId;
      });
    }
  }

  Future<void> _onDaySelected(BuildContext context, DateTime day) async {
    final shell = LeagueShellData.maybeOf(context);
    if (shell == null) {
      return;
    }
    setState(() => _selectedDay = day);

    final targetDay = _dayOnly(day);
    final merged = List<LeagueMatchSummary>.from(
      _matchesByDay[targetDay] ?? const [],
    );

    if (!context.mounted) {
      return;
    }
    if (merged.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.leagueL10n.noMatchesScheduled)),
      );
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LeagueDayMatchesScreen(
          leagueId: shell.leagueId,
          idUsuario: shell.idUsuario,
          day: day,
          matches: merged,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    final today = _dayOnly(DateTime.now());
    setState(() {
      _selectedDay = today;
      _anchorMonth = _monthOnly(today);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_monthPageController.hasClients) {
        return;
      }
      _monthPageController.jumpToPage(500);
    });
    await _loadSchedule(force: true);
  }

  List<LeagueUnavailablePlayer> _unavailableSorted({required bool injured}) {
    final list = _unavailablePlayers
        .where((n) => injured ? n.isInjured : n.isSuspended)
        .toList(growable: false);
    final sorted = [...list];
    sorted.sort((a, b) {
      final ad = a.unavailableUntil;
      final bd = b.unavailableUntil;
      if (ad == null && bd == null) {
        return 0;
      }
      if (ad == null) {
        return 1;
      }
      if (bd == null) {
        return -1;
      }
      return ad.compareTo(bd);
    });
    return sorted;
  }

  void _onSummarySeeMore(_LeagueHomeSummarySection section) {
    final shell = LeagueShellData.maybeOf(context);
    final ll = context.leagueL10n;
    if (section == _LeagueHomeSummarySection.standings) {
      if (shell == null) {
        return;
      }
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => LeagueTeamStandingsScreen(
            leagueId: shell.leagueId,
            idUsuario: shell.idUsuario,
          ),
        ),
      );
      return;
    }
    switch (section) {
      case _LeagueHomeSummarySection.topScorers:
        _openStatsList(
          title: ll.topScorers,
          subtitle: ll.topScorersSubtitle,
          items: _topPlayersToItems(_homeFeed.goleadores, maxItems: 10),
        );
        break;
      case _LeagueHomeSummarySection.topAssists:
        _openStatsList(
          title: ll.topAssists,
          subtitle: ll.topAssistsSubtitle,
          items: _topPlayersToItems(_homeFeed.asistidores, maxItems: 10),
        );
        break;
      case _LeagueHomeSummarySection.cleanSheets:
        _openStatsList(
          title: ll.cleanSheets,
          subtitle: ll.cleanSheetsSubtitle,
          items: _topPlayersToItems(_homeFeed.porteriasCero, maxItems: 10),
        );
        break;
      case _LeagueHomeSummarySection.injured:
        _openStatsList(
          title: ll.injuredPlayers,
          subtitle: ll.injuredPlayersSubtitle,
          items: _unavailableToItems(_unavailableSorted(injured: true)),
        );
        break;
      case _LeagueHomeSummarySection.suspended:
        _openStatsList(
          title: ll.suspendedPlayers,
          subtitle: ll.suspendedPlayersSubtitle,
          items: _unavailableToItems(_unavailableSorted(injured: false)),
        );
        break;
      case _LeagueHomeSummarySection.standings:
        break;
    }
  }

  void _openStatsList({
    required String title,
    required String subtitle,
    required List<LeagueStatsListItem> items,
  }) {
    final ll = context.leagueL10n;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LeagueStatsListScreen(
          title: title,
          subtitle: subtitle,
          items: items,
          emptyText: ll.noStatsYet,
        ),
      ),
    );
  }

  List<LeagueStatsListItem> _topPlayersToItems(
    List<LeagueHomeTopPlayer> rows, {
    int? maxItems,
  }) {
    final source = maxItems == null
        ? rows
        : rows.take(maxItems).toList(growable: false);
    return source
        .asMap()
        .entries
        .map((entry) {
          final i = entry.key;
          final row = entry.value;
          final team = row.nombreEquipo.trim().isEmpty
              ? '—'
              : row.nombreEquipo.trim();
          return LeagueStatsListItem(
            title: '${i + 1}. ${row.displayName()}',
            subtitle: team,
            trailing: '${row.total}',
            leading: _MiniPlayerPhoto(
              idJugador: row.idJugador,
              fotoJugador: row.fotoJugador,
            ),
            onTap: () => _openTopPlayerDetail(row),
          );
        })
        .toList(growable: false);
  }

  List<LeagueStatsListItem> _unavailableToItems(
    List<LeagueUnavailablePlayer> rows,
  ) {
    return rows
        .map((row) {
          final team = row.nombreEquipo.trim().isEmpty
              ? '—'
              : row.nombreEquipo.trim();
          return LeagueStatsListItem(
            title: row.displayName,
            subtitle: '$team · ${_availabilityText(row)}',
            trailing: '',
            leading: _MiniPlayerPhoto(
              idJugador: row.idJugador,
              fotoJugador: row.fotoJugador ?? '',
            ),
            onTap: () => _openUnavailablePlayerDetail(row),
          );
        })
        .toList(growable: false);
  }

  void _openTopPlayerDetail(LeagueHomeTopPlayer row) {
    final shell = LeagueShellData.maybeOf(context);
    if (shell == null) {
      return;
    }
    final player = LeagueSquadPlayer(
      idLigaJugador: row.idLigaJugador,
      idJugador: row.idJugador,
      nombre: row.nombre,
      pila: row.pila,
      posicion: row.posicion,
      valoracion: row.valoracion,
      idEquipo: row.idEquipo,
      nombreEquipo: row.nombreEquipo,
      estado: '',
      cansancio: 0,
      valor: 0,
      fotoJugador: row.fotoJugador,
      fotoEquipo: '',
      enPoolMercado: false,
      propietarioNick: '',
      idUsuarioDueno: 0,
      puntosTotales: 0,
      probabilidadTitular: row.probabilidadTitular,
      motivoTitularidad: row.motivoTitularidad,
      idPartidoProbabilidad: row.idPartidoProbabilidad,
      calculadoEnProbabilidad: row.calculadoEnProbabilidad,
    );
    LeagueInnerNavigation.openPlayerProfile(
      context: context,
      player: player,
      leagueId: shell.leagueId,
      idLigaJugador: row.idLigaJugador,
      idUsuario: shell.idUsuario,
      isOwnPlayerHint: null,
      isMarketPlayerHint: null,
    );
  }

  void _openUnavailablePlayerDetail(LeagueUnavailablePlayer row) {
    final shell = LeagueShellData.maybeOf(context);
    if (shell == null) {
      return;
    }
    final player = LeagueSquadPlayer(
      idLigaJugador: row.idLigaJugador,
      idJugador: row.idJugador,
      nombre: row.nombre,
      pila: row.pila ?? '',
      posicion: '',
      valoracion: 0,
      idEquipo: row.idEquipo,
      nombreEquipo: row.nombreEquipo,
      estado: '',
      cansancio: 0,
      valor: 0,
      fotoJugador: row.fotoJugador ?? '',
      fotoEquipo: '',
      enPoolMercado: false,
      propietarioNick: '',
      idUsuarioDueno: 0,
      puntosTotales: 0,
    );
    LeagueInnerNavigation.openPlayerProfile(
      context: context,
      player: player,
      leagueId: shell.leagueId,
      idLigaJugador: row.idLigaJugador,
      idUsuario: shell.idUsuario,
      isOwnPlayerHint: null,
      isMarketPlayerHint: null,
    );
  }

  String _availabilityText(LeagueUnavailablePlayer row) {
    final ll = context.leagueL10n;
    final txt = row.textoDisponibilidad.trim();
    if (txt.isNotEmpty) {
      return txt;
    }
    if (row.numeroJornadaDisponible != null &&
        row.numeroJornadaDisponible! > 0) {
      return ll.availableForMatchday(row.numeroJornadaDisponible!);
    }
    if (row.disponibleDesde != null) {
      return ll.availableOn(
        LeagueSpanishDateTime.formatDateNumeric(row.disponibleDesde),
      );
    }
    return ll.noReturnDate;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ll = context.leagueL10n;
    super.build(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final shell = LeagueShellData.maybeOf(context);
    final activityDays = _calendarActivityDays();
    final summaryPages = <Widget>[
      _LeagueHomeCompactCard(
        title: ll.teamStandingsTitle,
        dense: true,
        onSeeMore: () => _onSummarySeeMore(_LeagueHomeSummarySection.standings),
        child: _CompactTeamStandingsTable(
          rows: _teamStandings,
          loading: _teamStandingsLoading,
          error: _teamStandingsError,
          onRetry: () => _loadSchedule(force: true),
        ),
      ),
      _LeagueHomeCompactCard(
        title: ll.topScorers,
        onSeeMore: () => _onSummarySeeMore(_LeagueHomeSummarySection.topScorers),
        child: _CompactTopPlayersTable(
          rows: _homeFeed.goleadores,
          valueLabel: ll.statGoals,
          onTapPlayer: _openTopPlayerDetail,
        ),
      ),
      _LeagueHomeCompactCard(
        title: ll.topAssists,
        onSeeMore: () => _onSummarySeeMore(_LeagueHomeSummarySection.topAssists),
        child: _CompactTopPlayersTable(
          rows: _homeFeed.asistidores,
          valueLabel: ll.assistsShort,
          onTapPlayer: _openTopPlayerDetail,
        ),
      ),
      _LeagueHomeCompactCard(
        title: ll.cleanSheets,
        onSeeMore: () => _onSummarySeeMore(_LeagueHomeSummarySection.cleanSheets),
        child: _CompactTopPlayersTable(
          rows: _homeFeed.porteriasCero,
          valueLabel: ll.cleanSheetsShort,
          onTapPlayer: _openTopPlayerDetail,
        ),
      ),
    ];
    final pagesCount = summaryPages.length;
    final safeFeedPage = _feedPage.clamp(0, pagesCount - 1);

    return RefreshIndicator(
      onRefresh: () async {
        final s = LeagueShellData.maybeOf(context);
        if (s != null) {
          await s.reload();
        }
      },
      child: CustomScrollView(
        key: const PageStorageKey<String>('league_tab_home'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            sliver: SliverToBoxAdapter(
              child: Text(
                l10n.home,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          else ...[
            if (_error != null)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: Card(
                    elevation: 0,
                    color: colorScheme.errorContainer.withValues(alpha: 0.35),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        _error!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 420,
                child: PageView.builder(
                  controller: _monthPageController,
                  itemBuilder: (context, page) {
                    final month = _monthForPage(page);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: LeagueMonthCalendar(
                        visibleMonth: month,
                        daysWithActivity: activityDays,
                        selectedDay: _selectedDay,
                        onSelectDay: (d) => _onDaySelected(context, d),
                      ),
                    );
                  },
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  ll.leagueSummaryTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  height: 280,
                  child: PageView.builder(
                    controller: _feedPageController,
                    itemCount: pagesCount,
                    onPageChanged: (index) => setState(() => _feedPage = index),
                    itemBuilder: (context, index) => summaryPages[index],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(pagesCount, (index) {
                    final selected = index == safeFeedPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: selected ? 18 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: selected
                            ? colorScheme.primary
                            : colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    );
                  }),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    SizedBox(
                      height: 264,
                      child: PageView(
                        controller: _unavailablePageController,
                        onPageChanged: (index) =>
                            setState(() => _unavailablePage = index),
                        children: [
                          _LeagueHomeCompactCard(
                            title: ll.injuredPlayers,
                            onSeeMore: () =>
                                _onSummarySeeMore(_LeagueHomeSummarySection.injured),
                            child: _CompactUnavailableListTable(
                              rows: _unavailableSorted(injured: true),
                              loading: _unavailableLoading,
                              error: _unavailableError,
                              onRetry: () => _loadSchedule(force: true),
                              resolveAvailabilityText: _availabilityText,
                              emptyText: ll.noInjuredCurrently,
                              onTapPlayer: _openUnavailablePlayerDetail,
                            ),
                          ),
                          _LeagueHomeCompactCard(
                            title: ll.suspendedPlayers,
                            onSeeMore: () => _onSummarySeeMore(
                              _LeagueHomeSummarySection.suspended,
                            ),
                            child: _CompactUnavailableListTable(
                              rows: _unavailableSorted(injured: false),
                              loading: _unavailableLoading,
                              error: _unavailableError,
                              onRetry: () => _loadSchedule(force: true),
                              resolveAvailabilityText: _availabilityText,
                              emptyText: ll.noSuspendedCurrently,
                              onTapPlayer: _openUnavailablePlayerDetail,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(2, (index) {
                        final selected = index == _unavailablePage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: selected ? 18 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: selected
                                ? colorScheme.primary
                                : colorScheme.outlineVariant.withValues(
                                    alpha: 0.5,
                                  ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_rounds.isEmpty && _error == null)
                      Text(
                        ll.noRoundsInResponse,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      )
                    else if (activityDays.isEmpty && _rounds.isNotEmpty)
                      Text(
                        ll.noRoundsWithMatches,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LeagueHomeCompactCard extends StatelessWidget {
  const _LeagueHomeCompactCard({
    required this.title,
    required this.child,
    this.onSeeMore,
    this.dense = false,
  });

  final String title;
  final Widget child;
  final VoidCallback? onSeeMore;

  /// Menos padding y cabecera más compacta (p. ej. clasificación con 5 equipos visibles).
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final titleStyle = dense
        ? theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)
        : theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800);
    final pad = dense
        ? const EdgeInsets.fromLTRB(10, 8, 10, 6)
        : const EdgeInsets.fromLTRB(14, 14, 14, 12);
    final gapAfterTitle = dense ? 4.0 : 8.0;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: pad,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final hasBoundedHeight = constraints.hasBoundedHeight;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: hasBoundedHeight
                  ? MainAxisSize.max
                  : MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: titleStyle,
                      ),
                    ),
                    TextButton(
                      style: dense
                          ? TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            )
                          : null,
                      onPressed: onSeeMore,
                      child: Text(context.l10n.continueText),
                    ),
                  ],
                ),
                SizedBox(height: gapAfterTitle),
                if (hasBoundedHeight) Expanded(child: child) else child,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CompactTeamStandingsTable extends StatelessWidget {
  const _CompactTeamStandingsTable({
    required this.rows,
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  final List<LeagueTeamStandingRow> rows;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        ),
      );
    }

    if (error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            error!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(context.l10n.retry),
            ),
          ),
        ],
      );
    }

    if (rows.isEmpty) {
      return _CompactEmptyState(text: context.leagueL10n.noTeamStandingsYet);
    }

    final preview = rows.take(5).toList(growable: false);

    return ListView.separated(
      itemCount: preview.length + 1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, _) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        if (index == 0) {
          return const _TeamTableHeader();
        }
        return _TeamTableRow(row: preview[index - 1]);
      },
    );
  }
}

class _TeamTableHeader extends StatelessWidget {
  const _TeamTableHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ll = context.leagueL10n;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
        child: Row(
          children: [
            const _TeamHeaderCell(value: '#', width: 20),
            const SizedBox(width: 4),
            Expanded(
              child: _TeamHeaderCell(
                value: ll.teamColumn,
                alignLeft: true,
              ),
            ),
            const SizedBox(width: 4),
            _TeamHeaderCell(value: 'PTS', width: 36, bold: true),
          ],
        ),
      ),
    );
  }
}

class _TeamTableRow extends StatelessWidget {
  const _TeamTableRow({required this.row});

  final LeagueTeamStandingRow row;

  @override
  Widget build(BuildContext context) {
    final teamName = row.nombreEquipo.trim();
    final theme = Theme.of(context);
    final ll = context.leagueL10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            child: Text(
              '${row.posicion}',
              textAlign: TextAlign.right,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Row(
              children: [
                if (row.idEquipo > 0)
                  Semantics(
                    button: true,
                    label: teamName.isEmpty
                        ? ll.seeTeam
                        : ll.seeTeamColon(teamName),
                    child: Tooltip(
                      message: teamName.isEmpty
                          ? ll.seeTeam
                          : ll.seeTeamNamed(teamName),
                      child: Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => LeagueInnerNavigation.openCatalogTeamSquad(
                            context: context,
                            idEquipo: row.idEquipo,
                            nombreEquipo:
                                teamName.isEmpty ? null : teamName,
                            fotoEquipo: row.resolvedFotoEquipoUrl(),
                            idLiga: LeagueShellData.maybeOf(context)?.leagueId,
                            idUsuario: LeagueShellData.maybeOf(context)?.idUsuario,
                          ),
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: Center(
                              child: LeagueTeamLogo(
                                idEquipo: row.idEquipo,
                                size: 20,
                                networkImageUrl: row.resolvedFotoEquipoUrl(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: Center(
                      child: LeagueTeamLogo(
                        idEquipo: row.idEquipo,
                        size: 20,
                        networkImageUrl: row.resolvedFotoEquipoUrl(),
                      ),
                    ),
                  ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    row.nombreEquipo.trim().isEmpty
                        ? '—'
                        : row.nombreEquipo.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          _TeamStatCell(value: '${row.puntos}', width: 36, bold: true),
        ],
      ),
    );
  }
}

class _TeamHeaderCell extends StatelessWidget {
  const _TeamHeaderCell({
    required this.value,
    this.width,
    this.alignLeft = false,
    this.bold = false,
  });

  final String value;
  final double? width;
  final bool alignLeft;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      value,
      textAlign: alignLeft ? TextAlign.left : TextAlign.right,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
      ),
    );
    if (width == null) {
      return text;
    }
    return SizedBox(width: width, child: text);
  }
}

class _TeamStatCell extends StatelessWidget {
  const _TeamStatCell({
    required this.value,
    required this.width,
    this.bold = false,
  });

  final String value;
  final double width;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        value,
        textAlign: TextAlign.right,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          height: 1.2,
        ),
      ),
    );
  }
}

class _CompactTopPlayersTable extends StatelessWidget {
  const _CompactTopPlayersTable({
    required this.rows,
    required this.valueLabel,
    required this.onTapPlayer,
  });

  final List<LeagueHomeTopPlayer> rows;
  final String valueLabel;
  final void Function(LeagueHomeTopPlayer row) onTapPlayer;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return _CompactEmptyState(text: context.leagueL10n.noStatsYet);
    }
    final top = rows.take(4).toList(growable: false);
    final theme = Theme.of(context);
    return ListView.separated(
      itemCount: top.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final row = top[index];
        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onTapPlayer(row),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
            child: Row(
              children: [
                _RankChip(rank: index + 1),
                const SizedBox(width: 8),
                _MiniPlayerPhoto(
                  idJugador: row.idJugador,
                  fotoJugador: row.fotoJugador,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.displayName(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        row.nombreEquipo.trim().isEmpty
                            ? '—'
                            : row.nombreEquipo.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${row.total}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CompactUnavailableListTable extends StatelessWidget {
  const _CompactUnavailableListTable({
    required this.rows,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.resolveAvailabilityText,
    required this.emptyText,
    required this.onTapPlayer,
  });

  final List<LeagueUnavailablePlayer> rows;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final String Function(LeagueUnavailablePlayer row) resolveAvailabilityText;
  final String emptyText;
  final void Function(LeagueUnavailablePlayer row) onTapPlayer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        ),
      );
    }
    if (error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            error!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(context.l10n.retry),
            ),
          ),
        ],
      );
    }
    final top = rows.take(4).toList(growable: false);
    if (top.isEmpty) {
      return _CompactEmptyState(text: emptyText);
    }
    return ListView.separated(
      itemCount: top.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final row = top[index];
        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onTapPlayer(row),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MiniPlayerPhoto(
                  idJugador: row.idJugador,
                  fotoJugador: row.fotoJugador ?? '',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        row.nombreEquipo.trim().isEmpty
                            ? '—'
                            : row.nombreEquipo.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 124,
                  child: Text(
                    resolveAvailabilityText(row),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MiniPlayerPhoto extends StatelessWidget {
  const _MiniPlayerPhoto({required this.idJugador, required this.fotoJugador});

  final int idJugador;
  final String fotoJugador;

  @override
  Widget build(BuildContext context) {
    final uri = LeaguePlayerPhoto.resolveNightMarket(
      idJugador: idJugador,
      fotoJugador: fotoJugador,
    );
    if (uri == null) {
      return const _CircleFallback(icon: Icons.person_outline_rounded);
    }
    return ClipOval(
      child: Image.network(
        uri.toString(),
        width: 28,
        height: 28,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            const _CircleFallback(icon: Icons.person_outline_rounded),
      ),
    );
  }
}

class _CircleFallback extends StatelessWidget {
  const _CircleFallback({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surfaceContainerHighest,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: 16,
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
      ),
    );
  }
}

class _RankChip extends StatelessWidget {
  const _RankChip({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: 30,
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: colorScheme.primaryContainer.withValues(alpha: 0.7),
      ),
      alignment: Alignment.center,
      child: Text(
        '$rank',
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _CompactEmptyState extends StatelessWidget {
  const _CompactEmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
