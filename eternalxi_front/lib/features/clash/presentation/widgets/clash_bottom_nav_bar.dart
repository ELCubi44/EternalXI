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

/// Barra inferior Clash: placa ornamental con tabs centrados dentro.
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

  /// Recorte real del asset: 1200×213.
  static const double _plateAspect = 1200 / 213;

  @override
  void initState() {
    super.initState();
    final n = widget.items.length;
    _selectCtrl = List.generate(
      n,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 260),
      ),
    );
    _selectAnim = _selectCtrl
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOutCubic))
        .toList();
    _pressCtrl = List.generate(
      n,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 100),
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

    return Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          8,
          0,
          8,
          bottomPad > 0 ? (bottomPad * 0.4).clamp(4.0, 14.0) : 6,
        ),
        child: AspectRatio(
          aspectRatio: _plateAspect,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                ClashEpicAssets.clashBottomNavBg,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xE608101C),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: XiColors.classicGold.withValues(alpha: 0.55),
                      width: 1.2,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 3, 22, 4),
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
                                  Container(
                                    width: (18 * sel).clamp(0.0, 18.0),
                                    height: 2.5,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(2),
                                      gradient: sel > 0.05
                                          ? const LinearGradient(
                                              colors: [
                                                XiColors.classicGold,
                                                XiColors.techCyan,
                                              ],
                                            )
                                          : null,
                                      boxShadow: sel > 0.05
                                          ? [
                                              BoxShadow(
                                                color: XiColors.techCyan
                                                    .withValues(
                                                      alpha: 0.5 * sel,
                                                    ),
                                                blurRadius: 5 * sel,
                                              ),
                                            ]
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Opacity(
                                    opacity: selected ? 1.0 : 0.58,
                                    child: Image.asset(
                                      widget.items[i].iconAsset,
                                      width: 34,
                                      height: 34,
                                      fit: BoxFit.contain,
                                      filterQuality: FilterQuality.medium,
                                      gaplessPlayback: true,
                                    ),
                                  ),
                                  Text(
                                    widget.items[i].label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Lumiare',
                                      fontSize: 10.5,
                                      letterSpacing: 0.2,
                                      height: 1.0,
                                      color: labelColor,
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
      ),
    );
  }
}
