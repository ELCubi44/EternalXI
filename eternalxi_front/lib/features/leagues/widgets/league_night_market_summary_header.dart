import 'package:flutter/material.dart';
import 'dart:async';
import 'package:timezone/timezone.dart' as tz;

class LeagueNightMarketSummaryHeader extends StatefulWidget {
  const LeagueNightMarketSummaryHeader({super.key});

  @override
  State<LeagueNightMarketSummaryHeader> createState() =>
      _LeagueNightMarketSummaryHeaderState();
}

class _LeagueNightMarketSummaryHeaderState
    extends State<LeagueNightMarketSummaryHeader> {
  late final Timer _ticker;
  static final tz.Location _madrid = tz.getLocation('Europe/Madrid');

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = tz.TZDateTime.now(_madrid);
    final nextMidnight = tz.TZDateTime(
      _madrid,
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));
    final remaining = nextMidnight.difference(now);
    final countdown = _formatDurationHms(remaining);

    return Center(
      child: Text(
        countdown,
        style: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  static String _formatDurationHms(Duration duration) {
    final safe = duration.isNegative ? Duration.zero : duration;
    final totalSeconds = safe.inSeconds;
    final h = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
