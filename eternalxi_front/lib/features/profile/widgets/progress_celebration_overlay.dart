import 'dart:async';

import 'package:eternal_xi/app/localization/achievement_l10n.dart';
import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/data/models/user_progress_response.dart';
import 'package:eternal_xi/features/auth/controller/auth_controller.dart';
import 'package:eternal_xi/features/profile/controller/account_progress_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const _betweenEvents = Duration(milliseconds: 400);
const _floatDuration = Duration(milliseconds: 2400);
const _levelUpHold = Duration(milliseconds: 900);

/// Reproduce XP pendiente al entrar al juego (p. ej. pantalla de modos).
class ProgressCelebrationOverlay extends StatefulWidget {
  const ProgressCelebrationOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<ProgressCelebrationOverlay> createState() =>
      _ProgressCelebrationOverlayState();
}

class _ProgressCelebrationOverlayState extends State<ProgressCelebrationOverlay>
    with TickerProviderStateMixin {
  bool _queueRunning = false;
  bool _showOverlay = false;
  int _displayXpEnNivel = 0;
  int _displayXpParaSiguiente = 100;
  int _displayNivel = 1;
  String _displayRango = 'Novato';
  double _barProgress = 0;
  int? _levelUpFlashLevel;
  final List<_FloatingXpLabel> _floatingLabels = [];

  @override
  Widget build(BuildContext context) {
    final progressCtrl = context.watch<AccountProgressController>();
    if (progressCtrl.hasPendingCelebration &&
        !progressCtrl.isPlayingCelebration &&
        !_queueRunning) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_queueRunning) {
          unawaited(_maybePlayQueue());
        }
      });
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if (_showOverlay) _buildOverlay(context),
      ],
    );
  }

  Future<void> _maybePlayQueue() async {
    if (_queueRunning || !mounted) return;

    final userId = context.read<AuthController>().currentUser?.id;
    if (userId == null) return;

    final progressCtrl = context.read<AccountProgressController>();
    final progress = progressCtrl.progress;
    final pendingEvents = progressCtrl.pendingUnseenEvents;
    if (progress == null || pendingEvents.isEmpty) return;

    _queueRunning = true;
    progressCtrl.setCelebrating(true);

    var runningXp = progress.xpEnNivel;
    var runningMax = progress.xpParaSiguienteNivel;
    var runningLevel = progress.nivel;
    var runningRank = progress.rango;

    for (var i = pendingEvents.length - 1; i >= 0; i--) {
      final event = pendingEvents[i];
      if (event.tipo == 'LEVEL_UP') {
        runningLevel = event.nivelAnterior ?? runningLevel;
        runningRank = _rankForLevel(runningLevel);
      }
      final gain = _xpGainForEvent(event);
      if (gain > 0) {
        runningXp = (runningXp - gain).clamp(0, runningMax);
      }
    }

    setState(() {
      _showOverlay = true;
      _floatingLabels.clear();
      _levelUpFlashLevel = null;
      _displayNivel = runningLevel;
      _displayRango = runningRank;
      _displayXpEnNivel = runningXp;
      _displayXpParaSiguiente = runningMax;
      _barProgress = runningMax <= 0 ? 0 : runningXp / runningMax;
    });

    final locale = context.l10n.locale.languageCode;
    final seenIds = <int>[];
    var prevRatio = _barProgress;

    for (final event in pendingEvents) {
      if (!mounted) break;

      final chip = _labelForEvent(event, locale);
      _spawnFloatingLabel(chip.title, chip.subtitle, chip.xp);

      final fromXp = _displayXpEnNivel;

      if (event.tipo == 'ACHIEVEMENT') {
        runningXp = event.xpEnNivelDespues;
        runningMax = event.xpParaSiguienteDespues;
        final nextRatio = runningMax <= 0 ? 0.0 : runningXp / runningMax;
        await _animateBarTickByTick(
          fromRatio: prevRatio,
          toRatio: nextRatio,
          fromXp: fromXp,
          toXp: runningXp,
          maxXp: runningMax,
          level: runningLevel,
          rank: runningRank,
        );
        prevRatio = nextRatio;
      } else if (event.tipo == 'XP') {
        runningXp = event.xpEnNivelDespues;
        runningMax = event.xpParaSiguienteDespues;
        final nextRatio = runningMax <= 0 ? 0.0 : runningXp / runningMax;
        await _animateBarTickByTick(
          fromRatio: prevRatio,
          toRatio: nextRatio,
          fromXp: fromXp,
          toXp: runningXp,
          maxXp: runningMax,
          level: runningLevel,
          rank: runningRank,
        );
        prevRatio = nextRatio;
      } else if (event.tipo == 'LEVEL_UP') {
        runningLevel = event.nivelNuevo ?? runningLevel;
        runningRank = _rankForLevel(runningLevel);
        runningXp = event.xpEnNivelDespues;
        runningMax = event.xpParaSiguienteDespues;
        setState(() => _levelUpFlashLevel = runningLevel);
        final nextRatio = runningMax <= 0 ? 0.0 : runningXp / runningMax;
        await _animateBarTickByTick(
          fromRatio: 0,
          toRatio: nextRatio,
          fromXp: 0,
          toXp: runningXp,
          maxXp: runningMax,
          level: runningLevel,
          rank: runningRank,
        );
        prevRatio = nextRatio;
        await Future<void>.delayed(_levelUpHold);
        if (mounted) setState(() => _levelUpFlashLevel = null);
      }

      seenIds.add(event.id);
      await Future<void>.delayed(_betweenEvents);
    }

    await Future<void>.delayed(const Duration(milliseconds: 600));

    if (seenIds.isNotEmpty) {
      await progressCtrl.markEventsSeen(userId, seenIds);
      if (!mounted) {
        _queueRunning = false;
        return;
      }
      final auth = context.read<AuthController>();
      final user = auth.currentUser;
      if (user != null) {
        await progressCtrl.syncUserLevel(user);
        await auth.refreshCurrentUserFromServer();
      }
    }

    if (mounted) {
      progressCtrl.setCelebrating(false);
      setState(() {
        _showOverlay = false;
        _floatingLabels.clear();
        _levelUpFlashLevel = null;
      });
    }
    _queueRunning = false;
  }

  void _spawnFloatingLabel(String title, String subtitle, int xp) {
    if (!mounted) return;
    final controller = AnimationController(vsync: this, duration: _floatDuration);
    final label = _FloatingXpLabel(
      title: title,
      subtitle: subtitle,
      xp: xp,
      controller: controller,
    );
    setState(() => _floatingLabels.add(label));
    controller.forward().whenComplete(() {
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() => _floatingLabels.remove(label));
      controller.dispose();
    });
  }

  Future<void> _animateBarTickByTick({
    required double fromRatio,
    required double toRatio,
    required int fromXp,
    required int toXp,
    required int maxXp,
    required int level,
    required String rank,
  }) async {
    if (!mounted) return;
    final safeMax = maxXp <= 0 ? 1 : maxXp;
    final xpDelta = toXp - fromXp;
    final ratioDelta = (toRatio - fromRatio).abs();
    final steps = xpDelta > 0
        ? xpDelta
        : (ratioDelta > 0.001 ? 30 : 1);
    final stepDelay = Duration(
      milliseconds: (2000 / steps).clamp(50, 120).round(),
    );

    for (var step = 1; step <= steps; step++) {
      if (!mounted) return;
      final t = step / steps;
      final currentXp = xpDelta > 0 ? fromXp + step : toXp;
      setState(() {
        _barProgress = (fromRatio + (toRatio - fromRatio) * t).clamp(0.0, 1.0);
        _displayXpEnNivel = currentXp;
        _displayXpParaSiguiente = safeMax;
        _displayNivel = level;
        _displayRango = rank;
      });
      await Future<void>.delayed(stepDelay);
    }

    if (!mounted) return;
    setState(() {
      _barProgress = toRatio.clamp(0.0, 1.0);
      _displayXpEnNivel = toXp;
      _displayXpParaSiguiente = safeMax;
      _displayNivel = level;
      _displayRango = rank;
    });
  }

  int _xpGainForEvent(UserProgressEvent event) {
    if (event.tipo == 'ACHIEVEMENT') return event.xpLogro ?? 0;
    if (event.tipo == 'XP') return event.cantidadXp ?? 0;
    return 0;
  }

  _EventLabel _labelForEvent(UserProgressEvent event, String locale) {
    if (event.tipo == 'ACHIEVEMENT') {
      final translated = AchievementL10n.byCode(
        event.codigoLogro ?? '',
        localeCode: locale,
      );
      return _EventLabel(
        title: translated?.title ?? event.tituloLogro ?? 'Logro',
        subtitle: translated?.description ??
            event.descripcionLogro ??
            'Logro desbloqueado',
        xp: event.xpLogro ?? 0,
      );
    }
    if (event.tipo == 'LEVEL_UP') {
      return _EventLabel(
        title: '¡Nivel ${event.nivelNuevo}!',
        subtitle: _rankForLevel(event.nivelNuevo ?? _displayNivel),
        xp: 0,
      );
    }
    final xp = event.cantidadXp ?? 0;
    final title = _nonEmpty(event.tituloLogro) ?? _fallbackXpTitle(event);
    final subtitle =
        _nonEmpty(event.descripcionLogro) ?? _fallbackXpSubtitle(event);
    return _EventLabel(title: title, subtitle: subtitle, xp: xp);
  }

  String? _nonEmpty(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }

  String _fallbackXpTitle(UserProgressEvent event) {
    final code = event.codigoLogro ?? '';
    if (code.startsWith('ROUND_')) return 'Liga';
    if (code.startsWith('LEAGUE_')) return 'Liga';
    if (code == 'DAILY_LOGIN') return 'Inicio de sesión';
    return 'Experiencia';
  }

  String _fallbackXpSubtitle(UserProgressEvent event) {
    final code = event.codigoLogro ?? '';
    if (code.startsWith('ROUND_')) return 'Jornada completada';
    if (code.startsWith('LEAGUE_')) return 'Liga finalizada';
    if (code == 'DAILY_LOGIN') return 'Bonificación diaria';
    return 'XP ganada';
  }

  String _rankForLevel(int level) {
    if (level >= 75) return 'Inmortal';
    if (level >= 50) return 'Mítico';
    if (level >= 35) return 'Leyenda';
    if (level >= 20) return 'Estratega';
    if (level >= 10) return 'Manager';
    if (level >= 5) return 'Aficionado';
    return 'Novato';
  }

  Widget _buildOverlay(BuildContext context) {
    final maxXp = _displayXpParaSiguiente <= 0 ? 1 : _displayXpParaSiguiente;

    return Positioned.fill(
      child: IgnorePointer(
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.62),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_levelUpFlashLevel != null) ...[
                      const Text(
                        '¡SUBISTE DE NIVEL!',
                        style: TextStyle(
                          fontFamily: 'Lumiare',
                          color: XiColors.classicGold,
                          fontSize: 13,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_levelUpFlashLevel!}',
                        style: TextStyle(
                          fontFamily: 'Lumiare',
                          color: XiColors.warmWhite,
                          fontSize: 72,
                          height: 1,
                          shadows: [
                            Shadow(
                              color: XiColors.classicGold.withValues(alpha: 0.45),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                    SizedBox(
                      height: 150,
                      width: double.infinity,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.bottomCenter,
                        children: [
                          for (final label in _floatingLabels)
                            _FloatingXpLabelWidget(label: label),
                        ],
                      ),
                    ),
                    Text(
                      _displayRango,
                      style: const TextStyle(
                        fontFamily: 'Lumiare',
                        color: XiColors.warmWhite,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Nivel $_displayNivel',
                      style: TextStyle(
                        fontFamily: 'Lumiare',
                        color: XiColors.techCyan.withValues(alpha: 0.95),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$_displayXpEnNivel / $maxXp',
                      style: const TextStyle(
                        fontFamily: 'Lumiare',
                        color: XiColors.warmWhite,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: _barProgress.clamp(0.0, 1.0),
                        minHeight: 14,
                        backgroundColor: XiColors.royalBlue.withValues(alpha: 0.35),
                        color: XiColors.techCyan,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EventLabel {
  const _EventLabel({
    required this.title,
    required this.subtitle,
    required this.xp,
  });

  final String title;
  final String subtitle;
  final int xp;
}

class _FloatingXpLabel {
  _FloatingXpLabel({
    required this.title,
    required this.subtitle,
    required this.xp,
    required this.controller,
  });

  final String title;
  final String subtitle;
  final int xp;
  final AnimationController controller;
}

class _FloatingXpLabelWidget extends StatelessWidget {
  const _FloatingXpLabelWidget({required this.label});

  final _FloatingXpLabel label;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: label.controller,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(label.controller.value);
        final rise = -110.0 * t;
        final scale = 1.0 - (t * 0.4);
        final opacity = (1.0 - t).clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(0, rise),
          child: Transform.scale(
            scale: scale,
            child: Opacity(opacity: opacity, child: child),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label.xp > 0)
            Text(
              '+${label.xp} XP',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Lumiare',
                color: XiColors.classicGold,
                fontSize: 16,
              ),
            ),
          if (label.xp > 0) const SizedBox(height: 4),
          Text(
            label.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Lumiare',
              color: XiColors.warmWhite,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.subtitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Lumiare',
              color: XiColors.techCyan.withValues(alpha: 0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
