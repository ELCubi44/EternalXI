import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/help/data/clash_help_repository.dart';
import 'package:eternal_xi/features/clash/help/domain/clash_help_topic.dart';
import 'package:eternal_xi/features/clash/help/presentation/widgets/clash_help_labels.dart';
import 'package:eternal_xi/features/clash/presentation/clash_navigation_controller.dart';
import 'package:eternal_xi/features/clash/story/presentation/widgets/clash_story_level_status_chip.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Rutas internas conocidas de la guía Clash.
const clashHelpKnownRoutes = <String>{
  AppRoutes.clash,
  AppRoutes.clashStory,
  AppRoutes.clashEvents,
  AppRoutes.clashTeam7v7,
  AppRoutes.clashCards,
  AppRoutes.clashInventory,
  AppRoutes.clashMissions,
  AppRoutes.clashAchievements,
  AppRoutes.clashWeeklyMissions,
  AppRoutes.clashNews,
  AppRoutes.clashGifts,
  AppRoutes.clashSummonHistory,
  'clash:tab:summon',
  'clash:tab:shop',
};

class ClashHelpTopicScreen extends StatefulWidget {
  const ClashHelpTopicScreen({required this.topicId, super.key});

  final String topicId;

  @override
  State<ClashHelpTopicScreen> createState() => _ClashHelpTopicScreenState();
}

class _ClashHelpTopicScreenState extends State<ClashHelpTopicScreen> {
  ClashHelpTopic? _topic;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final topic = await context.read<ClashHelpRepository>().findById(
      widget.topicId,
    );
    if (mounted) {
      setState(() {
        _topic = topic;
        _loading = false;
      });
    }
  }

  void _openRelatedRoute(String path) {
    if (!clashHelpKnownRoutes.contains(path)) {
      return;
    }
    switch (path) {
      case 'clash:tab:summon':
        context.read<ClashNavigationController>().selectTab(2);
        context.go(AppRoutes.clash);
      case 'clash:tab:shop':
        context.read<ClashNavigationController>().selectTab(3);
        context.go(AppRoutes.clash);
      default:
        context.push(path);
    }
  }

  String _relatedRouteLabel(String path, AppLocalizations l10n) {
    return switch (path) {
      AppRoutes.clashStory => l10n.clashHelpGoStory,
      AppRoutes.clashEvents => l10n.clashHelpGoEvents,
      AppRoutes.clashTeam7v7 => l10n.clashHelpGoTeam,
      AppRoutes.clashCards => l10n.clashHelpGoCards,
      AppRoutes.clashInventory => l10n.clashHelpGoInventory,
      AppRoutes.clashMissions => l10n.clashHelpGoMissions,
      AppRoutes.clashAchievements => l10n.clashHelpGoAchievements,
      AppRoutes.clashNews => l10n.clashHelpGoNews,
      AppRoutes.clashGifts => l10n.clashHelpGoGifts,
      'clash:tab:summon' => l10n.clashHelpGoSummon,
      'clash:tab:shop' => l10n.clashHelpGoShop,
      _ => path,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final topic = _topic;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (topic == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.clashHelpTitle)),
        body: Center(child: Text(l10n.clashHelpTopicNotFound)),
      );
    }

    final relatedRoutes = topic.relatedRoutes
        .where((route) => clashHelpKnownRoutes.contains(route.path))
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.clashHelpTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.12,
                ),
                child: Icon(
                  clashHelpIconForName(topic.icon),
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        ),
                    ),
                    const SizedBox(height: 8),
                    ClashStoryLevelStatusChip(
                      label: clashHelpCategoryLabel(topic.category, l10n),
                      kind: ClashStoryLevelChipKind.type,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            topic.summary,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: context.xiTextSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          ...topic.sections.map((section) => _SectionCard(section: section)),
          if (relatedRoutes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              l10n.clashHelpRelatedLinks,
              style: theme.textTheme.titleSmall?.copyWith(
                ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: relatedRoutes
                  .map((route) {
                    final label =
                        route.label ?? _relatedRouteLabel(route.path, l10n);
                    return OutlinedButton(
                      onPressed: () => _openRelatedRoute(route.path),
                      child: Text(label),
                    );
                  })
                  .toList(growable: false),
            ),
          ],
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => context.pop(),
            child: Text(l10n.clashHelpBack),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section});

  final ClashHelpSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.xiDivider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.title,
              style: theme.textTheme.titleSmall?.copyWith(
                ),
            ),
            if (section.body.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                section.body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: context.xiTextSecondary,
                  height: 1.45,
                ),
              ),
            ],
            if (section.bullets.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...section.bullets.map(
                (bullet) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          ),
                      ),
                      Expanded(
                        child: Text(
                          bullet,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
