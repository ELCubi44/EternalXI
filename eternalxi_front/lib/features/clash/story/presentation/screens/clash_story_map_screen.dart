import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level_status.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level_type.dart';
import 'package:eternal_xi/features/clash/story/presentation/controllers/clash_story_controller.dart';
import 'package:eternal_xi/features/clash/story/presentation/widgets/clash_story_chapter_card.dart';
import 'package:eternal_xi/features/clash/story/presentation/widgets/clash_story_level_card.dart';
import 'package:eternal_xi/features/clash/story/presentation/widgets/clash_story_progress_header.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ClashStoryMapScreen extends StatefulWidget {
  const ClashStoryMapScreen({super.key});

  @override
  State<ClashStoryMapScreen> createState() => _ClashStoryMapScreenState();
}

class _ClashStoryMapScreenState extends State<ClashStoryMapScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = context.read<ClashStoryController>();
      if (controller.state == ClashStoryLoadState.idle) {
        await controller.load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = context.watch<ClashStoryController>();

    if (controller.state == ClashStoryLoadState.loading ||
        controller.state == ClashStoryLoadState.idle) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.state == ClashStoryLoadState.error) {
      return Center(
        child: Text(controller.errorMessage ?? l10n.clashStoryLoadError),
      );
    }

    final saga = controller.sagas.isNotEmpty ? controller.sagas.first : null;
    final chapter = controller.activeChapter;
    final levels = chapter == null
        ? const <ClashStoryLevel>[]
        : ([...chapter.levels]..sort((a, b) => a.order.compareTo(b.order)));
    final completedCount = levels
        .where((level) => controller.progress.isLevelCompleted(level.id))
        .length;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => context.go(AppRoutes.clash),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            Expanded(
              child: Text(
                l10n.clashHomeStory,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: context.xiTextPrimary,
                ),
              ),
            ),
          ],
        ),
        if (saga != null) ...[
          const SizedBox(height: 4),
          Text(
            saga.title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            saga.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.xiTextSecondary,
              height: 1.45,
            ),
          ),
        ],
        if (chapter != null) ...[
          const SizedBox(height: 16),
          ClashStoryProgressHeader(
            completedLevels: completedCount,
            totalLevels: levels.length,
            chapterTitle: chapter.title,
          ),
          const SizedBox(height: 14),
          ClashStoryChapterCard(
            title: chapter.title,
            description: chapter.description,
            completedLevels: completedCount,
            totalLevels: levels.length,
          ),
          const SizedBox(height: 18),
          for (final level in levels)
            ClashStoryLevelCard(
              level: level,
              status: controller.statusFor(level),
              progress: controller.progress,
              onAction: _canOpen(controller.statusFor(level))
                  ? () => _openLevel(context, level)
                  : null,
            ),
        ],
      ],
    );
  }

  bool _canOpen(ClashStoryLevelStatus status) {
    return status == ClashStoryLevelStatus.available ||
        status == ClashStoryLevelStatus.completed;
  }

  void _openLevel(BuildContext context, ClashStoryLevel level) {
    final route = switch (level.type) {
      ClashStoryLevelType.story => AppRoutes.clashStoryLevel(level.id),
      ClashStoryLevelType.match ||
      ClashStoryLevelType.mixed => AppRoutes.clashStoryLevelPrepare(level.id),
    };
    context.push(route);
  }
}
