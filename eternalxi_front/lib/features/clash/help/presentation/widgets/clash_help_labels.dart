import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/help/domain/clash_help_topic.dart';
import 'package:flutter/material.dart';

IconData clashHelpIconForName(String name) {
  return switch (name) {
    'info' => Icons.info_outline_rounded,
    'style' => Icons.style_outlined,
    'auto_awesome' => Icons.auto_awesome_outlined,
    'groups' => Icons.groups_outlined,
    'sports_soccer' => Icons.sports_soccer_outlined,
    'battery_charging_full' => Icons.battery_charging_full_outlined,
    'flash_on' => Icons.flash_on_outlined,
    'menu_book' => Icons.menu_book_outlined,
    'casino' => Icons.casino_outlined,
    'storefront' => Icons.storefront_outlined,
    'card_giftcard' => Icons.card_giftcard_outlined,
    _ => Icons.help_outline_rounded,
  };
}

String clashHelpCategoryLabel(
  ClashHelpCategory category,
  AppLocalizations l10n,
) {
  return switch (category) {
    ClashHelpCategory.gettingStarted => l10n.clashHelpCategoryGettingStarted,
    ClashHelpCategory.cards => l10n.clashHelpCategoryCards,
    ClashHelpCategory.match => l10n.clashHelpCategoryMatch,
    ClashHelpCategory.progress => l10n.clashHelpCategoryProgress,
    ClashHelpCategory.rewards => l10n.clashHelpCategoryRewards,
  };
}
