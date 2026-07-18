import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level_status.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level_type.dart';
import 'package:flutter/material.dart';

String clashStoryLevelTypeLabel(
  ClashStoryLevelType type,
  AppLocalizations l10n,
) {
  return switch (type) {
    ClashStoryLevelType.story => l10n.clashStoryTypeStory,
    ClashStoryLevelType.match => l10n.clashStoryTypeMatch,
    ClashStoryLevelType.mixed => l10n.clashStoryTypeMixed,
  };
}

/// Libro = historia; campo = partido (o mixto).
IconData clashStoryLevelTypeIcon(ClashStoryLevelType type) {
  return switch (type) {
    ClashStoryLevelType.story => Icons.menu_book_rounded,
    ClashStoryLevelType.match ||
    ClashStoryLevelType.mixed => Icons.stadium_rounded,
  };
}

String clashStoryLevelStatusLabel(
  ClashStoryLevelStatus status,
  AppLocalizations l10n,
) {
  return switch (status) {
    ClashStoryLevelStatus.locked => l10n.clashStoryStatusLocked,
    ClashStoryLevelStatus.available => l10n.clashStoryStatusAvailable,
    ClashStoryLevelStatus.completed => l10n.clashStoryStatusCompleted,
  };
}

String clashStoryLevelActionLabel({
  required ClashStoryLevelType type,
  required ClashStoryLevelStatus status,
  required AppLocalizations l10n,
}) {
  if (status == ClashStoryLevelStatus.locked) {
    return l10n.clashStoryStatusLocked;
  }
  if (status == ClashStoryLevelStatus.completed) {
    return type == ClashStoryLevelType.story
        ? l10n.clashStoryReadAgain
        : l10n.clashStoryActionReplay;
  }
  return switch (type) {
    ClashStoryLevelType.story ||
    ClashStoryLevelType.mixed => l10n.clashStoryActionRead,
    ClashStoryLevelType.match => l10n.clashStoryActionPlay,
  };
}
