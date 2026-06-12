import 'package:eternal_xi/app/icons/xi_icons.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:flutter/material.dart';

class XiBottomNavItem {
  const XiBottomNavItem({
    this.icon,
    this.assetIcon,
    required this.label,
  }) : assert(icon != null || assetIcon != null);

  final XiIconType? icon;
  final String? assetIcon;
  final String label;
}

class XiBottomNav extends StatefulWidget {
  final List<XiBottomNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const XiBottomNav({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  State<XiBottomNav> createState() => _XiBottomNavState();
}

class _XiBottomNavState extends State<XiBottomNav>
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
        duration: const Duration(milliseconds: 300),
      ),
    );
    _selectAnim = _selectCtrl
        .map(
          (c) => CurvedAnimation(parent: c, curve: Curves.easeOutBack),
        )
        .toList();

    _pressCtrl = List.generate(
      n,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 120),
      ),
    );
    _pressAnim = _pressCtrl
        .map(
          (c) => Tween<double>(begin: 1.0, end: 0.87).animate(
            CurvedAnimation(parent: c, curve: Curves.easeInOut),
          ),
        )
        .toList();

    if (widget.selectedIndex < n) {
      _selectCtrl[widget.selectedIndex].value = 1.0;
    }
  }

  @override
  void didUpdateWidget(XiBottomNav old) {
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
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      height: 68 + bottomPad,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: context.xiNavGradient,
        ),
        border: Border(top: BorderSide(color: context.xiNavBorder, width: 1)),
        boxShadow: [
          BoxShadow(
            color: XiColors.royalBlue.withValues(alpha: context.isXiDark ? 0.08 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPad),
        child: Row(
          children: List.generate(widget.items.length, (i) {
            return Expanded(
              child: GestureDetector(
                onTapDown: (_) => _onTapDown(i),
                onTapUp: (_) => _onTapUp(i),
                onTapCancel: () => _onTapCancel(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedBuilder(
                  animation: Listenable.merge(
                    [_selectAnim[i], _pressAnim[i]],
                  ),
                  builder: (context, child) {
                    final sel = _selectAnim[i].value;
                    final isSelected = widget.selectedIndex == i;
                    final selectedColor = context.xiNavSelected;
                    final unselectedColor = context.xiNavUnselected;
                    return Transform.scale(
                      scale: _pressAnim[i].value,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _IndicatorBar(
                            selValue: sel,
                            color: selectedColor,
                          ),
                          const SizedBox(height: 7),
                          _NavIcon(
                            item: widget.items[i],
                            isSelected: isSelected,
                            selectedColor: selectedColor,
                            unselectedColor: unselectedColor,
                          ),
                          const SizedBox(height: 3),
                          SizedBox(
                            height: 12,
                            child: sel > 0.1
                                ? Opacity(
                                    opacity: (sel * 2).clamp(0.0, 1.0),
                                    child: Text(
                                      widget.items[i].label,
                                      style: TextStyle(
                                        fontFamily: 'Lumiare',
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                        color: selectedColor,
                                        letterSpacing: 0.4,
                                        height: 1.2,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
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
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.item,
    required this.isSelected,
    required this.selectedColor,
    required this.unselectedColor,
  });

  final XiBottomNavItem item;
  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;

  @override
  Widget build(BuildContext context) {
    final asset = item.assetIcon;
    if (asset != null) {
      final image = Image.asset(
        asset,
        width: 24,
        height: 24,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      );
      if (!isSelected) {
        return Opacity(opacity: 0.55, child: image);
      }
      return image;
    }
    return XiIcon(
      item.icon!,
      size: 24,
      color: isSelected ? selectedColor : unselectedColor,
      filled: isSelected,
    );
  }
}

class _IndicatorBar extends StatelessWidget {
  final double selValue;
  final Color color;
  const _IndicatorBar({required this.selValue, required this.color});

  @override
  Widget build(BuildContext context) {
    final w = (26 * selValue).clamp(0.0, 26.0);
    if (w < 1) return const SizedBox(height: 3);
    return Container(
      width: w,
      height: 3,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.55),
            blurRadius: 6 * selValue,
            spreadRadius: selValue,
          ),
        ],
      ),
    );
  }
}
