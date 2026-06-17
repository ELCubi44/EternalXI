import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level_status.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level_type.dart';
import 'package:eternal_xi/features/clash/story/presentation/controllers/clash_story_controller.dart';
import 'package:eternal_xi/features/clash/story/presentation/widgets/clash_story_level_node.dart';
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
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: context.xiTextPrimary,
                ),
              ),
            ),
          ],
        ),
        if (saga != null) ...[
          Text(
            saga.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            saga.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.xiTextSecondary,
              height: 1.45,
            ),
          ),
        ],
        if (chapter != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.xiCardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.xiDivider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chapter.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  chapter.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.xiTextSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ..._levelNodes(context, controller, chapter.levels),
        ],
      ],
    );
  }

  List<Widget> _levelNodes(
    BuildContext context,
    ClashStoryController controller,
    List<ClashStoryLevel> levels,
  ) {
    final sorted = [...levels]..sort((a, b) => a.order.compareTo(b.order));
    final widgets = <Widget>[];

    for (var i = 0; i < sorted.length; i++) {
      final level = sorted[i];
      final status = controller.statusFor(level);
      widgets.add(
        ClashStoryLevelNode(
          level: level,
          status: status,
          onTap: status == ClashStoryLevelStatus.available
              ? () {
                  final route = level.type == ClashStoryLevelType.story
                      ? AppRoutes.clashStoryLevel(level.id)
                      : AppRoutes.clashStoryLevelPrepare(level.id);
                  context.push(route);
                }
              : null,
        ),
      );
      if (i < sorted.length - 1) {
        widgets.add(
          Center(
            child: Container(
              width: 3,
              height: 28,
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: context.xiDivider,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }
}

String clashStoryLevelTypeLabel(ClashStoryLevelType type, dynamic l10n) {
  return switch (type) {
    ClashStoryLevelType.story => l10n.clashStoryTypeStory,
    ClashStoryLevelType.match => l10n.clashStoryTypeMatch,
    ClashStoryLevelType.mixed => l10n.clashStoryTypeMixed,
  };
}

String clashStoryLevelStatusLabel(ClashStoryLevelStatus status, dynamic l10n) {
  return switch (status) {
    ClashStoryLevelStatus.locked => l10n.clashStoryStatusLocked,
    ClashStoryLevelStatus.available => l10n.clashStoryStatusAvailable,
    ClashStoryLevelStatus.completed => l10n.clashStoryStatusCompleted,
  };
}
