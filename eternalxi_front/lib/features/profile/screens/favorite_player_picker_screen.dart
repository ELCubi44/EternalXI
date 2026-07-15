import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/core/network/api_exception.dart';
import 'package:eternal_xi/data/models/catalog_team_player.dart';
import 'package:eternal_xi/data/models/season_summary.dart';
import 'package:eternal_xi/data/services/leagues_api_service.dart';
import 'package:eternal_xi/data/services/user_api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Selector de jugador favorito del catálogo Eterno Campeón.
class FavoritePlayerPickerScreen extends StatefulWidget {
  const FavoritePlayerPickerScreen({
    required this.userId,
    this.currentPlayerId,
    super.key,
  });

  final int userId;
  final int? currentPlayerId;

  @override
  State<FavoritePlayerPickerScreen> createState() =>
      _FavoritePlayerPickerScreenState();
}

class _FavoritePlayerPickerScreenState extends State<FavoritePlayerPickerScreen> {
  final _searchCtrl = TextEditingController();

  List<CatalogTeamPlayer> _players = const [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<LeaguesApiService>();
      final seasons = await api.fetchSeasonCatalog();
      final season = _pickEternoCampeonSeason(seasons);
      if (season == null) {
        throw const ApiException('No hay temporada Eterno Campeón disponible.');
      }
      final teams = await api.fetchCatalogTeamsBySeason(seasonId: season.id);
      final batches = await Future.wait(
        teams.map(
          (team) => api.getCatalogTeamPlayers(
            idEquipo: team.id,
            seasonId: season.id,
          ),
        ),
      );
      final seen = <int>{};
      final merged = <CatalogTeamPlayer>[];
      for (final batch in batches) {
        for (final player in batch) {
          if (seen.add(player.idJugador)) {
            merged.add(player);
          }
        }
      }
      merged.sort(
        (a, b) => a.displayName().toLowerCase().compareTo(
          b.displayName().toLowerCase(),
        ),
      );
      if (!mounted) return;
      setState(() {
        _players = merged;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is ApiException ? e.message : e.toString();
      });
    }
  }

  SeasonSummary? _pickEternoCampeonSeason(List<SeasonSummary> seasons) {
    for (final s in seasons) {
      final n = s.nombre.toLowerCase();
      if (n.contains('eterno') && n.contains('campe')) {
        return s;
      }
    }
    for (final s in seasons) {
      if (s.id == 2) return s;
    }
    return seasons.isNotEmpty ? seasons.first : null;
  }

  Future<void> _pickPlayer(CatalogTeamPlayer player) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await context.read<UserApiService>().updateFavoritePlayer(
        userId: widget.userId,
        idJugador: player.idJugador,
      );
      if (!mounted) return;
      Navigator.pop(context, player.idJugador);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(e is ApiException ? e.message : e.toString()),
        ),
      );
    }
  }

  Future<void> _clearFavorite() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await context.read<UserApiService>().updateFavoritePlayer(
        userId: widget.userId,
        idJugador: null,
      );
      if (!mounted) return;
      Navigator.pop(context, 0);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(e is ApiException ? e.message : e.toString()),
        ),
      );
    }
  }

  List<CatalogTeamPlayer> get _filteredPlayers {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _players;
    return _players
        .where((p) => p.displayName().toLowerCase().contains(q))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.xiBackground,
      appBar: AppBar(
        title: const Text('Jugador favorito'),
        backgroundColor: context.xiBackground,
        foregroundColor: context.xiTextPrimary,
        actions: [
          if (widget.currentPlayerId != null && widget.currentPlayerId! > 0)
            TextButton(
              onPressed: _saving ? null : _clearFavorite,
              child: const Text('Quitar'),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Material(
                      color: XiColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            fontFamily: 'Lumiare',
                            color: XiColors.error,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    controller: _searchCtrl,
                    style: TextStyle(
                      fontFamily: 'Lumiare',
                      color: context.xiTextPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Buscar jugador',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: context.xiCardSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: context.xiDivider),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredPlayers.isEmpty
                      ? Center(
                          child: Text(
                            'No hay jugadores que coincidan.',
                            style: TextStyle(
                              fontFamily: 'Lumiare',
                              color: context.xiTextSecondary,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: _filteredPlayers.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final player = _filteredPlayers[index];
                            return _FavoritePlayerPickRow(
                              player: player,
                              saving: _saving,
                              onPick: () => _pickPlayer(player),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _FavoritePlayerPickRow extends StatelessWidget {
  const _FavoritePlayerPickRow({
    required this.player,
    required this.saving,
    required this.onPick,
  });

  final CatalogTeamPlayer player;
  final bool saving;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final photo = player.resolvedFotoJugadorUrl();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: context.xiCompactCardGradient,
        ),
        border: Border.all(color: context.xiBorderSubtle),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      child: Row(
        children: [
          ClipOval(
            child: photo != null
                ? Image.network(
                    photo,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _photoFallback(),
                  )
                : _photoFallback(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              player.displayName(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Lumiare',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: context.xiTextPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: saving ? null : onPick,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Elegir'),
          ),
        ],
      ),
    );
  }

  Widget _photoFallback() {
    return ColoredBox(
      color: XiColors.royalBlue.withValues(alpha: 0.12),
      child: const SizedBox(
        width: 48,
        height: 48,
        child: Icon(Icons.person_rounded, color: XiColors.royalBlue),
      ),
    );
  }
}
