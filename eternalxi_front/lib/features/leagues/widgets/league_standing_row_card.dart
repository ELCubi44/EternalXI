import 'package:eternal_xi/app/localization/league_l10n.dart';
import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/localization/rewards_l10n.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/core/utils/league_money_format.dart';
import 'package:eternal_xi/features/rewards/utils/reward_formatters.dart';
import 'package:eternal_xi/data/models/league_standing_row.dart';
import 'package:flutter/material.dart';

class LeagueStandingRowCard extends StatefulWidget {
  const LeagueStandingRowCard({
    super.key,
    required this.row,
    required this.isFirstPlace,
    required this.isCurrentUser,
    this.onPeerTap,
    this.puntosFantasyJornada,
    this.puntosRecompensaJornada,
    this.showRoundFantasyPoints = true,
  });

  final LeagueStandingRow row;
  final bool isFirstPlace;
  final bool isCurrentUser;
  final VoidCallback? onPeerTap;
  final int? puntosFantasyJornada;
  final int? puntosRecompensaJornada;
  final bool showRoundFantasyPoints;

  @override
  State<LeagueStandingRowCard> createState() => _LeagueStandingRowCardState();
}

class _LeagueStandingRowCardState extends State<LeagueStandingRowCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _press, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final pos = row.posicion;
    final ll = context.leagueL10n;
    final ptsLabel = LeagueMoneyFormat.points(row.puntosTotales);
    final valorLabel = LeagueMoneyFormat.teamValue(row.valorTotalEquipo);
    final showRoundBreakdown =
        widget.puntosFantasyJornada != null &&
        widget.puntosRecompensaJornada != null;
    final showFantasyPts =
        showRoundBreakdown && widget.showRoundFantasyPoints;

    final pointsText = showFantasyPts
        ? LeagueMoneyFormat.points(widget.puntosFantasyJornada!.toDouble())
        : showRoundBreakdown && !widget.showRoundFantasyPoints
        ? ll.roundInProgress
        : ptsLabel;

    final medal = _medalConfig(context, pos, widget.isCurrentUser);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTapDown: widget.onPeerTap != null ? (_) => _press.forward() : null,
        onTapUp: widget.onPeerTap != null
            ? (_) {
                _press.reverse();
                widget.onPeerTap!();
              }
            : null,
        onTapCancel: widget.onPeerTap != null ? () => _press.reverse() : null,
        child: AnimatedBuilder(
          animation: _scale,
          builder: (_, child) =>
              Transform.scale(scale: _scale.value, child: child),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: medal.gradient,
              ),
              border: Border.all(color: medal.border, width: medal.borderWidth),
              boxShadow: [
                if (medal.glow != Colors.transparent)
                  BoxShadow(
                    color: medal.glow.withValues(alpha: 0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _PosBadge(position: pos, medal: medal),
                  const SizedBox(width: 10),
                  _Avatar(
                    nickname: row.nickname,
                    imageUrl: row.resolvedFotoUsuarioUrl(),
                    ringColor: medal.ring,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          row.nickname.isEmpty ? '—' : row.nickname,
                          style: TextStyle(
                            fontFamily: 'Lumiare',
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: medal.nameColor,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          valorLabel,
                          style: TextStyle(
                            fontFamily: 'Lumiare',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: context.xiTextPrimary,
                          ),
                        ),
                        if (showRoundBreakdown &&
                            (widget.puntosRecompensaJornada ?? 0) > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            '+${formatRewardPoints(widget.puntosRecompensaJornada!, unit: context.rewardsL10n.fichasUnit)}',
                            style: const TextStyle(
                              fontFamily: 'Lumiare',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: XiColors.classicGold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    pointsText,
                    style: TextStyle(
                      fontFamily: 'Lumiare',
                      fontSize: showRoundBreakdown && !showFantasyPts ? 12 : 28,
                      fontWeight: FontWeight.w900,
                      color: showRoundBreakdown && !showFantasyPts
                          ? context.xiTextPrimary
                          : medal.ptsColor,
                      height: 1.0,
                      shadows: medal.ptsShadow,
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

// ── Medal config ──────────────────────────────────────────────────────────────

class _MedalConfig {
  final List<Color> gradient;
  final Color border;
  final double borderWidth;
  final Color glow;
  final Color ring;
  final Color nameColor;
  final Color ptsColor;
  final Color badgeBg;
  final Color badgeFg;
  final List<Shadow>? ptsShadow;

  const _MedalConfig({
    required this.gradient,
    required this.border,
    required this.borderWidth,
    required this.glow,
    required this.ring,
    required this.nameColor,
    required this.ptsColor,
    required this.badgeBg,
    required this.badgeFg,
    this.ptsShadow,
  });
}

_MedalConfig _medalConfig(BuildContext context, int pos, bool isMe) {
  final dark = context.isXiDark;
  if (pos == 1) {
    return _MedalConfig(
      gradient: context.xiStandingGoldGradient,
      border: XiColors.classicGold,
      borderWidth: 1.8,
      glow: XiColors.classicGold,
      ring: XiColors.classicGold,
      nameColor: dark ? XiColors.warmWhite : XiColors.nightBlue,
      ptsColor: XiColors.classicGold,
      badgeBg: XiColors.classicGold,
      badgeFg: dark ? const Color(0xFF1A1200) : XiColors.nightBlue,
      ptsShadow: [
        Shadow(
          color: XiColors.classicGold.withValues(alpha: dark ? 0.66 : 0.35),
          blurRadius: dark ? 16 : 10,
        ),
      ],
    );
  }
  if (pos == 2) {
    return _MedalConfig(
      gradient: context.xiStandingSilverGradient,
      border: XiColors.steelGray,
      borderWidth: 1.5,
      glow: XiColors.steelGray.withValues(alpha: dark ? 1 : 0.5),
      ring: XiColors.steelGray,
      nameColor: dark ? XiColors.warmWhite : XiColors.nightBlue,
      ptsColor: dark ? XiColors.warmWhite : XiColors.nightBlue,
      badgeBg: XiColors.steelGray,
      badgeFg: dark ? const Color(0xFF0F1318) : XiColors.warmWhite,
      ptsShadow: [
        Shadow(
          color: XiColors.steelGray.withValues(alpha: dark ? 0.33 : 0.2),
          blurRadius: 12,
        ),
      ],
    );
  }
  if (pos == 3) {
    return _MedalConfig(
      gradient: context.xiStandingBronzeGradient,
      border: XiColors.sandGold,
      borderWidth: 1.5,
      glow: XiColors.sandGold.withValues(alpha: dark ? 1 : 0.55),
      ring: XiColors.sandGold,
      nameColor: dark ? XiColors.warmWhite : XiColors.nightBlue,
      ptsColor: XiColors.sandGold,
      badgeBg: XiColors.sandGold,
      badgeFg: dark ? const Color(0xFF1A0C00) : XiColors.nightBlue,
      ptsShadow: [
        Shadow(
          color: XiColors.sandGold.withValues(alpha: dark ? 0.33 : 0.22),
          blurRadius: 12,
        ),
      ],
    );
  }
  if (isMe) {
    return _MedalConfig(
      gradient: context.xiStandingMeGradient,
      border: XiColors.royalBlue.withValues(alpha: 0.55),
      borderWidth: 1.2,
      glow: XiColors.royalBlue,
      ring: XiColors.royalBlue,
      nameColor: dark ? XiColors.warmWhite : XiColors.nightBlue,
      ptsColor: dark ? XiColors.warmWhite : XiColors.nightBlue,
      badgeBg: XiColors.royalBlue,
      badgeFg: XiColors.warmWhite,
      ptsShadow: null,
    );
  }
  return _MedalConfig(
    gradient: context.xiStandingDefaultGradient,
    border: context.xiBorderSubtle,
    borderWidth: 1.0,
    glow: Colors.transparent,
    ring: XiColors.steelGray,
    nameColor: context.xiTextPrimary,
    ptsColor: context.xiTextPrimary,
    badgeBg: dark ? const Color(0xFF1C2E52) : const Color(0xFFE8ECF4),
    badgeFg: context.xiTextSecondary,
    ptsShadow: null,
  );
}

// ── Position badge ────────────────────────────────────────────────────────────

class _PosBadge extends StatelessWidget {
  final int position;
  final _MedalConfig medal;
  const _PosBadge({required this.position, required this.medal});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(shape: BoxShape.circle, color: medal.badgeBg),
      alignment: Alignment.center,
      child: Text(
        '$position',
        style: TextStyle(
          fontFamily: 'Lumiare',
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: medal.badgeFg,
          height: 1.0,
        ),
      ),
    );
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String nickname;
  final String? imageUrl;
  final Color ringColor;
  const _Avatar({
    required this.nickname,
    required this.imageUrl,
    required this.ringColor,
  });

  @override
  Widget build(BuildContext context) {
    final initial = nickname.trim().isEmpty
        ? '?'
        : nickname.trim().substring(0, 1).toUpperCase();
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: 2),
      ),
      child: ClipOval(
        child: imageUrl != null
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _AvatarFallback(initial: initial),
              )
            : _AvatarFallback(initial: initial),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String initial;
  const _AvatarFallback({required this.initial});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: XiColors.navyBlue,
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontFamily: 'Lumiare',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: XiColors.warmWhite,
          ),
        ),
      ),
    );
  }
}
