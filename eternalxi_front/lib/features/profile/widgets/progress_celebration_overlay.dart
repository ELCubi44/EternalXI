import 'dart:async';
import 'dart:math' as math;

import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/features/auth/controller/auth_controller.dart';
import 'package:eternal_xi/features/profile/controller/account_progress_controller.dart';
import 'package:eternal_xi/features/profile/widgets/account_level_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

/// Reproduce la cola de eventos de progreso pendientes al entrar en Mis ligas.
class ProgressCelebrationOverlay extends StatefulWidget {
  const ProgressCelebrationOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<ProgressCelebrationOverlay> createState() =>
      _ProgressCelebrationOverlayState();
}

class _ProgressCelebrationOverlayState
    extends State<ProgressCelebrationOverlay> with TickerProviderStateMixin {
  bool _started = false;
  int _displayXpEnNivel = 0;
  int _displayXpParaSiguiente = 100;
  int _displayNivel = 1;
  String _displayRango = 'Novato';
  double _progressFrom = 0;
  bool _showOverlay = false;
  String? _bannerTitle;
  String? _bannerSubtitle;
  bool _isLevelUp = false;

  late final AnimationController _burstCtrl;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _burstCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _burstCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _maybePlayQueue());
    }
  }

  Future<void> _maybePlayQueue() async {
    final userId = context.read<AuthController>().currentUser?.id;
    if (userId == null) return;

    final progressCtrl = context.read<AccountProgressController>();
    final progress = progressCtrl.progress;
    if (progress == null || progress.eventosPendientes.isEmpty) return;

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
      if (!mounted) break;

      if (event.tipo == 'ACHIEVEMENT') {
        _triggerBanner(
          title: '¡LOGRO DESBLOQUEADO!',
          subtitle: event.tituloLogro ?? 'Logro desbloqueado',
          isLevelUp: false,
        );
        runningXp = event.xpEnNivelDespues;
        runningMax = event.xpParaSiguienteDespues;
        await _animateBar(prevRatio, runningXp, runningMax, runningLevel, runningRank);
        prevRatio = runningMax <= 0 ? 0 : runningXp / runningMax;
        await Future<void>.delayed(const Duration(milliseconds: 700));
      } else if (event.tipo == 'XP') {
        final xp = event.cantidadXp ?? 0;
        _triggerBanner(
          title: '+$xp XP',
          subtitle: 'Experiencia obtenida',
          isLevelUp: false,
        );
        runningXp = event.xpEnNivelDespues;
        runningMax = event.xpParaSiguienteDespues;
        await _animateBar(prevRatio, runningXp, runningMax, runningLevel, runningRank);
        prevRatio = runningMax <= 0 ? 0 : runningXp / runningMax;
        await Future<void>.delayed(const Duration(milliseconds: 500));
      } else if (event.tipo == 'LEVEL_UP') {
        runningLevel = event.nivelNuevo ?? runningLevel;
        runningRank = _rankForLevel(runningLevel);
        runningXp = event.xpEnNivelDespues;
        runningMax = event.xpParaSiguienteDespues;
        _triggerBanner(
          title: '¡SUBISTE DE NIVEL!',
          subtitle: 'NIVEL $runningLevel · ${runningRank.toUpperCase()}',
          isLevelUp: true,
        );
        await _animateBar(0, runningXp, runningMax, runningLevel, runningRank);
        prevRatio = runningMax <= 0 ? 0 : runningXp / runningMax;
        await Future<void>.delayed(const Duration(milliseconds: 1000));
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
        _isLevelUp = false;
      });
    }
  }

  void _triggerBanner({
    required String title,
    required String subtitle,
    required bool isLevelUp,
  }) {
    if (!mounted) return;
    _burstCtrl.reset();
    setState(() {
      _bannerTitle = title;
      _bannerSubtitle = subtitle;
      _isLevelUp = isLevelUp;
    });
    _burstCtrl.forward();
  }

  Future<void> _animateBar(
    double fromRatio,
    int xp,
    int maxXp,
    int level,
    String rank,
  ) async {
    if (!mounted) return;
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
        if (_showOverlay) _buildOverlay(),
      ],
    );
  }

  Widget _buildOverlay() {
    if (_isLevelUp && _bannerTitle != null) {
      return _LevelUpOverlay(
        level: _displayNivel,
        rank: _displayRango,
        burstCtrl: _burstCtrl,
        pulseCtrl: _pulseCtrl,
        xpDisplay: AccountLevelDisplay(
          nivel: _displayNivel,
          rango: _displayRango,
          xpEnNivel: _displayXpEnNivel,
          xpParaSiguiente: _displayXpParaSiguiente,
          animateProgress: true,
          displayXpEnNivel: _displayXpEnNivel,
          displayXpParaSiguiente: _displayXpParaSiguiente,
          progressFrom: _progressFrom,
        ),
      );
    }

    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.70),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_bannerTitle != null) ...[
                  _FloatInWidget(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            XiColors.surfaceElevated,
                            XiColors.surfaceCard,
                          ],
                        ),
                        border: Border.all(
                          color: XiColors.royalBlue.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: XiColors.royalBlue.withValues(alpha: 0.25),
                            blurRadius: 24,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            _bannerTitle!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Lumiare',
                              color: XiColors.warmWhite,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (_bannerSubtitle != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              _bannerSubtitle!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Lumiare',
                                color: XiColors.techCyan,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
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
    );
  }
}

// ── Overlay de subida de nivel ────────────────────────────────────────────────

class _LevelUpOverlay extends StatelessWidget {
  const _LevelUpOverlay({
    required this.level,
    required this.rank,
    required this.burstCtrl,
    required this.pulseCtrl,
    required this.xpDisplay,
  });

  final int level;
  final String rank;
  final AnimationController burstCtrl;
  final AnimationController pulseCtrl;
  final Widget xpDisplay;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Fondo: explosión de color
            Positioned.fill(
              child: AnimatedBuilder(
                animation: burstCtrl,
                builder: (context, _) => CustomPaint(
                  painter: _BurstPainter(progress: burstCtrl.value),
                ),
              ),
            ),

            // Partículas de celebración
            Positioned.fill(
              child: AnimatedBuilder(
                animation: burstCtrl,
                builder: (context, _) => CustomPaint(
                  painter: _LevelUpParticles(
                    progress: burstCtrl.value,
                    seed: level,
                  ),
                ),
              ),
            ),

            // Contenido centrado
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // "SUBISTE DE NIVEL"
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 400),
                      builder: (context, v, child) =>
                          Opacity(opacity: v, child: child),
                      child: const Text(
                        '¡SUBISTE DE NIVEL!',
                        style: TextStyle(
                          fontFamily: 'Lumiare',
                          color: XiColors.classicGold,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4.0,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    AnimatedBuilder(
                      animation: pulseCtrl,
                      builder: (context, _) {
                        final glow = 0.3 + pulseCtrl.value * 0.5;
                        return Text(
                          '$level',
                          style: TextStyle(
                            fontFamily: 'Lumiare',
                            color: XiColors.warmWhite,
                            fontSize: 120,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                            shadows: [
                              Shadow(
                                color: XiColors.classicGold.withValues(
                                  alpha: glow,
                                ),
                                blurRadius: 60,
                              ),
                              Shadow(
                                color: XiColors.energyOrange.withValues(
                                  alpha: glow * 0.65,
                                ),
                                blurRadius: 36,
                              ),
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 350.ms)
                            .scale(
                              begin: const Offset(0.35, 0.35),
                              end: const Offset(1, 1),
                              duration: 750.ms,
                              curve: Curves.easeOutBack,
                            )
                            .shake(hz: 2.5, duration: 500.ms, delay: 400.ms);
                      },
                    ),

                    // Línea decorativa
                    Container(
                      width: 80,
                      height: 2,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            XiColors.classicGold,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Rango
                    Text(
                      rank.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Lumiare',
                        color: XiColors.techLightGray,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3.0,
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Barra de XP
                    xpDisplay,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widget de float-in ────────────────────────────────────────────────────────

class _FloatInWidget extends StatefulWidget {
  const _FloatInWidget({required this.child});

  final Widget child;

  @override
  State<_FloatInWidget> createState() => _FloatInWidgetState();
}

class _FloatInWidgetState extends State<_FloatInWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ── Painters ──────────────────────────────────────────────────────────────────

class _BurstPainter extends CustomPainter {
  const _BurstPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Fondo oscuro semitransparente
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.82),
    );

    // Explosión radial dorada
    final maxR = size.width * 1.2;
    final r = maxR * math.min(1.0, progress * 1.5);
    final alpha = (1.0 - progress * 0.7).clamp(0.0, 1.0);
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.85,
          colors: [
            XiColors.classicGold.withValues(alpha: 0.18 * alpha),
            XiColors.royalBlue.withValues(alpha: 0.12 * alpha),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(center: Offset(cx, cy), radius: r),
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) =>
      old.progress != progress;
}

class _LevelUpParticles extends CustomPainter {
  const _LevelUpParticles({required this.progress, required this.seed});

  final double progress;
  final int seed;

  static const _colors = [
    XiColors.classicGold,
    XiColors.techCyan,
    XiColors.royalBlue,
    XiColors.emeraldGreen,
    XiColors.energyOrange,
    XiColors.warmWhite,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final rnd = math.Random(seed);
    final cx = size.width / 2;
    final cy = size.height * 0.42;

    for (var i = 0; i < 50; i++) {
      final angle = rnd.nextDouble() * math.pi * 2;
      final speed = (0.3 + rnd.nextDouble() * 0.7) * size.height * 0.55;
      final x = cx + math.cos(angle) * speed * progress;
      final y = cy + math.sin(angle) * speed * progress +
          0.5 * 800 * progress * progress; // gravedad
      final alpha = (1.0 - progress * 1.3).clamp(0.0, 1.0);
      final r = 2.5 + rnd.nextDouble() * 4.0;
      final color = _colors[i % _colors.length];

      if (i % 3 == 0) {
        // Cuadrado rotado
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(progress * math.pi * 4 + i);
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: r * 1.8,
            height: r * 0.9,
          ),
          Paint()..color = color.withValues(alpha: alpha),
        );
        canvas.restore();
      } else {
        canvas.drawCircle(
          Offset(x, y),
          r,
          Paint()..color = color.withValues(alpha: alpha),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LevelUpParticles old) =>
      old.progress != progress;
}
