import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/features/clash/cards/presentation/epic/clash_epic_assets.dart';
import 'package:flutter/material.dart';

class ClashBottomNavItem {
  const ClashBottomNavItem({
    required this.iconAsset,
    required this.label,
  });

  final String iconAsset;
  final String label;
}

/// Barra inferior Clash: placa ornamental + iconos custom (flujo epic).
class ClashBottomNavBar extends StatefulWidget {
  const ClashBottomNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  final List<ClashBottomNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  @override
  State<ClashBottomNavBar> createState() => _ClashBottomNavBarState();
}

class _ClashBottomNavBarState extends State<ClashBottomNavBar>
    with TickerProviderStateMixin {
  late final List<AnimationController> _selectCtrl;
  late final List<Animation<double>> _selectAnim;
  late final List<AnimationController> _pressCtrl;
  late final List<Animation<double>> _pressAnim;

  @override
  void initState() {
    super.initState();
    final n = widget.items.length;
    _selectCtrl = List.generate(
      n,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 280),
      ),
    );
    _selectAnim = _selectCtrl
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOutCubic))
        .toList();
    _pressCtrl = List.generate(
      n,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 110),
      ),
    );
    _pressAnim = _pressCtrl
        .map(
          (c) => Tween<double>(begin: 1.0, end: 0.9).animate(
            CurvedAnimation(parent: c, curve: Curves.easeInOut),
          ),
        )
        .toList();
    if (widget.selectedIndex < n) {
      _selectCtrl[widget.selectedIndex].value = 1.0;
    }
  }

  @override
  void didUpdateWidget(ClashBottomNavBar old) {
    super.didUpdateWidget(old);
    if (old.selectedIndex != widget.selectedIndex) {
      if (old.selectedIndex < _selectCtrl.length) {
        _selectCtrl[old.selectedIndex].reverse();
      }
      if (widget.selectedIndex < _selectCtrl.length) {
        _selectCtrl[widget.selectedIndex].forward();
      }
    }
  }

  @override
  void dispose() {
    for (final c in _selectCtrl) {
      c.dispose();
    }
    for (final c in _pressCtrl) {
      c.dispose();
    }
    super.dispose();
  }

  void _onTapDown(int i) => _pressCtrl[i].forward();
  void _onTapUp(int i) {
    _pressCtrl[i].reverse();
    if (i != widget.selectedIndex) widget.onItemSelected(i);
  }

  void _onTapCancel(int i) => _pressCtrl[i].reverse();

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final barHeight = 72.0 + bottomPad;

    return Material(
      color: Colors.transparent,
      child: SizedBox(
        height: barHeight,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Velo suave para legibilidad sobre fondos claros.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: barHeight + 12,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: bottomPad > 0 ? bottomPad * 0.35 : 4,
              child: AspectRatio(
                aspectRatio: 1200 / 360,
                child: Image.asset(
                  ClashEpicAssets.clashBottomNavBg,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) => DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: XiColors.classicGold.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: bottomPad > 0 ? bottomPad * 0.35 + 6 : 10,
              height: 58,
              child: Row(
                children: List.generate(widget.items.length, (i) {
                  return Expanded(
                    child: GestureDetector(
                      onTapDown: (_) => _onTapDown(i),
                      onTapUp: (_) => _onTapUp(i),
                      onTapCancel: () => _onTapCancel(i),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedBuilder(
                        animation: Listenable.merge([
                          _selectAnim[i],
                          _pressAnim[i],
                        ]),
                        builder: (context, _) {
                          final sel = _selectAnim[i].value;
                          final selected = widget.selectedIndex == i;
                          final labelColor = Color.lerp(
                            XiColors.steelGray,
                            XiColors.techCyan,
                            sel,
                          )!;
                          return Transform.scale(
                            scale: _pressAnim[i].value,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _GlowDot(active: sel),
                                const SizedBox(height: 2),
                                AnimatedScale(
                                  scale: selected ? 1.08 : 1.0,
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutCubic,
                                  child: Opacity(
                                    opacity: selected ? 1.0 : 0.62,
                                    child: Image.asset(
                                      widget.items[i].iconAsset,
                                      width: 30,
                                      height: 30,
                                      fit: BoxFit.contain,
                                      filterQuality: FilterQuality.medium,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.items[i].label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Lumiare',
                                    fontSize: 9,
                                    letterSpacing: 0.3,
                                    height: 1.1,
                                    color: labelColor,
                                    shadows: selected
                                        ? [
                                            Shadow(
                                              color: XiColors.techCyan
                                                  .withValues(alpha: 0.55),
                                              blurRadius: 8,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowDot extends StatelessWidget {
  const _GlowDot({required this.active});

  final double active;

  @override
  Widget build(BuildContext context) {
    final w = (18 * active).clamp(0.0, 18.0);
    if (w < 1) return const SizedBox(height: 4);
    return Container(
      width: w,
      height: 3,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: const LinearGradient(
          colors: [XiColors.classicGold, XiColors.techCyan],
        ),
        boxShadow: [
          BoxShadow(
            color: XiColors.techCyan.withValues(alpha: 0.55 * active),
            blurRadius: 6 * active,
            spreadRadius: active,
          ),
        ],
      ),
    );
  }
}
