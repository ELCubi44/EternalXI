import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_display_item.dart';

/// Variante de feedback al conceder recompensas (Fase 59).
enum ClashRewardFeedbackKind { success, partial, failure }

/// Mensaje listo para snackbar o bottom sheet (Fase 59).
class ClashRewardFeedbackMessage {
  const ClashRewardFeedbackMessage({
    required this.kind,
    required this.title,
    this.subtitle,
    this.items = const [],
    this.compactSummary,
  });

  final ClashRewardFeedbackKind kind;
  final String title;
  final String? subtitle;
  final List<ClashRewardDisplayItem> items;
  final String? compactSummary;

  bool get hasItems => items.isNotEmpty;
  bool get useCompactPresentation => items.length <= 2;
}
