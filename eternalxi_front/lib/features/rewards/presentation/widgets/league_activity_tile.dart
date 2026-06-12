import 'package:eternal_xi/app/localization/rewards_l10n.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/data/models/league_activity_event.dart';
import 'package:eternal_xi/shared/widgets/coach_roulette_icon.dart';
import 'package:eternal_xi/shared/widgets/pack_envelope_icon.dart';
import 'package:eternal_xi/shared/widgets/reward_cards_icon.dart';
import 'package:flutter/material.dart';

class LeagueActivityTile extends StatelessWidget {
  const LeagueActivityTile({super.key, required this.event});

  final LeagueActivityEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rl10n = context.rewardsL10n;
    final dateStr = _formatDate(context, event.creadoEn);
    final tipo = event.tipo.trim().toUpperCase();
    final icon = _iconForType(tipo);
    final isPackOpened = tipo == 'PACK_OPENED';
    final isCoachRoulette =
        tipo == 'COACH_ROULETTE' || tipo == 'COACH_ROULETTE_SPIN';
    final isCardRedeemed = tipo == 'CARD_REDEEMED';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: context.xiCompactCardGradient,
        ),
        border: Border.all(color: context.xiBorderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: icon.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: isPackOpened
                ? const PackEnvelopeIcon(size: 22)
                : isCoachRoulette
                    ? const CoachRouletteIcon(size: 22)
                    : isCardRedeemed
                        ? const RewardCardsIcon(size: 22)
                        : Icon(icon.icon, size: 18, color: icon.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (event.actorNickname.isNotEmpty) ...[
                      Text(
                        event.actorNickname,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: context.xiTextPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        dateStr,
                        textAlign: TextAlign.end,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: context.xiTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  rl10n.activityMessage(event),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.xiTextPrimary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(BuildContext context, DateTime? utc) {
    if (utc == null) return '—';
    final local = utc.toLocal();
    final now = DateTime.now();
    final rl10n = context.rewardsL10n;
    final relative = rl10n.relativeTime(local, now);
    if (relative.isNotEmpty) return relative;
    final loc = MaterialLocalizations.of(context);
    return loc.formatShortDate(local);
  }

  static _ActivityIcon _iconForType(String tipo) {
    switch (tipo.trim().toUpperCase()) {
      case 'CARD_REDEEMED':
        return const _ActivityIcon(Icons.auto_awesome_rounded, Color(0xFFFFD54F));
      case 'COACH_ROULETTE':
      case 'COACH_ROULETTE_SPIN':
        return const _ActivityIcon(Icons.casino_rounded, Color(0xFFCE93D8));
      case 'PACK_OPENED':
        return const _ActivityIcon(Icons.mail_rounded, Color(0xFF81D4FA));
      case 'ADMIN_KICK':
        return const _ActivityIcon(Icons.person_remove_rounded, Color(0xFFEF9A9A));
      case 'ROUND_FINISHED':
        return const _ActivityIcon(Icons.emoji_events_rounded, Color(0xFFA5D6A7));
      case 'PLAYER_SOLD_WITH_CARD':
        return const _ActivityIcon(Icons.attach_money_rounded, Color(0xFF81C784));
      case 'DIRECT_CLAUSE_EXECUTED':
        return const _ActivityIcon(Icons.gavel_rounded, Color(0xFFFFAB91));
      case 'PLAYER_PROTECTION_APPLIED':
        return const _ActivityIcon(Icons.shield_rounded, Color(0xFF81D4FA));
      case 'LEAGUE_POINTS_BONUS_APPLIED':
        return const _ActivityIcon(Icons.star_rounded, Color(0xFFFFD54F));
      case 'VALUE_RECOVERY_APPLIED':
      case 'VALUE_BOOST_APPLIED':
        return const _ActivityIcon(Icons.trending_up_rounded, Color(0xFF80CBC4));
      default:
        return const _ActivityIcon(Icons.info_outline_rounded, Color(0xFF90A4AE));
    }
  }
}

class _ActivityIcon {
  const _ActivityIcon(this.icon, this.color);
  final IconData icon;
  final Color color;
}
