import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/app/theme/xi_typography.dart';
import 'package:eternal_xi/core/network/api_exception.dart';
import 'package:eternal_xi/core/utils/user_public_tag.dart';
import 'package:eternal_xi/data/models/user_progress_response.dart';
import 'package:eternal_xi/data/models/user_public_profile.dart';
import 'package:eternal_xi/data/services/user_api_service.dart';
import 'package:eternal_xi/data/services/user_progress_api_service.dart';
import 'package:eternal_xi/features/auth/controller/auth_controller.dart';
import 'package:eternal_xi/features/leagues/screens/participant_lineup_history_screen.dart';
import 'package:eternal_xi/features/profile/widgets/account_level_display.dart';
import 'package:eternal_xi/features/profile/widgets/achievements_tab.dart';
import 'package:eternal_xi/features/profile/widgets/favorite_player_slot.dart';
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

  late final TabController _tabs;

  int? get _viewerId => context.read<AuthController>().currentUser?.id;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) {
        setState(() {});
      }
    });
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

  Future<void> _sendFriendRequest() async {
    final viewer = _viewerId;
    final profile = _profile;
    if (viewer == null || profile == null || profile.id == viewer) return;
    try {
      await context.read<UserApiService>().sendFriendRequest(
        idUsuario: viewer,
        idAmigo: profile.id,
      );
      if (!mounted) return;
      await _load();
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
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text(
            e is ApiException ? e.message : context.l10n.friendsRequestError,
          ),
        ),
      );
    }
  }

  Widget _buildFriendAction(ThemeData theme) {
    final profile = _profile!;
    final viewer = _viewerId;
    if (viewer == null || viewer == profile.id || profile.isFriend) {
      return const SizedBox.shrink();
    }
    if (profile.isPendingOutgoing) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          context.l10n.friendsRequestSent,
          style: theme.textTheme.bodySmall?.copyWith(
            color: context.xiTextSecondary,
          ),
        ),
      );
    }
    if (profile.isPendingIncoming) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: FilledButton.icon(
        onPressed: _sendFriendRequest,
        icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
        label: Text(context.l10n.friendsAdd),
      ),
    );
  }

  Widget _buildPrincipalHeader(ThemeData theme) {
    final profile = _profile!;
    final progress = _progress;

    Widget avatar = UserProfileAvatar(
      userId: profile.id,
      photoPath: profile.foto,
      nickname: profile.nickname,
      size: 84,
    );

    if (progress != null) {
      avatar = AccountLevelAvatarRing(
        nivel: progress.nivel,
        xpEnNivel: progress.xpEnNivel,
        xpParaSiguiente: progress.xpParaSiguienteNivel,
        ringStroke: 3,
        ringGap: 2.5,
        child: avatar,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              Column(
                children: [
                  Center(child: avatar),
                  const SizedBox(height: 10),
                  Center(
                    child: XiText(
                      profile.nickname,
                      style: XiTypography.lumiare(
                        fontSize: 22,
                        letterSpacing: 0.4,
                        color: context.xiTextPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: XiText(
                      UserPublicTag.format(profile.id),
                      style: XiTypography.lumiare(
                        fontSize: 13,
                        color: XiColors.classicGold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
              Positioned(
                right: 8,
                bottom: 14,
                child: FavoritePlayerSlot(
                  loading: _loading,
                  favorite: profile.jugadorFavorito,
                  showAddPlaceholder: false,
                ),
              ),
            ],
          ),
          _buildFriendAction(theme),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildLeaguesTab(ThemeData theme) {
    final ligas = _profile!.ligas;
    if (ligas.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Sin ligas finalizadas',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.xiTextSecondary,
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      itemCount: ligas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final league = ligas[index];
        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            title: Text(league.nombreLiga),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (league.posicionFinal > 0)
                  Text(
                    '${league.posicionFinal}\u00ba de ${league.totalParticipantes} \u00b7 ${league.puntosFantasy} pts',
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
                    'Porter\u00edas a 0: ${league.maxPorteriasCero!.nombre} (${league.maxPorteriasCero!.total})',
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _openLeagueHistory(league),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final showHeader = _tabs.index == 0;

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
                labelStyle: XiTypography.lumiare(fontSize: 13),
                tabs: const [
                  Tab(text: 'Principal'),
                  Tab(text: 'Ligas'),
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
                if (showHeader) _buildPrincipalHeader(theme),
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
                          ],
                        ),
                      ),
                      RefreshIndicator(
                        onRefresh: _load,
                        child: _buildLeaguesTab(theme),
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

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final UserPublicStats stats;

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatTile(label: 'Ligas ganadas', value: '${stats.ligasGanadas}'),
      _StatTile(label: 'Goles', value: '${stats.goles}'),
      _StatTile(label: 'Asistencias', value: '${stats.asistencias}'),
      _StatTile(label: 'Porter\u00edas a 0', value: '${stats.porteriasCero}'),
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
            XiText(
              value,
              style: XiTypography.lumiare(
                fontSize: 16,
                color: context.xiTextPrimary,
              ),
            ),
            XiText(
              label,
              style: XiTypography.lumiare(
                fontSize: 11,
                color: context.xiTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
