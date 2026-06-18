import 'package:eternal_xi/features/clash/achievements/domain/clash_achievement_reward.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_json_helpers.dart';
import 'package:eternal_xi/features/clash/gifts/domain/clash_gift_status.dart';

/// Definición de regalo desde catálogo JSON local (Fase 32).
class ClashGift {
  const ClashGift({
    required this.id,
    required this.title,
    required this.message,
    required this.rewards,
    this.availableFrom,
    this.expiresAt,
    this.isPinned = false,
  });

  final String id;
  final String title;
  final String message;
  final ClashAchievementReward rewards;
  final DateTime? availableFrom;
  final DateTime? expiresAt;
  final bool isPinned;

  factory ClashGift.fromJson(Map<String, dynamic> json) {
    final rewardsRaw = json['rewards'] as Map<String, dynamic>? ?? const {};
    return ClashGift(
      id: clashRequireString(json['id'], 'id'),
      title: clashRequireString(json['title'], 'title'),
      message: clashRequireString(json['message'], 'message'),
      rewards: ClashAchievementReward.fromJson(rewardsRaw),
      availableFrom: _parseOptionalDate(json['availableFrom']),
      expiresAt: _parseOptionalDate(json['expiresAt']),
      isPinned: json['isPinned'] == true,
    );
  }

  static DateTime? _parseOptionalDate(Object? value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value.toString());
  }

  ClashGiftStatus resolveStatus({
    required bool claimed,
    required DateTime now,
  }) {
    if (claimed) {
      return ClashGiftStatus.claimed;
    }
    if (expiresAt != null && now.isAfter(expiresAt!)) {
      return ClashGiftStatus.expired;
    }
    return ClashGiftStatus.available;
  }

  bool isClaimableAt(DateTime now, {required bool claimed}) {
    if (claimed) {
      return false;
    }
    if (resolveStatus(claimed: claimed, now: now) !=
        ClashGiftStatus.available) {
      return false;
    }
    if (availableFrom != null && now.isBefore(availableFrom!)) {
      return false;
    }
    return true;
  }
}

/// Regalo con estado en el buzón.
class ClashGiftEntry {
  const ClashGiftEntry({
    required this.gift,
    required this.status,
    required this.canClaim,
  });

  final ClashGift gift;
  final ClashGiftStatus status;
  final bool canClaim;
}

/// Resumen para tarjeta de Inicio y cabecera del buzón.
class ClashGiftsSummary {
  const ClashGiftsSummary({
    required this.totalGifts,
    required this.pendingCount,
    required this.claimedCount,
    this.latestPendingTitle,
  });

  final int totalGifts;
  final int pendingCount;
  final int claimedCount;
  final String? latestPendingTitle;

  bool get hasPending => pendingCount > 0;
}
