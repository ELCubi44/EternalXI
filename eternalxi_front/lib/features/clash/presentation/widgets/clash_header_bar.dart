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

/// Cabecera Clash: overlays calibrados al marco ornamental.
class ClashHeaderBar extends StatefulWidget {
  const ClashHeaderBar({super.key});

  @override
  State<ClashHeaderBar> createState() => _ClashHeaderBarState();
}

class _ClashHeaderBarState extends State<ClashHeaderBar> {
  final _energyService = ClashEnergyService();
  ClashEnergyWallet? _energy;
  Timer? _ticker;

  static const double _frameAspect = 800 / 298;

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
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
          child: Align(
            alignment: Alignment.topCenter,
            child: FractionallySizedBox(
              widthFactor: 0.90,
              child: AspectRatio(
                aspectRatio: _frameAspect,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final h = constraints.maxHeight;

                    final avatarSize = w * 0.215;
                    final avatarLeft = w * 0.058;
                    final avatarTop = h * 0.19;

                    // Misma columna útil para texto / XP / recursos.
                    final contentLeft = w * 0.345;
                    final contentRight = w * 0.055;

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
                        Positioned(
                          left: avatarLeft,
                          top: avatarTop,
                          width: avatarSize,
                          height: avatarSize,
                          child: InkWell(
                            onTap: _openProfile,
                            customBorder: const CircleBorder(),
                            child: _HeaderAvatar(
                              photoUrl: photoUrl,
                              nickname: displayName,
                            ),
                          ),
                        ),
                        Positioned(
                          left: contentLeft,
                          right: contentRight,
                          top: h * 0.16,
                          height: h * 0.255,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: w * 0.02),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        displayName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                          color: XiColors.warmWhite,
                                          fontWeight: FontWeight.w800,
                                          fontSize: (h * 0.092).clamp(
                                            11.5,
                                            13.5,
                                          ),
                                          height: 1.0,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'Nv. $nivel',
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                        color: XiColors.classicGold,
                                        fontWeight: FontWeight.w800,
                                        fontSize: (h * 0.078).clamp(
                                          11.0,
                                          12.5,
                                        ),
                                        height: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                                if (rango.isNotEmpty) ...[
                                  SizedBox(height: h * 0.025),
                                  Text(
                                    rango,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: XiColors.warmWhite.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontSize: (h * 0.055).clamp(8.5, 10.0),
                                      height: 1.0,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: contentLeft,
                          right: contentRight,
                          top: h * 0.455,
                          height: h * 0.12,
                          child: Align(
                            alignment: Alignment.center,
                            child: Stack(
                              alignment: const Alignment(0, 0.15),
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: SizedBox(
                                    height: (h * 0.07).clamp(6.5, 8.0),
                                    width: double.infinity,
                                    child: LinearProgressIndicator(
                                      value: xpFraction,
                                      backgroundColor: Colors.black.withValues(
                                        alpha: 0.45,
                                      ),
                                      color: XiColors.techCyan,
                                    ),
                                  ),
                                ),
                                Text(
                                  '$xpEn/$xpMax xp',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: XiColors.warmWhite,
                                    fontWeight: FontWeight.w800,
                                    fontSize: (h * 0.052).clamp(8.5, 10.0),
                                    height: 1,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black87,
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: w * 0.33,
                          right: w * 0.05,
                          top: h * 0.675,
                          height: h * 0.195,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              for (final slot in [
                                _ResourceSlot(
                                  iconAsset: ClashEpicAssets.clashEnergyIcon,
                                  primary: energy?.fractionLabel ?? '—/—',
                                  accent: XiColors.techCyan,
                                ),
                                _ResourceSlot(
                                  iconWidget: const MoneyCoinsIcon(size: 12),
                                  primary: _formatAmount(coins),
                                  accent: XiColors.classicGold,
                                ),
                                _ResourceSlot(
                                  iconAsset: ClashEpicAssets.clashGachaGemIcon,
                                  primary: _formatAmount(gems),
                                  accent: const Color(0xFF6EE7FF),
                                ),
                              ])
                                Expanded(
                                  child: Center(child: slot),
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
                    fontSize: 18,
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
                      fontSize: 18,
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
    this.iconAsset,
    this.iconWidget,
  });

  final String primary;
  final Color accent;
  final String? iconAsset;
  final Widget? iconWidget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconWidget != null)
            iconWidget!
          else if (iconAsset != null)
            Image.asset(
              iconAsset!,
              width: 12,
              height: 12,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          const SizedBox(width: 4),
          Text(
            primary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: context.xiTextPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 10,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
