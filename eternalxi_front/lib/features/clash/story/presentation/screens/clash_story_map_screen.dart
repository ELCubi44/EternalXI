import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level_status.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level_type.dart';
import 'package:eternal_xi/features/clash/story/presentation/controllers/clash_story_controller.dart';
import 'package:eternal_xi/features/clash/story/presentation/widgets/clash_story_level_card.dart';
import 'package:eternal_xi/features/clash/story/presentation/widgets/clash_story_progress_header.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Listado numerado de misiones de historia (libro = story, campo = partido).
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
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.clashHomeStory),
          leading: IconButton(
            onPressed: () => context.go(AppRoutes.clash),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (controller.state == ClashStoryLoadState.error) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.clashHomeStory),
          leading: IconButton(
            onPressed: () => context.go(AppRoutes.clash),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        body: Center(
          child: Text(controller.errorMessage ?? l10n.clashStoryLoadError),
        ),
      );
    }

    final chapter = controller.activeChapter;
    final levels = chapter == null
        ? const <ClashStoryLevel>[]
        : ([...chapter.levels]..sort((a, b) => a.order.compareTo(b.order)));
    final completed = levels
        .where((l) => controller.statusFor(l) == ClashStoryLevelStatus.completed)
        .length;
    final progress = controller.progress;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.clashHomeStory),
        leading: IconButton(
          onPressed: () => context.go(AppRoutes.clash),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          if (chapter != null) ...[
            ClashStoryProgressHeader(
              completedLevels: completed,
              totalLevels: levels.length,
              chapterTitle: chapter.title,
            ),
            const SizedBox(height: 16),
          ],
          if (levels.isEmpty)
            Text(
              l10n.clashStoryLoadError,
              textAlign: TextAlign.center,
            )
          else
            for (final level in levels)
              ClashStoryLevelCard(
                level: level,
                status: controller.statusFor(level),
                progress: progress,
                onAction: _canOpen(controller.statusFor(level))
                    ? () => _openLevel(context, level)
                    : null,
              ),
        ],
      ),
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
