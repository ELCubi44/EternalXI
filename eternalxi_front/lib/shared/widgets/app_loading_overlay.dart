import 'package:flutter/material.dart';

class AppLoadingOverlay extends StatelessWidget {
  const AppLoadingOverlay({
    required this.isLoading,
    required this.child,
    super.key,
  });

  final bool isLoading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scrim = Theme.of(context).colorScheme.scrim.withValues(alpha: 0.38);
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !isLoading,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: isLoading
                  ? ColoredBox(
                      key: const ValueKey('loading'),
                      color: scrim,
                      child: const Center(child: CircularProgressIndicator()),
                    )
                  : const SizedBox.shrink(key: ValueKey('idle')),
            ),
          ),
        ),
      ],
    );
  }
}
