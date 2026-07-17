import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/core/constants/api_constants.dart';
import 'package:eternal_xi/features/auth/controller/auth_controller.dart';
import 'package:eternal_xi/features/clash/cards/presentation/epic/clash_epic_assets.dart';
import 'package:eternal_xi/features/profile/controller/account_progress_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Cabecera Clash: avatar grande + XP saliendo del círculo (sin recursos).
class ClashHeaderBar extends StatefulWidget {
  const ClashHeaderBar({super.key});

  @override
  State<ClashHeaderBar> createState() => _ClashHeaderBarState();
}

class _ClashHeaderBarState extends State<ClashHeaderBar> {
  static const double _avatarSize = 72;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final auth = context.read<AuthController>();
    final progressCtrl = context.read<AccountProgressController>();
    final userId = auth.currentUser?.id;
    if (userId != null) {
      await progressCtrl.loadProgress(userId);
    }
  }

  void _openProfile() {
    context.push('${AppRoutes.profile}?from=clash');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthController>().currentUser;
    final progress = context.watch<AccountProgressController>().progress;
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

    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(ClashEpicAssets.clashHeaderBg),
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.35),
                Colors.black.withValues(alpha: 0.55),
                Colors.black.withValues(alpha: 0.75),
              ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 14, 14),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: _avatarSize - 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Expanded(
                              child: Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: XiColors.warmWhite,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Nivel $nivel',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: XiColors.warmWhite,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$xpEn/$xpMax exp',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: XiColors.warmWhite.withValues(alpha: 0.78),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: xpFraction,
                            minHeight: 9,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.14,
                            ),
                            color: XiColors.techCyan,
                          ),
                        ),
                        if (rango.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            rango,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: XiColors.warmWhite.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: InkWell(
                        onTap: _openProfile,
                        customBorder: const CircleBorder(),
                        child: _HeaderAvatar(
                          size: _avatarSize,
                          photoUrl: photoUrl,
                          nickname: displayName,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
          color: XiColors.classicGold.withValues(alpha: 0.8),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: XiColors.techCyan.withValues(alpha: 0.22),
            blurRadius: 14,
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
