import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/app/theme/xi_typography.dart';
import 'package:eternal_xi/core/constants/api_constants.dart';
import 'package:eternal_xi/features/auth/controller/auth_controller.dart';
import 'package:eternal_xi/features/clash/content/clash_media_pack_service.dart';
import 'package:eternal_xi/features/profile/controller/account_progress_controller.dart';
import 'package:eternal_xi/features/profile/controller/friends_pending_controller.dart';
import 'package:eternal_xi/shared/widgets/fantasy_atmosphere_background.dart';
import 'package:eternal_xi/shared/widgets/pending_notification_badge.dart';
import 'package:eternal_xi/features/profile/widgets/achievements_tab.dart';
import 'package:eternal_xi/features/profile/widgets/progress_celebration_overlay.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ModeSelectionScreen extends StatefulWidget {
  const ModeSelectionScreen({super.key});

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProgress());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    final userId = context.read<AuthController>().currentUser?.id;
    if (userId == null) return;
    await context.read<AccountProgressController>().loadProgress(userId);
    if (mounted) {
      context.read<FriendsPendingController>().refresh(userId);
    }
  }

  Future<void> _enterClash() async {
    final ready = await ClashMediaPackService().isPackReadyQuick();
    if (!mounted) return;
    context.go(ready ? AppRoutes.clash : AppRoutes.clashPrepare);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final auth = context.watch<AuthController>();
    final pending = context.watch<FriendsPendingController>().incomingCount;
    final user = auth.currentUser;
    final nickname = user?.nickname.trim();
    final greeting = (nickname != null && nickname.isNotEmpty)
        ? nickname
        : l10n.appTitle;
    final photoUrl = (user != null && user.hasProfilePhoto)
        ? ApiConstants.userProfilePhotoUrl(
            user.id,
            cacheBuster: user.foto.hashCode,
          )
        : null;

    return WithFantasyAtmosphere(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ProgressCelebrationOverlay(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 12, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.appTitle,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                letterSpacing: 0.6,
                                color: context.xiHeaderTitle,
                              ).lumiareNative,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.modeSelectionSubtitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: context.xiTextSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PendingNotificationBadge(
                        count: pending,
                        child: _ModeProfileButton(
                          nickname: greeting,
                          nivel: user?.nivel ?? 1,
                          photoUrl: photoUrl,
                          onTap: () => context.push(
                            '${AppRoutes.profile}?from=mode',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelStyle: const TextStyle(
                      fontFamily: 'Lumiare',
                      fontSize: 14,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontFamily: 'Lumiare',
                      fontSize: 14,
                    ),
                    tabs: [
                      Tab(text: l10n.modeSelectionModesTab),
                      Tab(text: l10n.achievementsTab),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      RefreshIndicator(
                        onRefresh: _loadProgress,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                          children: [
                            _ModeOptionCard(
                              icon: Icons.emoji_events_rounded,
                              iconColor: XiColors.classicGold,
                              title: l10n.modeFantasyTitle,
                              description: l10n.modeFantasyDescription,
                              actionLabel: l10n.modeEnter,
                              onTap: () => context.go(AppRoutes.leagues),
                            ),
                            const SizedBox(height: 14),
                            _ModeOptionCard(
                              icon: Icons.bolt_rounded,
                              iconColor: XiColors.techCyan,
                              title: l10n.modeClashTitle,
                              description: l10n.modeClashDescription,
                              actionLabel: l10n.modeEnter,
                              onTap: _enterClash,
                            ),
                          ],
                        ),
                      ),
                      RefreshIndicator(
                        onRefresh: _loadProgress,
                        child: AchievementsTab(onRetry: _loadProgress),
                      ),
                    ],
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

class _ModeProfileButton extends StatelessWidget {
  const _ModeProfileButton({
    required this.nickname,
    required this.nivel,
    required this.photoUrl,
    required this.onTap,
  });

  final String nickname;
  final int nivel;
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: XiColors.royalBlue.withValues(alpha: 0.65),
                width: 1.5,
              ),
            ),
            child: ClipOval(
              child: photoUrl != null
                  ? Image.network(photoUrl!, fit: BoxFit.cover)
                  : ColoredBox(
                      color: XiColors.royalBlue.withValues(alpha: 0.15),
                      child: Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontFamily: 'Lumiare',
                            color: XiColors.royalBlue,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: XiColors.royalBlue,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.xiBackground, width: 1.2),
              ),
              child: Text(
                '$nivel',
                style: const TextStyle(
                  fontFamily: 'Lumiare',
                  fontSize: 9,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeOptionCard extends StatelessWidget {
  const _ModeOptionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.actionLabel,
    this.enabled = true,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String actionLabel;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardOpacity = enabled ? 1.0 : 0.72;

    return Opacity(
      opacity: cardOpacity,
      child: Material(
        color: context.xiCardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: context.xiDivider),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: iconColor, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: context.xiTextPrimary,
                        ),
                      ),
                    ),
                    if (!enabled)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: context.xiChipBackground,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: context.xiDivider),
                        ),
                        child: Text(
                          actionLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: context.xiTextSecondary,
                          ),
                        ),
                      )
                    else
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: context.xiTextSecondary.withValues(alpha: 0.5),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: context.xiTextSecondary.withValues(alpha: 0.9),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: enabled ? onTap : null,
                    child: Text(actionLabel),
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
