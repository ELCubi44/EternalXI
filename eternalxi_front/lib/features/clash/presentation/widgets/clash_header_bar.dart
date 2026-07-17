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
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
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

                    final avatarSize = w * 0.245;
                    // Lados OK; solo subir un pelín.
                    final avatarLeft = w * 0.065;
                    final avatarTop = h * 0.165;

                    // Nombre + nivel: muy poco abajo y un poco a la derecha.
                    final nameLeft = w * 0.34;
                    final nameRight = w * 0.045;

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
                        // Nombre + nivel: muy poco abajo y un poco a la derecha.
                        Positioned(
                          left: nameLeft,
                          right: nameRight,
                          top: h * 0.225,
                          height: h * 0.175,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: w * 0.015),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: XiColors.warmWhite,
                                      fontWeight: FontWeight.w800,
                                      fontSize: (h * 0.10).clamp(12.0, 14.0),
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Nv. $nivel',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: XiColors.classicGold,
                                    fontWeight: FontWeight.w800,
                                    fontSize: (h * 0.085).clamp(11.0, 13.0),
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // XP: misma forma chaflanada; un pelín más a la izquierda.
                        Positioned(
                          left: w * 0.372,
                          right: w * 0.098,
                          top: h * 0.46,
                          height: h * 0.135,
                          child: Center(
                            child: _ChamferedXpBar(
                              fraction: xpFraction,
                              label: '$xpEn/$xpMax xp',
                              height: (h * 0.095).clamp(10.0, 13.0),
                              labelStyle: theme.textTheme.labelSmall?.copyWith(
                                color: XiColors.warmWhite,
                                fontWeight: FontWeight.w800,
                                fontSize: (h * 0.055).clamp(9.0, 10.5),
                                height: 1,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black87,
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Recursos: un pelín abajo a la izquierda.
                        Positioned(
                          left: w * 0.315,
                          right: w * 0.055,
                          top: h * 0.695,
                          height: h * 0.18,
                          child: Row(
                            children: [
                              Expanded(
                                child: _ResourceSlot(
                                  iconAsset: ClashEpicAssets.clashEnergyIcon,
                                  primary: energy?.fractionLabel ?? '—/—',
                                  accent: XiColors.techCyan,
                                ),
                              ),
                              Expanded(
                                child: _ResourceSlot(
                                  iconWidget: const MoneyCoinsIcon(size: 12),
                                  primary: _formatAmount(coins),
                                  accent: XiColors.classicGold,
                                ),
                              ),
                              Expanded(
                                child: _ResourceSlot(
                                  iconAsset: ClashEpicAssets.clashGachaGemIcon,
                                  primary: _formatAmount(gems),
                                  accent: const Color(0xFF6EE7FF),
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

/// Barra XP en octógono alargado (esquinas a 45°), como los huecos de recursos.
class _ChamferedXpBar extends StatelessWidget {
  const _ChamferedXpBar({
    required this.fraction,
    required this.label,
    required this.height,
    this.labelStyle,
  });

  final double fraction;
  final String label;
  final double height;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final cut = height * 0.42;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _ChamferedRectPainter(
                fill: Colors.black.withValues(alpha: 0.55),
                stroke: XiColors.techCyan.withValues(alpha: 0.55),
                strokeWidth: 1.1,
                cut: cut,
              ),
            ),
          ),
          Positioned.fill(
            child: ClipPath(
              clipper: _ChamferedRectClipper(cut: cut),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: fraction.clamp(0.0, 1.0),
                  heightFactor: 1,
                  child: const ColoredBox(color: XiColors.techCyan),
                ),
              ),
            ),
          ),
          Text(label, textAlign: TextAlign.center, style: labelStyle),
        ],
      ),
    );
  }
}

class _ChamferedRectClipper extends CustomClipper<Path> {
  const _ChamferedRectClipper({required this.cut});

  final double cut;

  @override
  Path getClip(Size size) => _chamferedRectPath(size, cut);

  @override
  bool shouldReclip(covariant _ChamferedRectClipper oldClipper) =>
      oldClipper.cut != cut;
}

class _ChamferedRectPainter extends CustomPainter {
  const _ChamferedRectPainter({
    required this.fill,
    required this.stroke,
    required this.strokeWidth,
    required this.cut,
  });

  final Color fill;
  final Color stroke;
  final double strokeWidth;
  final double cut;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _chamferedRectPath(size, cut);
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeJoin = StrokeJoin.miter,
    );
  }

  @override
  bool shouldRepaint(covariant _ChamferedRectPainter oldDelegate) =>
      oldDelegate.fill != fill ||
      oldDelegate.stroke != stroke ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.cut != cut;
}

Path _chamferedRectPath(Size size, double cut) {
  final w = size.width;
  final h = size.height;
  final c = cut.clamp(0.0, h / 2).toDouble();
  return Path()
    ..moveTo(c, 0)
    ..lineTo(w - c, 0)
    ..lineTo(w, c)
    ..lineTo(w, h - c)
    ..lineTo(w - c, h)
    ..lineTo(c, h)
    ..lineTo(0, h - c)
    ..lineTo(0, c)
    ..close();
}
