import 'package:eternal_xi/app/icons/xi_icons.dart';
import 'package:eternal_xi/app/localization/league_l10n.dart';
import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/app/theme/xi_typography.dart';
import 'package:eternal_xi/shared/widgets/xi_brand_wordmark.dart';
import 'package:eternal_xi/core/constants/api_constants.dart';
import 'package:eternal_xi/data/models/league_summary.dart';
import 'package:eternal_xi/features/auth/controller/auth_controller.dart';
import 'package:eternal_xi/features/legal/widgets/age_confirmation_dialog.dart';
import 'package:eternal_xi/features/leagues/controller/leagues_controller.dart';
import 'package:eternal_xi/core/utils/league_asset_urls.dart';
import 'package:eternal_xi/shared/widgets/fantasy_atmosphere_background.dart';
import 'package:eternal_xi/shared/widgets/league_participants_icon.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class MyLeaguesScreen extends StatefulWidget {
  const MyLeaguesScreen({super.key});

  @override
  State<MyLeaguesScreen> createState() => _MyLeaguesScreenState();
}

class _MyLeaguesScreenState extends State<MyLeaguesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
      showAgeConfirmationDialog(context);
    });
  }

  int? _resolveUserId() {
    final user = context.read<AuthController>().currentUser;
    final id = user?.id;
    if (id == null || id <= 0) return null;
    return id;
  }

  Future<void> _refresh() async {
    final idUsuario = _resolveUserId();
    if (idUsuario == null) return;
    await context.read<LeaguesController>().loadMyLeagues(idUsuario);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final leagues = context.watch<LeaguesController>();
    final user = context.watch<AuthController>().currentUser;
    final userId = _resolveUserId();
    final nickname = user?.nickname ?? 'Jugador';
    final nivel = user?.nivel ?? 1;
    final photoUrl = (user != null && user.hasProfilePhoto)
        ? ApiConstants.userProfilePhotoUrl(
            user.id,
            cacheBuster: user.foto.hashCode,
          )
        : null;

    return WithFantasyAtmosphere(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
            children: [
              // ── Header personalizado ──────────────────────────────
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 16, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'MIS LIGAS',
                              style: XiTypography.sectionEyebrow(
                                color: context.xiTextPrimary,
                                fontSize: 10,
                                letterSpacing: 2.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            XiBrandWordmark(
                              fontSize: 22,
                              color: context.xiTextPrimary,
                              letterSpacing: 0.6,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.backToModeSelection,
                        onPressed: () => context.go(AppRoutes.mode),
                        icon: const Icon(Icons.swap_horiz_rounded),
                      ),
                      if (userId != null) ...[
                        _IconActionButton(
                          assetIcon: 'assets/app/action_join_league.png',
                          iconSize: 40,
                          visualOffsetY: -3,
                          tooltip: l10n.joinLeague,
                          onTap: () async {
                            await context.push(AppRoutes.leaguesJoin);
                            if (context.mounted) await _refresh();
                          },
                        ),
                        _IconActionButton(
                          assetIcon: 'assets/app/action_create_league.png',
                          iconSize: 36,
                          tooltip: l10n.createLeague,
                          onTap: () async {
                            await context.push(AppRoutes.leaguesCreate);
                            if (context.mounted) await _refresh();
                          },
                        ),
                        const SizedBox(width: 6),
                        _HeaderProfileButton(
                          nivel: nivel,
                          nickname: nickname,
                          photoUrl: photoUrl,
                          onTap: () => context.push(AppRoutes.profile),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 4),

              // ── Cuerpo ────────────────────────────────────────────
              Expanded(
                child: userId == null
                    ? _NoSessionMessage()
                    : RefreshIndicator(
                        onRefresh: _refresh,
                        child: _LeaguesBody(
                          leagues: leagues,
                          onRetry: _refresh,
                        ),
                      ),
              ),
            ],
        ),
      ),
    );
  }
}

class _NavAssetIcon extends StatelessWidget {
  const _NavAssetIcon({required this.asset, this.dimmed = false});

  final String asset;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      asset,
      width: 24,
      height: 24,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
    if (dimmed) {
      return Opacity(opacity: 0.55, child: image);
    }
    return image;
  }
}

// ── Header actions ────────────────────────────────────────────────────────────

class _HeaderProfileButton extends StatelessWidget {
  const _HeaderProfileButton({
    required this.nivel,
    required this.nickname,
    required this.photoUrl,
    required this.onTap,
  });

  final int nivel;
  final String nickname;
  final String? photoUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initial = nickname.trim().isEmpty
        ? '?'
        : nickname.trim()[0].toUpperCase();
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: XiColors.royalBlue.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
            clipBehavior: Clip.hardEdge,
            child: photoUrl != null
                ? Image.network(
                    photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _Initial(initial: initial),
                  )
                : _Initial(initial: initial),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: XiColors.royalBlue,
                border: Border.all(color: XiColors.background, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                '$nivel',
                style: const TextStyle(
                  fontFamily: 'Lumiare',
                  color: XiColors.warmWhite,
                  fontSize: 8,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Initial extends StatelessWidget {
  const _Initial({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: XiColors.navyBlue,
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontFamily: 'Lumiare',
            color: XiColors.warmWhite,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _IconActionButton extends StatelessWidget {
  const _IconActionButton({
    this.icon,
    this.assetIcon,
    this.iconSize = 22,
    this.visualOffsetY = 0,
    required this.tooltip,
    required this.onTap,
  }) : assert(icon != null || assetIcon != null);

  final IconData? icon;
  final String? assetIcon;
  final double iconSize;
  final double visualOffsetY;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final touchTarget = iconSize + 12;
    final Widget leading;
    if (assetIcon != null) {
      leading = Image.asset(
        assetIcon!,
        width: iconSize,
        height: iconSize,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      );
    } else {
      leading = Icon(icon, color: context.xiTextPrimary, size: iconSize);
    }
  final iconWidget = visualOffsetY != 0
      ? Transform.translate(offset: Offset(0, visualOffsetY), child: leading)
      : leading;

    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onTap,
        icon: iconWidget,
        padding: const EdgeInsets.all(4),
        constraints: BoxConstraints(
          minWidth: touchTarget,
          minHeight: touchTarget,
        ),
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _NoSessionMessage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.person_off_outlined, size: 56, color: XiColors.steelGray),
        const SizedBox(height: 16),
        Text(
          l10n.noUserSession,
          style: const TextStyle(
            fontFamily: 'Lumiare',
            color: XiColors.warmWhite,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.noUserSessionHint,
          style: const TextStyle(
            fontFamily: 'Lumiare',
            color: XiColors.steelGray,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _LeaguesBody extends StatelessWidget {
  const _LeaguesBody({required this.leagues, required this.onRetry});

  final LeaguesController leagues;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (leagues.isLoading && leagues.myLeagues.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (leagues.errorMessage != null && leagues.myLeagues.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48, color: XiColors.heroRed),
          const SizedBox(height: 16),
          Text(
            leagues.errorMessage!,
            style: const TextStyle(
              fontFamily: 'Lumiare',
              color: XiColors.warmWhite,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Center(
            child: GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: XiColors.royalBlue),
                  color: XiColors.royalBlue.withValues(alpha: 0.12),
                ),
                child: Text(
                  l10n.retry,
                  style: const TextStyle(
                    fontFamily: 'Lumiare',
                    color: XiColors.royalBlue,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (leagues.myLeagues.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        children: [
          const XiIcon(
            XiIconType.stadium,
            size: 56,
            color: XiColors.royalBlue,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noLeaguesYet,
            style: const TextStyle(
              fontFamily: 'Lumiare',
              color: XiColors.warmWhite,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.createOrJoinLeagueHint,
            style: const TextStyle(
              fontFamily: 'Lumiare',
              color: XiColors.steelGray,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: leagues.myLeagues.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final league = leagues.myLeagues[index];
        return _LeagueCard(
          league: league,
          onTap: () => context.push(AppRoutes.leagueDetail(league.id)),
        );
      },
    );
  }
}

// ── Tarjeta de liga ───────────────────────────────────────────────────────────

class _LeagueCard extends StatefulWidget {
  const _LeagueCard({required this.league, required this.onTap});

  final LeagueSummary league;
  final VoidCallback onTap;

  @override
  State<_LeagueCard> createState() => _LeagueCardState();
}

class _LeagueCardState extends State<_LeagueCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 160),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ll = context.leagueL10n;
    final seasonUri = widget.league.idTemporada > 0
        ? LeagueAssetUrls.seasonCover(widget.league.idTemporada).toString()
        : null;

    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) {
        _pressCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: context.xiCompactCardGradient,
            ),
            border: Border.all(color: context.xiBorderSubtle),
            boxShadow: context.xiCardShadow,
          ),
          clipBehavior: Clip.hardEdge,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Imagen de temporada
                _SeasonThumbnail(seasonUri: seasonUri),
                const SizedBox(width: 14),

                // Información
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.league.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Lumiare',
                          color: context.xiTextPrimary,
                          fontSize: 16,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const LeagueParticipantsIcon(size: 20),
                          const SizedBox(width: 5),
                          Text(
                            ll.participantsCount(widget.league.participantes),
                            style: TextStyle(
                              fontFamily: 'Lumiare',
                              color: context.xiTextPrimary,
                              fontSize: 12,
                            ),
                          ),
                          if (widget.league.soyAdmin) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                color: XiColors.royalBlue.withValues(alpha: 0.15),
                                border: Border.all(
                                  color: XiColors.royalBlue.withValues(alpha: 0.35),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                'ADMIN',
                                style: TextStyle(
                                  fontFamily: 'Lumiare',
                                  color: context.xiTextPrimary,
                                  fontSize: 9,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Flecha derecha
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: XiColors.royalBlue.withValues(alpha: 0.10),
                    border: Border.all(
                      color: XiColors.royalBlue.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: XiColors.royalBlue,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Miniatura de temporada ────────────────────────────────────────────────────

class _SeasonThumbnail extends StatelessWidget {
  const _SeasonThumbnail({required this.seasonUri});

  final String? seasonUri;

  @override
  Widget build(BuildContext context) {
    const size = 60.0;
    if (seasonUri == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: XiColors.surfaceContainer,
          border: Border.all(color: XiColors.divider, width: 0.5),
        ),
        alignment: Alignment.center,
        child: const XiIcon(
          XiIconType.stadium,
          size: 28,
          color: XiColors.steelGray,
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        seasonUri!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: XiColors.surfaceContainer,
          ),
          alignment: Alignment.center,
          child: const XiIcon(XiIconType.stadium, size: 28, color: XiColors.steelGray),
        ),
      ),
    );
  }
}
