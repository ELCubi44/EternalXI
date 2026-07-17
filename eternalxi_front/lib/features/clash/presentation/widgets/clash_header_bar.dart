import 'dart:async';

import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/core/constants/api_constants.dart';
import 'package:eternal_xi/features/auth/controller/auth_controller.dart';
import 'package:eternal_xi/features/clash/cards/presentation/epic/clash_epic_assets.dart';
import 'package:eternal_xi/features/clash/shared/energy/clash_energy_service.dart';
import 'package:eternal_xi/features/clash/story/presentation/controllers/clash_story_controller.dart';
import 'package:eternal_xi/features/profile/controller/account_progress_controller.dart';
import 'package:eternal_xi/features/profile/widgets/account_level_display.dart';
import 'package:eternal_xi/shared/widgets/money_coins_icon.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Cabecera Clash: avatar + XP + bandeja de recursos (sin anillo ni pills).
class ClashHeaderBar extends StatefulWidget {
  const ClashHeaderBar({super.key});

  @override
  State<ClashHeaderBar> createState() => _ClashHeaderBarState();
}

class _ClashHeaderBarState extends State<ClashHeaderBar> {
  final _energyService = ClashEnergyService();
  ClashEnergyWallet? _energy;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final auth = context.read<AuthController>();
    final progressCtrl = context.read<AccountProgressController>();
    final storyCtrl = context.read<ClashStoryController>();
    final userId = auth.currentUser?.id;
    if (userId != null) {
      await progressCtrl.loadProgress(userId);
    }
    if (!mounted) return;
    await storyCtrl.load();
    final energy = await _energyService.load();
    if (!mounted) return;
    setState(() => _energy = energy);
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) async {
      final next = await _energyService.load();
      if (!mounted) return;
      setState(() => _energy = next);
    });
  }

  void _openProfile() {
    context.push('${AppRoutes.profile}?from=clash');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthController>().currentUser;
    final progress = context.watch<AccountProgressController>().progress;
    final story = context.watch<ClashStoryController>();
    final nickname = user?.nickname.trim();
    final displayName =
        (nickname != null && nickname.isNotEmpty) ? nickname : '—';
    final nivel = progress?.nivel ?? user?.nivel ?? 1;
    final xpEn = progress?.xpEnNivel ?? 0;
    final xpMax = progress?.xpParaSiguienteNivel ?? 1;
    final photoUrl = user == null
        ? null
        : ApiConstants.userProfilePhotoUrl(
            user.id,
            cacheBuster: DateTime.now().millisecondsSinceEpoch ~/ 60000,
          );
    final energy = _energy;
    final coins = story.progress.walletCoins;
    final gems = story.progress.walletGems;

    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.55),
              Colors.black.withValues(alpha: 0.18),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: _openProfile,
                      customBorder: const CircleBorder(),
                      child: _HeaderAvatar(
                        photoUrl: photoUrl,
                        nickname: displayName,
                        size: 56,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: XiColors.warmWhite,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          AccountLevelDisplay(
                            compact: true,
                            showXpUnit: true,
                            nivel: nivel,
                            rango: progress?.rango ?? '',
                            xpEnNivel: xpEn,
                            xpParaSiguiente: xpMax,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _ResourcesTray(
                  energyPrimary: energy?.fractionLabel ?? '—/—',
                  energySecondary: energy?.countdownLabel,
                  coinsLabel: _formatAmount(coins),
                  gemsLabel: _formatAmount(gems),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatAmount(int value) {
    final raw = value.toString();
    final buf = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      final fromEnd = raw.length - i;
      buf.write(raw[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) {
        buf.write('.');
      }
    }
    return buf.toString();
  }
}

class _HeaderAvatar extends StatelessWidget {
  const _HeaderAvatar({
    required this.nickname,
    required this.size,
    this.photoUrl,
  });

  final String nickname;
  final double size;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final initial = nickname.trim().isEmpty
        ? '?'
        : nickname.trim().characters.first.toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: XiColors.classicGold.withValues(alpha: 0.75),
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(
            color: XiColors.techCyan.withValues(alpha: 0.25),
            blurRadius: 10,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: photoUrl == null
          ? ColoredBox(
              color: XiColors.royalBlue.withValues(alpha: 0.25),
              child: Center(
                child: Text(
                  initial,
                  style: TextStyle(
                    fontFamily: 'Lumiare',
                    color: XiColors.warmWhite,
                    fontWeight: FontWeight.w700,
                    fontSize: size * 0.34,
                  ),
                ),
              ),
            )
          : Image.network(
              photoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => ColoredBox(
                color: XiColors.royalBlue.withValues(alpha: 0.25),
                child: Center(
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontFamily: 'Lumiare',
                      color: XiColors.warmWhite,
                      fontWeight: FontWeight.w700,
                      fontSize: size * 0.34,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

/// Bandeja única estilo HUD: iconos/valores sin pastillas individuales.
class _ResourcesTray extends StatelessWidget {
  const _ResourcesTray({
    required this.energyPrimary,
    required this.coinsLabel,
    required this.gemsLabel,
    this.energySecondary,
  });

  final String energyPrimary;
  final String? energySecondary;
  final String coinsLabel;
  final String gemsLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: const DecorationImage(
            image: AssetImage(ClashEpicAssets.clashResourcesTrayBg),
            fit: BoxFit.fill,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
          child: Row(
            children: [
              Expanded(
                child: _ResourceSlot(
                  iconAsset: ClashEpicAssets.clashEnergyIcon,
                  primary: energyPrimary,
                  secondary: energySecondary,
                  accent: XiColors.techCyan,
                ),
              ),
              Expanded(
                child: _ResourceSlot(
                  iconWidget: const MoneyCoinsIcon(size: 18),
                  primary: coinsLabel,
                  accent: XiColors.classicGold,
                ),
              ),
              Expanded(
                child: _ResourceSlot(
                  iconAsset: ClashEpicAssets.clashGachaGemIcon,
                  primary: gemsLabel,
                  accent: const Color(0xFF6EE7FF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResourceSlot extends StatelessWidget {
  const _ResourceSlot({
    required this.primary,
    required this.accent,
    this.secondary,
    this.iconAsset,
    this.iconWidget,
  });

  final String primary;
  final String? secondary;
  final Color accent;
  final String? iconAsset;
  final Widget? iconWidget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          if (iconWidget != null)
            iconWidget!
          else if (iconAsset != null)
            Image.asset(
              iconAsset!,
              width: 20,
              height: 20,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  primary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: context.xiTextPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    height: 1.05,
                  ),
                ),
                if (secondary != null && secondary!.isNotEmpty)
                  Text(
                    secondary!,
                    maxLines: 1,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: accent.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      height: 1.1,
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
