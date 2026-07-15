import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/core/network/api_exception.dart';
import 'package:eternal_xi/core/utils/user_public_tag.dart';
import 'package:eternal_xi/data/models/user_progress_response.dart';
import 'package:eternal_xi/data/models/user_public_profile.dart';
import 'package:eternal_xi/data/services/user_api_service.dart';
import 'package:eternal_xi/data/services/user_progress_api_service.dart';
import 'package:eternal_xi/features/auth/controller/auth_controller.dart';
import 'package:eternal_xi/features/leagues/screens/participant_lineup_history_screen.dart';
import 'package:eternal_xi/features/profile/controller/friends_pending_controller.dart';
import 'package:eternal_xi/features/profile/widgets/account_level_display.dart';
import 'package:eternal_xi/features/profile/widgets/achievements_tab.dart';
import 'package:eternal_xi/shared/widgets/user_profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PublicUserProfileScreen extends StatefulWidget {
  const PublicUserProfileScreen({
    required this.userId,
    this.nicknameHint,
    super.key,
  });

  final int userId;
  final String? nicknameHint;

  @override
  State<PublicUserProfileScreen> createState() =>
      _PublicUserProfileScreenState();
}

class _PublicUserProfileScreenState extends State<PublicUserProfileScreen>
    with SingleTickerProviderStateMixin {
  UserPublicProfile? _profile;
  UserProgressResponse? _progress;
  bool _loading = true;
  String? _error;
  bool _friendBusy = false;

  late final TabController _tabs;

  int? get _viewerId => context.read<AuthController>().currentUser?.id;

  bool get _isOwnProfile =>
      _viewerId != null && _viewerId == widget.userId;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final userApi = context.read<UserApiService>();
      final progressApi = context.read<UserProgressApiService>();
      final results = await Future.wait<Object?>([
        userApi.getPublicProfile(
          targetUserId: widget.userId,
          viewerUserId: _viewerId,
        ),
        progressApi.getPublicProgress(widget.userId),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = results[0] as UserPublicProfile;
        _progress = results[1] as UserProgressResponse;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _sendFriendRequest() async {
    final viewer = _viewerId;
    if (viewer == null || _profile == null || _friendBusy) return;
    setState(() => _friendBusy = true);
    try {
      await context.read<UserApiService>().sendFriendRequest(
        idUsuario: viewer,
        idAmigo: _profile!.id,
      );
      await _load();
      if (!mounted) return;
      context.read<FriendsPendingController>().refresh(viewer);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(context.l10n.friendsRequestSent),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            e is ApiException ? e.message : context.l10n.friendsLoadError,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _friendBusy = false);
    }
  }

  Future<void> _acceptFriendRequest() async {
    final viewer = _viewerId;
    final profile = _profile;
    if (viewer == null || profile?.idAmistad == null || _friendBusy) return;
    setState(() => _friendBusy = true);
    try {
      await context.read<UserApiService>().acceptFriendRequest(
        idUsuario: viewer,
        idAmistad: profile!.idAmistad!,
      );
      await _load();
      if (!mounted) return;
      context.read<FriendsPendingController>().refresh(viewer);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(e is ApiException ? e.message : 'Error'),
        ),
      );
    } finally {
      if (mounted) setState(() => _friendBusy = false);
    }
  }

  void _openLeagueHistory(UserPublicLeagueSummary league) {
    final viewer = _viewerId;
    if (viewer == null) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ParticipantLineupHistoryScreen(
          idLiga: league.idLiga,
          idLigaParticipante: league.idLigaParticipante,
          idUsuarioSolicitante: viewer,
          idUsuarioParticipante: widget.userId,
          nickname: _profile?.nickname,
          leagueSummary: league,
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final profile = _profile!;
    final progress = _progress;
    final nivel = progress?.nivel ?? profile.nivel;

    Widget avatar = UserProfileAvatar(
      userId: profile.id,
      photoPath: profile.foto,
      nickname: profile.nickname,
      size: 96,
    );

    if (progress != null) {
      avatar = AccountLevelAvatarRing(
        nivel: progress.nivel,
        xpEnNivel: progress.xpEnNivel,
        xpParaSiguiente: progress.xpParaSiguienteNivel,
        child: avatar,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        children: [
          Center(child: avatar),
          const SizedBox(height: 12),
          Center(
            child: Text(
              profile.nickname,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              UserPublicTag.format(profile.id),
              style: theme.textTheme.labelLarge?.copyWith(
                color: XiColors.classicGold,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (progress != null)
            AccountLevelDisplay(
              compact: true,
              nivel: progress.nivel,
              rango: progress.rango,
              xpEnNivel: progress.xpEnNivel,
              xpParaSiguiente: progress.xpParaSiguienteNivel,
            )
          else
            Text(
              'Nivel $nivel',
              style: theme.textTheme.titleSmall?.copyWith(
                color: context.xiTextSecondary,
              ),
            ),
          if (!_isOwnProfile) ...[
            const SizedBox(height: 16),
            _FriendActionButton(
              profile: profile,
              busy: _friendBusy,
              onSend: _sendFriendRequest,
              onAccept: _acceptFriendRequest,
            ),
          ],
          if (profile.jugadorFavorito != null) ...[
            const SizedBox(height: 16),
            _FavoritePlayerCard(player: profile.jugadorFavorito!),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: context.xiBackground,
      appBar: AppBar(
        title: Text(l10n.profile),
        backgroundColor: context.xiBackground,
        foregroundColor: context.xiTextPrimary,
        bottom: _loading || _error != null || _profile == null
            ? null
            : TabBar(
                controller: _tabs,
                labelStyle: const TextStyle(fontFamily: 'Lumiare'),
                tabs: const [
                  Tab(text: 'Estadísticas'),
                  Tab(text: 'Logros'),
                ],
              ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _profile == null
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(theme),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                          children: [
                            _StatsGrid(stats: _profile!.stats),
                            const SizedBox(height: 22),
                            Text(
                              'Ligas',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_profile!.ligas.isEmpty)
                              Text(
                                'Sin ligas finalizadas',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: context.xiTextSecondary,
                                ),
                              )
                            else
                              ..._profile!.ligas.map(
                                (league) => Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    title: Text(league.nombreLiga),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (league.posicionFinal > 0)
                                          Text(
                                            '${league.posicionFinal}º de ${league.totalParticipantes} · ${league.puntosFantasy} pts',
                                          ),
                                        if (league.maxGoleador != null)
                                          Text(
                                            'Goleador: ${league.maxGoleador!.nombre} (${league.maxGoleador!.total})',
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        if (league.maxAsistente != null)
                                          Text(
                                            'Asistencias: ${league.maxAsistente!.nombre} (${league.maxAsistente!.total})',
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        if (league.maxPorteriasCero != null)
                                          Text(
                                            'Porterías a 0: ${league.maxPorteriasCero!.nombre} (${league.maxPorteriasCero!.total})',
                                            style: theme.textTheme.bodySmall,
                                          ),
                                      ],
                                    ),
                                    isThreeLine: true,
                                    trailing: const Icon(
                                      Icons.chevron_right_rounded,
                                    ),
                                    onTap: () => _openLeagueHistory(league),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      RefreshIndicator(
                        onRefresh: _load,
                        child: AchievementsTab(
                          progressOverride: _progress,
                          showLevelHeader: false,
                          onRetry: _load,
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

class _FriendActionButton extends StatelessWidget {
  const _FriendActionButton({
    required this.profile,
    required this.busy,
    required this.onSend,
    required this.onAccept,
  });

  final UserPublicProfile profile;
  final bool busy;
  final VoidCallback onSend;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (profile.isFriend) {
      return FilledButton.tonal(
        onPressed: null,
        child: Text(l10n.friendsTabFriends),
      );
    }
    if (profile.isPendingOutgoing) {
      return FilledButton.tonal(
        onPressed: null,
        child: Text(l10n.friendsRequestSent),
      );
    }
    if (profile.isPendingIncoming) {
      return FilledButton(
        onPressed: busy ? null : onAccept,
        child: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(l10n.friendsAccept),
      );
    }
    return FilledButton(
      onPressed: busy ? null : onSend,
      child: busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(l10n.friendsAdd),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final UserPublicStats stats;

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatTile(label: 'Ligas ganadas', value: '${stats.ligasGanadas}'),
      _StatTile(label: 'Goles', value: '${stats.goles}'),
      _StatTile(label: 'Asistencias', value: '${stats.asistencias}'),
      _StatTile(label: 'Porterías a 0', value: '${stats.porteriasCero}'),
      _StatTile(label: 'Lesiones', value: '${stats.lesiones}'),
      _StatTile(label: 'Sanciones', value: '${stats.sanciones}'),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.2,
      children: items,
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: context.xiCardSurface,
        border: Border.all(
          color: context.xiTextSecondary.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: context.xiTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoritePlayerCard extends StatelessWidget {
  const _FavoritePlayerCard({required this.player});

  final UserPublicFavoritePlayer player;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (player.photoUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  player.photoUrl!,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.sports_soccer_rounded,
                    size: 40,
                  ),
                ),
              )
            else
              const Icon(Icons.sports_soccer_rounded, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jugador favorito',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: context.xiTextSecondary,
                    ),
                  ),
                  Text(
                    player.nombre,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (player.equipo.isNotEmpty)
                    Text(
                      player.equipo,
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
