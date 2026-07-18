import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level_status.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level_type.dart';
import 'package:eternal_xi/features/clash/story/presentation/controllers/clash_story_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Mapa mundo Clash: zoom/pan realista + marcas de misión.
class ClashStoryMapScreen extends StatefulWidget {
  const ClashStoryMapScreen({super.key});

  static const worldMapAsset =
      'assets/images/clash/story/map/clash_world_map.png';
  static const pin1Asset = 'assets/images/clash/story/map/clash_map_pin_1.png';

  /// Posición normalizada del pin Zaragoza sobre el mapa (0–1).
  static const zaragozaOffset = Offset(0.505, 0.355);

  @override
  State<ClashStoryMapScreen> createState() => _ClashStoryMapScreenState();
}

class _ClashStoryMapScreenState extends State<ClashStoryMapScreen> {
  final _transform = TransformationController();
  ClashStoryLevel? _selected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = context.read<ClashStoryController>();
      if (controller.state == ClashStoryLoadState.idle) {
        await controller.load();
      }
      // Zoom inicial hacia Europa / Zaragoza.
      _transform.value = Matrix4.identity()
        ..translateByDouble(-420.0, -180.0, 0)
        ..scaleByDouble(2.2, 2.2, 2.2, 1);
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = context.watch<ClashStoryController>();

    if (controller.state == ClashStoryLoadState.loading ||
        controller.state == ClashStoryLoadState.idle) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B1020),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (controller.state == ClashStoryLoadState.error) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B1020),
        body: Center(
          child: Text(
            controller.errorMessage ?? l10n.clashStoryLoadError,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final chapter = controller.activeChapter;
    final levels = chapter == null
        ? const <ClashStoryLevel>[]
        : ([...chapter.levels]..sort((a, b) => a.order.compareTo(b.order)));
    final first = levels.isEmpty ? null : levels.first;
    final firstStatus =
        first == null ? null : controller.statusFor(first);

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: Stack(
        fit: StackFit.expand,
        children: [
          InteractiveViewer(
            transformationController: _transform,
            minScale: 0.8,
            maxScale: 5,
            boundaryMargin: const EdgeInsets.all(200),
            child: SizedBox(
              width: 1600,
              height: 900,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    ClashStoryMapScreen.worldMapAsset,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                  ),
                  if (first != null)
                    Align(
                      alignment: Alignment(
                        (ClashStoryMapScreen.zaragozaOffset.dx * 2) - 1,
                        (ClashStoryMapScreen.zaragozaOffset.dy * 2) - 1,
                      ),
                      child: GestureDetector(
                        onTap: () => setState(() => _selected = first),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              ClashStoryMapScreen.pin1Asset,
                              width: 56,
                              height: 56,
                              filterQuality: FilterQuality.high,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: XiColors.classicGold
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                              child: const Text(
                                'Zaragoza',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.go(AppRoutes.clash),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: Colors.white,
                  ),
                  Expanded(
                    child: Text(
                      l10n.clashHomeStory,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontFamily: 'Lumiare',
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_selected != null && firstStatus != null)
            _MissionSheet(
              level: _selected!,
              status: firstStatus,
              onClose: () => setState(() => _selected = null),
              onStart: _canOpen(firstStatus)
                  ? () => _openLevel(context, _selected!)
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

class _MissionSheet extends StatelessWidget {
  const _MissionSheet({
    required this.level,
    required this.status,
    required this.onClose,
    this.onStart,
  });

  final ClashStoryLevel level;
  final ClashStoryLevelStatus status;
  final VoidCallback onClose;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: XiColors.classicGold.withValues(alpha: 0.55),
            ),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xF0121A2A), Color(0xE6081424)],
            ),
            boxShadow: [
              BoxShadow(
                color: XiColors.techCyan.withValues(alpha: 0.2),
                blurRadius: 18,
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        level.title,
                        style: const TextStyle(
                          fontFamily: 'Lumiare',
                          color: XiColors.classicGold,
                          fontSize: 18,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(Icons.close_rounded),
                      color: Colors.white70,
                    ),
                  ],
                ),
                Text(
                  'Zaragoza · España',
                  style: TextStyle(
                    color: XiColors.techCyan.withValues(alpha: 0.9),
                    fontSize: 12,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  level.description,
                  style: const TextStyle(
                    color: Colors.white,
                    height: 1.4,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: onStart,
                  child: Text(
                    onStart == null
                        ? l10n.clashStoryStatusLocked
                        : status == ClashStoryLevelStatus.completed
                            ? l10n.clashStoryActionReplay
                            : l10n.clashStoryActionRead,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
