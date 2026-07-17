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
import 'package:eternal_xi/shared/widgets/money_coins_icon.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Cabecera Clash sobre marco ornamental unificado (avatar + XP + recursos).
class ClashHeaderBar extends StatefulWidget {
  const ClashHeaderBar({super.key});

  @override
  State<ClashHeaderBar> createState() => _ClashHeaderBarState();
}

class _ClashHeaderBarState extends State<ClashHeaderBar> {
  final _energyService = ClashEnergyService();
  ClashEnergyWallet? _energy;
  Timer? _ticker;

  /// Ratio del asset `bg_clash_header_ornate.jpg`.
  static const double _frameAspect = 900 / 336;

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
    final xpMaxRaw = progress?.xpParaSiguienteNivel ?? 1;
    final xpMax = xpMaxRaw <= 0 ? 1 : xpMaxRaw;
    final xpFraction = (xpEn / xpMax).clamp(0.0, 1.0);
    final rango = progress?.rango ?? '';
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
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
          child: AspectRatio(
            aspectRatio: _frameAspect,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        ClashEpicAssets.clashHeaderPlateBg,
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                    // Avatar en el círculo izquierdo.
                    Positioned(
                      left: w * 0.055,
                      top: h * 0.15,
                      width: w * 0.255,
                      height: w * 0.255,
                      child: InkWell(
                        onTap: _openProfile,
                        customBorder: const CircleBorder(),
                        child: _HeaderAvatar(
                          photoUrl: photoUrl,
                          nickname: displayName,
                        ),
                      ),
                    ),
                    // Nombre + nivel en el panel superior.
                    Positioned(
                      left: w * 0.34,
                      right: w * 0.05,
                      top: h * 0.12,
                      height: h * 0.26,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: XiColors.warmWhite,
                                fontWeight: FontWeight.w800,
                                fontSize: (h * 0.12).clamp(14.0, 18.0),
                                height: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Nv. $nivel',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: XiColors.classicGold,
                              fontWeight: FontWeight.w800,
                              fontSize: (h * 0.095).clamp(12.0, 15.0),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // XP en la barra hexagonal central.
                    Positioned(
                      left: w * 0.36,
                      right: w * 0.06,
                      top: h * 0.42,
                      height: h * 0.14,
                      child: Row(
                        children: [
                          Text(
                            '$xpEn/$xpMax xp',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: XiColors.warmWhite.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w700,
                              fontSize: (h * 0.085).clamp(11.0, 13.0),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: xpFraction,
                                minHeight: (h * 0.07).clamp(6.0, 9.0),
                                backgroundColor: Colors.black.withValues(
                                  alpha: 0.35,
                                ),
                                color: XiColors.techCyan,
                              ),
                            ),
                          ),
                          if (rango.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              rango,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: XiColors.warmWhite.withValues(
                                  alpha: 0.75,
                                ),
                                fontSize: (h * 0.075).clamp(10.0, 12.0),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Recursos en los 3 huecos inferiores.
                    Positioned(
                      left: w * 0.345,
                      right: w * 0.045,
                      top: h * 0.62,
                      height: h * 0.26,
                      child: Row(
                        children: [
                          Expanded(
                            child: _ResourceSlot(
                              iconAsset: ClashEpicAssets.clashEnergyIcon,
                              primary: energy?.fractionLabel ?? '—/—',
                              secondary: energy?.countdownLabel,
                              accent: XiColors.techCyan,
                              compact: true,
                            ),
                          ),
                          Expanded(
                            child: _ResourceSlot(
                              iconWidget: const MoneyCoinsIcon(size: 16),
                              primary: _formatAmount(coins),
                              accent: XiColors.classicGold,
                              compact: true,
                            ),
                          ),
                          Expanded(
                            child: _ResourceSlot(
                              iconAsset: ClashEpicAssets.clashGachaGemIcon,
                              primary: _formatAmount(gems),
                              accent: const Color(0xFF6EE7FF),
                              compact: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
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
  const _HeaderAvatar({required this.nickname, this.photoUrl});

  final String nickname;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final initial = nickname.trim().isEmpty
        ? '?'
        : nickname.trim().characters.first.toUpperCase();
    return Container(
      decoration: const BoxDecoration(shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child: photoUrl == null
          ? ColoredBox(
              color: XiColors.royalBlue.withValues(alpha: 0.35),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontFamily: 'Lumiare',
                    color: XiColors.warmWhite,
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                  ),
                ),
              ),
            )
          : Image.network(
              photoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => ColoredBox(
                color: XiColors.royalBlue.withValues(alpha: 0.35),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontFamily: 'Lumiare',
                      color: XiColors.warmWhite,
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                    ),
                  ),
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
    this.compact = false,
  });

  final String primary;
  final String? secondary;
  final Color accent;
  final String? iconAsset;
  final Widget? iconWidget;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconSize = compact ? 16.0 : 20.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          if (iconWidget != null)
            iconWidget!
          else if (iconAsset != null)
            Image.asset(
              iconAsset!,
              width: iconSize,
              height: iconSize,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          SizedBox(width: compact ? 5 : 7),
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
                    fontSize: compact ? 11.5 : 13,
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
                      fontSize: 9,
                      height: 1.05,
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
