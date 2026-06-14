import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/features/clash/cards/presentation/controllers/clash_cards_controller.dart';
import 'package:eternal_xi/features/clash/story/presentation/controllers/clash_story_controller.dart';
import 'package:eternal_xi/features/clash/story/presentation/screens/clash_story_reward_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ClashStoryLevelReaderScreen extends StatefulWidget {
  const ClashStoryLevelReaderScreen({required this.levelId, super.key});

  final String levelId;

  @override
  State<ClashStoryLevelReaderScreen> createState() =>
      _ClashStoryLevelReaderScreenState();
}

class _ClashStoryLevelReaderScreenState
    extends State<ClashStoryLevelReaderScreen> {
  var _initialized = false;
  var _loading = true;
  var _blocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  Future<void> _prepare() async {
    final controller = context.read<ClashStoryController>();
    if (controller.state == ClashStoryLoadState.idle) {
      await controller.load();
    }
    final ok = await controller.prepareLevel(widget.levelId);
    if (!mounted) {
      return;
    }
    setState(() {
      _initialized = true;
      _loading = false;
      _blocked = !ok;
    });
  }

  Future<void> _onNext(ClashStoryController controller) async {
    if (controller.hasNextScene) {
      controller.nextScene();
      return;
    }

    final result = await controller.finishActiveLevel();
    if (!mounted || result == null) {
      return;
    }

    final cardsController = context.read<ClashCardsController>();
    await cardsController.reloadOwnedCards();
    if (!mounted) {
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<ClashStoryController>.value(
          value: controller,
          child: ClashStoryRewardScreen(levelId: widget.levelId),
        ),
      ),
    );

    if (mounted) {
      context.go(AppRoutes.clashStory);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = context.watch<ClashStoryController>();

    if (_loading || !_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_blocked || controller.activeLevel == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.clashStoryLevelBlockedTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.clashStoryLevelBlockedBody,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final level = controller.activeLevel!;
    final scene = level.scenes[controller.sceneIndex];
    final progressLabel = '${controller.sceneIndex + 1}/${level.scenes.length}';

    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(level.title),
        actions: [
          if (scene.isSkippable)
            TextButton(
              onPressed: () => controller.skipScene(),
              child: Text(l10n.clashStorySkipScene),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(
                value: (controller.sceneIndex + 1) / level.scenes.length,
                backgroundColor: Colors.white12,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                progressLabel,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: Colors.white70),
              ),
              const Spacer(),
              if (scene.speaker != null) ...[
                Text(
                  scene.speaker!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  scene.text,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    height: 1.55,
                  ),
                ),
              ),
              const Spacer(flex: 2),
              FilledButton(
                onPressed: () => _onNext(controller),
                child: Text(
                  controller.hasNextScene
                      ? l10n.clashStoryNextScene
                      : l10n.clashStoryFinishLevel,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
