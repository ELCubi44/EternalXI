import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level_status.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level_type.dart';
import 'package:eternal_xi/features/clash/story/presentation/controllers/clash_story_controller.dart';
import 'package:eternal_xi/features/clash/story/presentation/widgets/clash_story_mission_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Listado fino de misiones: solo las desbloqueadas; la siguiente aparece al completar.
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

  /// Completadas + la actual disponible; las bloqueadas aún no se muestran.
  List<ClashStoryLevel> _visibleLevels(
    List<ClashStoryLevel> levels,
    ClashStoryController controller,
  ) {
    final visible = <ClashStoryLevel>[];
    for (final level in levels) {
      final status = controller.statusFor(level);
      if (status == ClashStoryLevelStatus.locked) break;
      visible.add(level);
    }
    return visible;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final controller = context.watch<ClashStoryController>();

    if (controller.state == ClashStoryLoadState.loading ||
        controller.state == ClashStoryLoadState.idle) {
      return Scaffold(
        appBar: AppBar(
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
    final visible = _visibleLevels(levels, controller);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go(AppRoutes.clash),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(
            l10n.clashHomeStory,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: context.xiTextPrimary,
            ),
          ),
          if (chapter != null) ...[
            const SizedBox(height: 4),
            Text(
              chapter.title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.xiTextSecondary,
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (visible.isEmpty)
            Text(
              l10n.clashStoryLoadError,
              textAlign: TextAlign.center,
            )
          else
            for (final level in visible)
              ClashStoryMissionBar(
                level: level,
                status: controller.statusFor(level),
                onTap: () => _openLevel(context, level),
              ),
        ],
      ),
    );
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
