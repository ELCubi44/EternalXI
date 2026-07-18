import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/features/clash/cards/presentation/controllers/clash_cards_controller.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level_status.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_scene.dart';
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
  var _noEnergy = false;

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
      _noEnergy = !ok && controller.errorMessage == 'energy';
      _blocked = !ok && !_noEnergy;
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

    final hasRewards =
        !result.rewardsGranted.isEmpty || result.newlyGrantedCardIds.isNotEmpty;

    if (hasRewards) {
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
    }

    if (mounted) {
      context.go(AppRoutes.clashStory);
    }
  }

  void _exitWithoutReward(ClashStoryController controller) {
    controller.clearActiveLevel();
    controller.clearLastCompletion();
    context.go(AppRoutes.clashStory);
  }

  Future<void> _openMenu(ClashStoryController controller) async {
    final l10n = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF121A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.clashStoryMenuTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Lumiare',
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.clashStoryMenuExitHint,
                  style: const TextStyle(color: Colors.white70, height: 1.35),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: Text(l10n.clashStoryMenuResume),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _exitWithoutReward(controller);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                  ),
                  child: Text(l10n.clashStoryMenuExit),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = context.watch<ClashStoryController>();

    if (_loading || !_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_noEnergy) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.clashHomeStory),
          leading: IconButton(
            onPressed: () => context.go(AppRoutes.clashStory),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.clashStoryNotEnoughEnergy,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go(AppRoutes.clashStory),
                  child: Text(l10n.clashStoryBackToMap),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_blocked || controller.activeLevel == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.clashStoryLevelBlockedTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.clashStoryCompletePreviousLevel,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go(AppRoutes.clashStory),
                  child: Text(l10n.clashStoryBackToMap),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final level = controller.activeLevel!;
    final status = controller.statusFor(level);
    final isCompleted = status == ClashStoryLevelStatus.completed;
    final scene = level.scenes[controller.sceneIndex];
    final hasArt = (scene.imagePath?.isNotEmpty ?? false) ||
        (scene.backgroundPath?.isNotEmpty ?? false);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      body: hasArt
          ? _MangaSceneView(
              scene: scene,
              progressLabel:
                  '${controller.sceneIndex + 1}/${level.scenes.length}',
              progress: (controller.sceneIndex + 1) / level.scenes.length,
              canGoBack: controller.hasPreviousScene,
              onMenu: () => _openMenu(controller),
              onPrevious: controller.hasPreviousScene
                  ? () => controller.previousScene()
                  : null,
              onNext: () => _onNext(controller),
              nextLabel: controller.hasNextScene
                  ? l10n.clashStoryNextScene
                  : isCompleted
                      ? l10n.clashStoryReadAgain
                      : l10n.clashStoryFinishLevel,
              previousLabel: l10n.clashStoryPreviousScene,
            )
          : _LegacyTextSceneView(
              scene: scene,
              levelTitle: level.title,
              progressLabel:
                  '${controller.sceneIndex + 1}/${level.scenes.length}',
              progress: (controller.sceneIndex + 1) / level.scenes.length,
              canGoBack: controller.hasPreviousScene,
              onMenu: () => _openMenu(controller),
              onPrevious: controller.hasPreviousScene
                  ? () => controller.previousScene()
                  : null,
              onNext: () => _onNext(controller),
              nextLabel: controller.hasNextScene
                  ? l10n.clashStoryNextScene
                  : isCompleted
                      ? l10n.clashStoryReadAgain
                      : l10n.clashStoryFinishLevel,
              previousLabel: l10n.clashStoryPreviousScene,
            ),
    );
  }
}

class _MangaSceneView extends StatelessWidget {
  const _MangaSceneView({
    required this.scene,
    required this.progressLabel,
    required this.progress,
    required this.canGoBack,
    required this.onMenu,
    required this.onNext,
    required this.nextLabel,
    required this.previousLabel,
    this.onPrevious,
  });

  final ClashStoryScene scene;
  final String progressLabel;
  final double progress;
  final bool canGoBack;
  final VoidCallback onMenu;
  final VoidCallback onNext;
  final String nextLabel;
  final String previousLabel;
  final VoidCallback? onPrevious;

  @override
  Widget build(BuildContext context) {
    final art = scene.imagePath ?? scene.backgroundPath!;

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          art,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => const ColoredBox(
            color: Color(0xFF0B1020),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.45, 0.72, 1.0],
              colors: [
                Color(0x66000000),
                Color(0x14000000),
                Color(0x66000000),
                Color(0xE6000000),
              ],
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: onMenu,
                      icon: const Icon(Icons.menu_rounded),
                      color: Colors.white,
                      tooltip: context.l10n.clashStoryMenuTitle,
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white24,
                        color: XiColors.techCyan,
                        minHeight: 3,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      progressLabel,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _DialoguePlate(
                  speaker: scene.speaker,
                  text: scene.text,
                  onNext: onNext,
                  onPrevious: onPrevious,
                  nextLabel: nextLabel,
                  previousLabel: previousLabel,
                  canGoBack: canGoBack,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DialoguePlate extends StatelessWidget {
  const _DialoguePlate({
    required this.text,
    required this.onNext,
    required this.nextLabel,
    required this.previousLabel,
    required this.canGoBack,
    this.speaker,
    this.onPrevious,
  });

  final String? speaker;
  final String text;
  final VoidCallback onNext;
  final VoidCallback? onPrevious;
  final String nextLabel;
  final String previousLabel;
  final bool canGoBack;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: XiColors.classicGold.withValues(alpha: 0.55),
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xF0141C2C),
              XiColors.royalBlue.withValues(alpha: 0.35),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: XiColors.techCyan.withValues(alpha: 0.18),
              blurRadius: 16,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (speaker != null && speaker!.trim().isNotEmpty) ...[
                Text(
                  speaker!,
                  style: const TextStyle(
                    fontFamily: 'Lumiare',
                    color: XiColors.techCyan,
                    fontSize: 14,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              GestureDetector(
                onTap: onNext,
                behavior: HitTestBehavior.opaque,
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    height: 1.45,
                    fontSize: 15.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (canGoBack && onPrevious != null)
                    TextButton.icon(
                      onPressed: onPrevious,
                      icon: const Icon(Icons.chevron_left_rounded, size: 18),
                      label: Text(previousLabel),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                      ),
                    ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: onNext,
                    icon: Text(
                      nextLabel,
                      style: TextStyle(
                        color: XiColors.classicGold.withValues(alpha: 0.95),
                        fontSize: 13,
                        letterSpacing: 0.4,
                      ),
                    ),
                    label: Icon(
                      Icons.chevron_right_rounded,
                      color: XiColors.classicGold.withValues(alpha: 0.95),
                      size: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegacyTextSceneView extends StatelessWidget {
  const _LegacyTextSceneView({
    required this.scene,
    required this.levelTitle,
    required this.progressLabel,
    required this.progress,
    required this.canGoBack,
    required this.onMenu,
    required this.onNext,
    required this.nextLabel,
    required this.previousLabel,
    this.onPrevious,
  });

  final ClashStoryScene scene;
  final String levelTitle;
  final String progressLabel;
  final double progress;
  final bool canGoBack;
  final VoidCallback onMenu;
  final VoidCallback onNext;
  final String nextLabel;
  final String previousLabel;
  final VoidCallback? onPrevious;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onMenu,
                icon: const Icon(Icons.menu_rounded),
                color: Colors.white,
              ),
              Expanded(
                child: Text(
                  levelTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                progressLabel,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white12,
            color: XiColors.techCyan,
          ),
          const SizedBox(height: 20),
          if (scene.speaker != null) ...[
            Text(
              scene.speaker!,
              style: const TextStyle(color: XiColors.techCyan, fontSize: 16),
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
              style: const TextStyle(
                color: Colors.white,
                height: 1.55,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              if (canGoBack && onPrevious != null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: onPrevious,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                    ),
                    child: Text(previousLabel),
                  ),
                ),
              if (canGoBack && onPrevious != null) const SizedBox(width: 10),
              Expanded(
                child: FilledButton(onPressed: onNext, child: Text(nextLabel)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
