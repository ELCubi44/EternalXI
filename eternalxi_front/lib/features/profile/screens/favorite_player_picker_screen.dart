import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/core/network/api_exception.dart';
import 'package:eternal_xi/data/models/eligible_favorite_player.dart';
import 'package:eternal_xi/data/services/user_api_service.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_cards_local_datasource.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_player_collection_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/profile/widgets/favorite_picker_team_expand_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Selector de jugador favorito (Clash carta o alineacion Fantasy).
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

  List<EligibleFavoritePlayer> _players = const [];
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
      final api = context.read<UserApiService>();
      // Desbloquea avatares de cartas Clash poseídas antes de listar opciones.
      try {
        final collectionBackend =
            await SharedPreferencesClashPlayerCollectionBackend.create();
        final ownedIds = collectionBackend.readSnapshot().ownedCardIds;
        if (ownedIds.isNotEmpty) {
          final cardsRepo = ClashCardsRepository(ClashCardsLocalDataSource());
          final playerIds = <int>{};
          for (final cardId in ownedIds) {
            final entry = await cardsRepo.findById(cardId);
            final pid = entry?.card.playerId;
            if (pid != null && pid > 0) {
              playerIds.add(pid);
            }
          }
          if (playerIds.isNotEmpty) {
            await api.registerAvatarUnlocks(
              userId: widget.userId,
              playerIds: playerIds.toList(growable: false),
              origen: 'clash',
            );
          }
        }
      } catch (_) {
        // Colección Clash ausente o API no disponible: seguimos con Fantasy.
      }

      final rows = await api.getFavoritePlayerOptions(userId: widget.userId);
      if (!mounted) return;
      setState(() {
        _players = rows;
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

  Future<void> _pickPlayer(EligibleFavoritePlayer player) async {
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

  List<FavoritePickerTeamGroup> get _filteredTeams {
    final q = _searchCtrl.text.trim().toLowerCase();
    final all = groupEligibleFavoritePlayersByTeam(_players);
    if (q.isEmpty) return all;

    final out = <FavoritePickerTeamGroup>[];
    for (final team in all) {
      final teamMatches = team.nombreEquipo.toLowerCase().contains(q);
      final matchedPlayers = teamMatches
          ? team.players
          : team.players
                .where((p) => p.nombre.toLowerCase().contains(q))
                .toList(growable: false);
      if (matchedPlayers.isEmpty) continue;
      final copy = FavoritePickerTeamGroup(
        idEquipo: team.idEquipo,
        nombreEquipo: team.nombreEquipo,
        fotoEquipo: team.fotoEquipo,
      )..players.addAll(matchedPlayers);
      out.add(copy);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final teams = _filteredTeams;

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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Text(
                    'Desbloquea avatares jugando Fantasy (alineaci\u00f3n en jornada iniciada) o consiguiendo cartas Clash.',
                    style: TextStyle(
                      fontFamily: 'Lumiare',
                      fontSize: 13,
                      color: context.xiTextSecondary,
                      height: 1.35,
                    ),
                  ),
                ),
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
                      hintText: 'Buscar jugador o equipo',
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
                  child: teams.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              _players.isEmpty
                                  ? 'Juega partidas Fantasy o consigue cartas Clash para ir desbloqueando avatares.'
                                  : 'No hay jugadores o equipos que coincidan.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Lumiare',
                                color: context.xiTextSecondary,
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: teams.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            return FavoritePickerTeamExpandCard(
                              group: teams[index],
                              saving: _saving,
                              onPick: _pickPlayer,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
