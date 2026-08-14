import 'package:flutter/material.dart';

/// Conserva el estado de cada hijo (como [IndexedStack]) y hace un fade
/// breve al cambiar de �ndice, para que el cambio no sea un corte seco.
class FadeIndexedStack extends StatefulWidget {
  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 280),
  });

  final int index;
  final List<Widget> children;
  final Duration duration;

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late int _displayedIndex;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _displayedIndex = widget.index;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: 1,
    );
  }

  @override
  void didUpdateWidget(FadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
    if (widget.index != oldWidget.index) {
      _animateTo(widget.index);
    }
  }

  Future<void> _animateTo(int next) async {
    final gen = ++_generation;
    await _controller.animateTo(
      0,
      duration: Duration(
        milliseconds: (widget.duration.inMilliseconds * 0.45).round(),
      ),
      curve: Curves.easeInCubic,
    );
    if (!mounted || gen != _generation) return;
    setState(() => _displayedIndex = next);
    await _controller.animateTo(
      1,
      duration: Duration(
        milliseconds: (widget.duration.inMilliseconds * 0.55).round(),
      ),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: IndexedStack(
        index: _displayedIndex,
        children: widget.children,
      ),
    );
  }
}
