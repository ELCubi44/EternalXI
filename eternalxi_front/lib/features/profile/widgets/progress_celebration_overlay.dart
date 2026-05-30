import 'dart:async';

import 'package:eternal_xi/features/auth/controller/auth_controller.dart';
import 'package:eternal_xi/features/profile/controller/account_progress_controller.dart';
import 'package:eternal_xi/features/profile/widgets/account_level_display.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Reproduce la cola de eventos de progreso pendientes al entrar en Mis ligas.
class ProgressCelebrationOverlay extends StatefulWidget {
  const ProgressCelebrationOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<ProgressCelebrationOverlay> createState() =>
      _ProgressCelebrationOverlayState();
}

class _ProgressCelebrationOverlayState extends State<ProgressCelebrationOverlay> {
  bool _started = false;
  int _displayXpEnNivel = 0;
  int _displayXpParaSiguiente = 100;
  int _displayNivel = 1;
  String _displayRango = 'Novato';
  double _progressFrom = 0;
  bool _showOverlay = false;
  String? _bannerTitle;
  String? _bannerSubtitle;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybePlayQueue());
    }
  }

  Future<void> _maybePlayQueue() async {
    final userId = context.read<AuthController>().currentUser?.id;
    if (userId == null) {
      return;
    }

    final progressCtrl = context.read<AccountProgressController>();
    final progress = progressCtrl.progress;
    if (progress == null || progress.eventosPendientes.isEmpty) {
      return;
    }

    progressCtrl.setCelebrating(true);

    var runningXp = progress.xpEnNivel;
    var runningMax = progress.xpParaSiguienteNivel;
    var runningLevel = progress.nivel;
    var runningRank = progress.rango;

    for (var i = progress.eventosPendientes.length - 1; i >= 0; i--) {
      final event = progress.eventosPendientes[i];
      if (event.tipo == 'LEVEL_UP') {
        runningLevel = event.nivelAnterior ?? runningLevel;
        runningRank = _rankForLevel(runningLevel);
      }
      final gain = event.tipo == 'ACHIEVEMENT'
          ? (event.xpLogro ?? 0)
          : (event.tipo == 'XP' ? (event.cantidadXp ?? 0) : 0);
      if (gain > 0) {
        runningXp = (runningXp - gain).clamp(0, runningMax);
      }
    }

    setState(() {
      _showOverlay = true;
      _displayNivel = runningLevel;
      _displayRango = runningRank;
      _displayXpEnNivel = runningXp;
      _displayXpParaSiguiente = runningMax;
      _progressFrom = runningMax <= 0 ? 0 : runningXp / runningMax;
    });

    final seenIds = <int>[];
    var prevRatio = _progressFrom;

    for (final event in progress.eventosPendientes) {
      if (!mounted) {
        break;
      }

      if (event.tipo == 'ACHIEVEMENT') {
        _showBanner(
          'Has conseguido un logro',
          event.tituloLogro ?? 'Logro desbloqueado',
        );
        runningXp = event.xpEnNivelDespues;
        runningMax = event.xpParaSiguienteDespues;
        await _animateBar(prevRatio, runningXp, runningMax, runningLevel, runningRank);
        prevRatio = runningMax <= 0 ? 0 : runningXp / runningMax;
        await Future<void>.delayed(const Duration(milliseconds: 650));
      } else if (event.tipo == 'XP') {
        final xp = event.cantidadXp ?? 0;
        _showBanner('Experiencia obtenida', '+$xp XP');
        runningXp = event.xpEnNivelDespues;
        runningMax = event.xpParaSiguienteDespues;
        await _animateBar(prevRatio, runningXp, runningMax, runningLevel, runningRank);
        prevRatio = runningMax <= 0 ? 0 : runningXp / runningMax;
        await Future<void>.delayed(const Duration(milliseconds: 450));
      } else if (event.tipo == 'LEVEL_UP') {
        runningLevel = event.nivelNuevo ?? runningLevel;
        runningRank = _rankForLevel(runningLevel);
        runningXp = event.xpEnNivelDespues;
        runningMax = event.xpParaSiguienteDespues;
        _showBanner('¡Subiste de nivel!', 'Nivel $runningLevel · $runningRank');
        await _animateBar(0, runningXp, runningMax, runningLevel, runningRank);
        prevRatio = runningMax <= 0 ? 0 : runningXp / runningMax;
        await Future<void>.delayed(const Duration(milliseconds: 850));
      }

      seenIds.add(event.id);
    }

    if (seenIds.isNotEmpty) {
      await progressCtrl.markEventsSeen(userId, seenIds);
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
        _bannerTitle = null;
        _bannerSubtitle = null;
      });
    }
  }

  Future<void> _animateBar(
    double fromRatio,
    int xp,
    int maxXp,
    int level,
    String rank,
  ) async {
    if (!mounted) {
      return;
    }
    final safeMax = maxXp <= 0 ? 1 : maxXp;
    setState(() {
      _progressFrom = fromRatio.clamp(0.0, 1.0);
      _displayXpEnNivel = xp;
      _displayXpParaSiguiente = safeMax;
      _displayNivel = level;
      _displayRango = rank;
    });
    await Future<void>.delayed(const Duration(milliseconds: 950));
  }

  void _showBanner(String title, String subtitle) {
    if (!mounted) {
      return;
    }
    setState(() {
      _bannerTitle = title;
      _bannerSubtitle = subtitle;
    });
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showOverlay)
          Positioned.fill(
            child: Material(
              color: Colors.black.withValues(alpha: 0.55),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_bannerTitle != null) ...[
                        Icon(
                          Icons.auto_awesome,
                          size: 56,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _bannerTitle!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        if (_bannerSubtitle != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _bannerSubtitle!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white70,
                                ),
                          ),
                        ],
                        const SizedBox(height: 28),
                      ],
                      AccountLevelDisplay(
                        nivel: _displayNivel,
                        rango: _displayRango,
                        xpEnNivel: _displayXpEnNivel,
                        xpParaSiguiente: _displayXpParaSiguiente,
                        animateProgress: true,
                        displayXpEnNivel: _displayXpEnNivel,
                        displayXpParaSiguiente: _displayXpParaSiguiente,
                        progressFrom: _progressFrom,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
