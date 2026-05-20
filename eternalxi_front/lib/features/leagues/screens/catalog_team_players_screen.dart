import 'package:eternal_xi/core/network/api_exception.dart';
import 'package:eternal_xi/core/utils/league_money_format.dart';
import 'package:eternal_xi/data/models/catalog_team_coach.dart';
import 'package:eternal_xi/data/models/catalog_team_player.dart';
import 'package:eternal_xi/data/models/catalog_team_squad.dart';
import 'package:eternal_xi/data/models/catalog_team_summary.dart';
import 'package:eternal_xi/data/models/league_squad_player.dart';
import 'package:eternal_xi/data/services/leagues_api_service.dart';
import 'package:eternal_xi/features/leagues/navigation/league_inner_navigation.dart';
import 'package:eternal_xi/features/leagues/widgets/league_player_avatar.dart';
import 'package:eternal_xi/features/leagues/shell/league_shell_data.dart';
import 'package:eternal_xi/features/leagues/widgets/league_team_logo.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Plantilla del catálogo (`GET /catalog/teams/{idEquipo}/squad`): equipo, entrenador y jugadores.
class CatalogTeamPlayersScreen extends StatefulWidget {
  const CatalogTeamPlayersScreen({
    super.key,
    required this.idEquipo,
    this.nombreEquipo,
    this.fotoEquipo,
    this.seasonId,
    this.idLiga,
    this.idUsuario,
  });

  final int idEquipo;
  final String? nombreEquipo;
  final String? fotoEquipo;
  final int? seasonId;
  final int? idLiga;
  final int? idUsuario;

  @override
  State<CatalogTeamPlayersScreen> createState() =>
      _CatalogTeamPlayersScreenState();
}

class _CatalogTeamPlayersScreenState extends State<CatalogTeamPlayersScreen> {
  bool _loading = true;
  String? _error;
  CatalogTeamSquad? _squad;

  String _humanError(Object e) {
    if (e is ApiException) {
      return e.message;
    }
    return e.toString().replaceFirst('Exception: ', '');
  }

  int? _resolvedLeagueId() {
    final shell = LeagueShellData.maybeOf(context);
    return widget.idLiga ?? shell?.leagueId;
  }

  int? _resolvedUserId() {
    final shell = LeagueShellData.maybeOf(context);
    return widget.idUsuario ?? shell?.idUsuario;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<LeaguesApiService>();
      final resolvedLeagueId = _resolvedLeagueId();
      final squad = await api.getCatalogTeamSquad(
        idEquipo: widget.idEquipo,
        seasonId: widget.seasonId,
        idLiga: resolvedLeagueId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _squad = squad;
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  String _title(CatalogTeamSummary? equipo) {
    final fromApi = equipo?.nombre.trim() ?? '';
    if (fromApi.isNotEmpty) {
      return fromApi;
    }
    final hint = (widget.nombreEquipo ?? '').trim();
    return hint.isEmpty ? 'Equipo' : hint;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final equipo = _squad?.equipo;
    final title = _title(equipo);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
          children: [
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              _CatalogErrorState(error: _error!, onRetry: _load)
            else if (_squad == null)
              const SizedBox.shrink()
            else ...[
              _CatalogTeamHeaderBar(
                equipo: _squad!.equipo,
                idEquipoLogo: widget.idEquipo,
                fallbackNombre: widget.nombreEquipo,
                fallbackFotoEquipo: widget.fotoEquipo,
              ),
              const SizedBox(height: 14),
              if (_squad!.entrenador != null)
                _CatalogCoachCard(coach: _squad!.entrenador!)
              else
                const _CatalogNoCoachCard(),
              const SizedBox(height: 18),
              Text(
                'Plantilla',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              if (_squad!.jugadores.isEmpty)
                const _CatalogEmptyState()
              else
                ..._groupedRows(context, _squad!.jugadores),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _groupedRows(BuildContext context, List<CatalogTeamPlayer> players) {
    final leagueId = _resolvedLeagueId();
    final userId = _resolvedUserId();
    final canOpenFantasy = (leagueId ?? 0) > 0 && (userId ?? 0) > 0;
    final showLeagueValue = (leagueId ?? 0) > 0;
    final groups = <String, List<CatalogTeamPlayer>>{
      'POR': [],
      'DEF': [],
      'MED': [],
      'DEL': [],
      'OTR': [],
    };
    for (final p in players) {
      final key = _positionGroup(p.posicion);
      groups[key]!.add(p);
    }
    for (final list in groups.values) {
      list.sort((a, b) {
        final byDorsal = a.dorsal.compareTo(b.dorsal);
        if (byDorsal != 0) {
          return byDorsal;
        }
        return b.valoracion.compareTo(a.valoracion);
      });
    }
    final widgets = <Widget>[];
    for (final entry in groups.entries) {
      if (entry.value.isEmpty) {
        continue;
      }
      widgets.add(_CatalogPositionHeader(label: entry.key));
      widgets.add(const SizedBox(height: 6));
      widgets.addAll(
        entry.value.map(
          (p) => _CatalogPlayerRow(
            player: p,
            showLeagueValue: showLeagueValue,
            onTap: (canOpenFantasy && p.idLigaJugador > 0)
                ? () => _openFantasyPlayer(context, p)
                : null,
          ),
        ),
      );
      widgets.add(const SizedBox(height: 10));
    }
    return widgets;
  }

  String _positionGroup(String raw) {
    final p = raw.trim().toUpperCase();
    if (p.startsWith('POR')) {
      return 'POR';
    }
    if (p.startsWith('DEF')) {
      return 'DEF';
    }
    if (p.startsWith('MED') || p.startsWith('MC')) {
      return 'MED';
    }
    if (p.startsWith('DEL')) {
      return 'DEL';
    }
    return 'OTR';
  }

  void _openFantasyPlayer(BuildContext context, CatalogTeamPlayer p) {
    final idLiga = _resolvedLeagueId();
    final idUsuario = _resolvedUserId();
    if ((idLiga ?? 0) <= 0 || (idUsuario ?? 0) <= 0 || p.idLigaJugador <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir el detalle fantasy para este jugador.'),
        ),
      );
      return;
    }
    final player = LeagueSquadPlayer(
      idLigaJugador: p.idLigaJugador,
      idJugador: p.idJugador,
      nombre: p.nombre,
      pila: p.pila,
      posicion: p.posicion,
      valoracion: p.valoracion,
      idEquipo: p.idEquipo,
      nombreEquipo: p.nombreEquipo,
      estado: p.estado ?? '',
      cansancio: 0,
      valor: p.valor,
      fotoJugador: p.fotoJugador,
      fotoEquipo: p.fotoEquipo,
      enPoolMercado: false,
      propietarioNick: '',
      idUsuarioDueno: p.idUsuarioDueno ?? 0,
      puntosTotales: 0,
    );
    LeagueInnerNavigation.openPlayerProfile(
      context: context,
      player: player,
      leagueId: idLiga,
      idLigaJugador: p.idLigaJugador,
      idUsuario: idUsuario,
      isOwnPlayerHint: null,
      isMarketPlayerHint: null,
      isNightMarketPlayerHint: null,
    );
  }
}

class _CatalogTeamHeaderBar extends StatelessWidget {
  const _CatalogTeamHeaderBar({
    required this.equipo,
    required this.idEquipoLogo,
    this.fallbackNombre,
    this.fallbackFotoEquipo,
  });

  final CatalogTeamSummary equipo;
  final int idEquipoLogo;
  final String? fallbackNombre;
  final String? fallbackFotoEquipo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final nombre = equipo.nombre.trim().isNotEmpty
        ? equipo.nombre.trim()
        : (fallbackNombre?.trim().isNotEmpty ?? false)
        ? fallbackNombre!.trim()
        : 'Equipo';
    final logoUrl = equipo.resolvedFotoUrl() ??
        CatalogTeamPlayer.resolvedCatalogAssetUrl(fallbackFotoEquipo);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.55),
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
          ],
        ),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          LeagueTeamLogo(
            idEquipo: idEquipoLogo,
            size: 56,
            networkImageUrl: logoUrl,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogCoachCard extends StatelessWidget {
  const _CatalogCoachCard({required this.coach});

  final CatalogTeamCoach coach;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _CoachAvatar(url: coach.resolvedFotoUrl(), colorScheme: colorScheme),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                coach.displayNombreCompleto(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
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
    const size = 48.0;
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
          Icons.sports_soccer_rounded,
          size: 26,
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
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return Center(
              child: SizedBox(
                width: size * 0.42,
                height: size * 0.42,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              ),
            );
          },
          errorBuilder: (_, _, _) => Container(
            color: colorScheme.secondaryContainer.withValues(alpha: 0.65),
            alignment: Alignment.center,
            child: Icon(
              Icons.sports_soccer_rounded,
              size: 26,
              color: colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}

class _CatalogNoCoachCard extends StatelessWidget {
  const _CatalogNoCoachCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.person_off_outlined, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Sin entrenador asignado',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogPlayerRow extends StatelessWidget {
  const _CatalogPlayerRow({
    required this.player,
    required this.showLeagueValue,
    this.onTap,
  });

  final CatalogTeamPlayer player;
  final bool showLeagueValue;
  final VoidCallback? onTap;

  static String _rating(double v) {
    if (v.isNaN || v.isInfinite) {
      return '—';
    }
    if (v == v.roundToDouble()) {
      return v.toInt().toString();
    }
    return v.toStringAsFixed(1).replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final showValorMercado = showLeagueValue && player.valor > 0;

    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 28,
            alignment: Alignment.center,
            child: Text(
              player.dorsal > 0 ? '${player.dorsal}' : '—',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 6),
          _CatalogPlayerAvatar(player: player, size: 46),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.displayName(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (showValorMercado)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      LeagueMoneyFormat.money(player.valor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _rating(player.valoracion),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: onTap == null
          ? child
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: child,
            ),
    );
  }
}

class _CatalogPositionHeader extends StatelessWidget {
  const _CatalogPositionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _CatalogPlayerAvatar extends StatelessWidget {
  const _CatalogPlayerAvatar({required this.player, required this.size});

  final CatalogTeamPlayer player;
  final double size;

  @override
  Widget build(BuildContext context) {
    final proxy = LeagueSquadPlayer(
      idLigaJugador: player.idLigaJugador,
      idJugador: player.idJugador,
      nombre: player.nombre,
      pila: player.pila,
      posicion: player.posicion,
      valoracion: player.valoracion,
      idEquipo: player.idEquipo,
      nombreEquipo: player.nombreEquipo,
      estado: '',
      cansancio: 0,
      valor: player.valor,
      fotoJugador: (player.fotoUrl?.trim().isNotEmpty ?? false)
          ? player.fotoUrl!.trim()
          : player.fotoJugador,
      fotoEquipo: player.fotoEquipo,
      enPoolMercado: false,
      propietarioNick: '',
      idUsuarioDueno: 0,
    );
    return SizedBox(
      width: size,
      height: size,
      child: LeaguePlayerAvatar(
        player: proxy,
        size: size,
        circular: true,
      ),
    );
  }
}

class _CatalogEmptyState extends StatelessWidget {
  const _CatalogEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 34),
      child: Column(
        children: [
          Icon(Icons.groups_2_outlined, size: 34, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 10),
          Text(
            'Este equipo no tiene jugadores en catálogo.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CatalogErrorState extends StatelessWidget {
  const _CatalogErrorState({required this.error, required this.onRetry});

  final String error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 26),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 34, color: colorScheme.error),
          const SizedBox(height: 10),
          Text(
            error,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.error),
          ),
          const SizedBox(height: 10),
          FilledButton.tonalIcon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
