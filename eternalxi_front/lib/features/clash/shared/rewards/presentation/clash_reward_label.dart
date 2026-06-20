import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/shared/rewards/domain/clash_reward_ids.dart';

/// Labels legibles compartidos para recompensas Clash (Fase 58).
abstract final class ClashRewardLabel {
  static String itemIdLabel(AppLocalizations l10n, String id) {
    return switch (id) {
      'basic-training-manual' => l10n.clashRewardLabelBasicTrainingManual,
      'advanced-training-manual' => l10n.clashRewardLabelAdvancedTrainingManual,
      'master-training-manual' => l10n.clashRewardLabelMasterTrainingManual,
      'basic-technique-book' => l10n.clashRewardLabelBasicTechniqueBook,
      'advanced-technique-book' => l10n.clashRewardLabelAdvancedTechniqueBook,
      'master-technique-book' => l10n.clashRewardLabelMasterTechniqueBook,
      'insignia-r' => l10n.clashRewardLabelInsigniaR,
      'insignia-sr' => l10n.clashRewardLabelInsigniaSr,
      'starter-single-ticket' => l10n.clashRewardLabelStarterTicket,
      _ => id,
    };
  }

  static String shopGrantLabel(AppLocalizations l10n, String grantLabel) {
    final normalized = grantLabel.trim();
    if (normalized.isEmpty) {
      return normalized;
    }
    return normalized;
  }

  static String shopGrantOrItemLabel(
    AppLocalizations l10n, {
    required String id,
    required String grantLabel,
  }) {
    if (ClashRewardIds.isKnownGrantableItemId(id)) {
      return itemIdLabel(l10n, id);
    }
    final fromGrant = grantLabel.trim();
    if (fromGrant.isNotEmpty) {
      return fromGrant;
    }
    return id;
  }

  static bool isKnownItemId(String id) =>
      ClashRewardIds.isKnownGrantableItemId(id);
}
