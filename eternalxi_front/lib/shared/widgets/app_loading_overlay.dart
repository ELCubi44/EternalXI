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
        if (isLoading)
          ColoredBox(
            color: scrim,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
