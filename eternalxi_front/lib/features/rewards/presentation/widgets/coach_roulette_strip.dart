import 'dart:math' as math;

import 'package:eternal_xi/app/localization/rewards_l10n.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/core/utils/league_asset_urls.dart';
import 'package:eternal_xi/core/utils/league_coach_photo.dart';
import 'package:eternal_xi/features/rewards/data/models/reward_coach_item.dart';
import 'package:flutter/material.dart';

enum _RoulettePhase { tension, spinning, result }

// ── Dialog público ────────────────────────────────────────────────────────────

Future<void> showCoachRouletteDialog({
  required BuildContext context,
  required List<RewardCoachItem> itemsRuleta,
  required RewardCoachItem entrenadorGanador,
}) async {
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'roulette',
    barrierColor: Colors.black.withValues(alpha: 0.96),
    transitionDuration: const Duration(milliseconds: 320),
    transitionBuilder: (ctx, anim, _, child) => FadeTransition(
      opacity: anim,
      child: child,
    ),
    pageBuilder: (ctx, _, __) => _RouletteDialog(
      itemsRuleta: itemsRuleta,
      entrenadorGanador: entrenadorGanador,
    ),
  );
}

// ── Dialog con fases ──────────────────────────────────────────────────────────

class _RouletteDialog extends StatefulWidget {
  const _RouletteDialog({
    required this.itemsRuleta,
    required this.entrenadorGanador,
  });

  final List<RewardCoachItem> itemsRuleta;
  final RewardCoachItem entrenadorGanador;

  @override
  State<_RouletteDialog> createState() => _RouletteDialogState();
}

class _RouletteDialogState extends State<_RouletteDialog>
    with TickerProviderStateMixin {
  _RoulettePhase _phase = _RoulettePhase.tension;
  late final AnimationController _pulse;
  late final AnimationController _celebrate;
  double _flashOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _celebrate = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _runSequence();
  }

  Future<void> _runSequence() async {
    // Fase 1: tensión (1.6 s)
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    setState(() => _phase = _RoulettePhase.spinning);
  }

  void _onSpinFinished() {
    if (!mounted) return;
    // Flash y transición a resultado
    setState(() => _flashOpacity = 0.95);
    Future<void>.delayed(const Duration(milliseconds: 100)).then((_) {
      if (!mounted) return;
      setState(() {
        _flashOpacity = 0.0;
        _phase = _RoulettePhase.result;
      });
      _celebrate.forward();
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _celebrate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rl10n = RewardsL10n.of(context);

    return Stack(
      children: [
        // Partículas de fondo (siempre activas)
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) => CustomPaint(
              painter: _RouletteBgPainter(
                pulse: _pulse.value,
                intense: _phase == _RoulettePhase.result,
              ),
            ),
          ),
        ),

        // Flash al revelar resultado
        if (_flashOpacity > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _flashOpacity,
                duration: const Duration(milliseconds: 180),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      colors: [Colors.white, XiColors.classicGold, Colors.transparent],
                      radius: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Contenido principal
        Material(
          color: Colors.transparent,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: _phase == _RoulettePhase.result
                          ? () => Navigator.of(context).pop()
                          : null,
                      icon: Icon(
                        Icons.close_rounded,
                        color: _phase == _RoulettePhase.result
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.transparent,
                      ),
                    ),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.88, end: 1.0).animate(
                            CurvedAnimation(
                              parent: anim,
                              curve: Curves.easeOutBack,
                            ),
                          ),
                          child: child,
                        ),
                      ),
                      child: _buildPhase(rl10n),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhase(RewardsL10n rl10n) {
    switch (_phase) {
      case _RoulettePhase.tension:
        return _TensionPhase(key: const ValueKey('tension'), pulse: _pulse);
      case _RoulettePhase.spinning:
        return _SpinningPhase(
          key: const ValueKey('spin'),
          itemsRuleta: widget.itemsRuleta,
          entrenadorGanador: widget.entrenadorGanador,
          onFinished: _onSpinFinished,
          rl10n: rl10n,
        );
      case _RoulettePhase.result:
        return _ResultPhase(
          key: const ValueKey('result'),
          winner: widget.entrenadorGanador,
          celebrate: _celebrate,
          rl10n: rl10n,
          onClose: () => Navigator.of(context).pop(),
        );
    }
  }
}

// ── Fase: tensión ─────────────────────────────────────────────────────────────

class _TensionPhase extends StatefulWidget {
  const _TensionPhase({super.key, required this.pulse});

  final AnimationController pulse;

  @override
  State<_TensionPhase> createState() => _TensionPhaseState();
}

class _TensionPhaseState extends State<_TensionPhase>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Icono giratorio con glow
        AnimatedBuilder(
          animation: _spin,
          builder: (context, _) {
            return Transform.rotate(
              angle: _spin.value * 2 * math.pi,
              child: AnimatedBuilder(
                animation: widget.pulse,
                builder: (context, child) {
                  final glow = 0.2 + widget.pulse.value * 0.45;
                  return Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [XiColors.classicGold, XiColors.energyOrange],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: XiColors.classicGold.withValues(alpha: glow),
                          blurRadius: 40,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        '⚙',
                        style: TextStyle(
                          fontSize: 42,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),

        const SizedBox(height: 40),

        const Text(
          'RULETA DEL',
          style: TextStyle(
            fontFamily: 'Lumiare',
            color: XiColors.steelGray,
            fontSize: 13,
            letterSpacing: 5.0,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'ENTRENADOR',
          style: TextStyle(
            fontFamily: 'Lumiare',
            color: XiColors.warmWhite,
            fontSize: 32,
            letterSpacing: 2.5,
            height: 1.0,
          ),
        ),

        const SizedBox(height: 36),

        // Puntos de carga
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.2, end: 1.0),
              duration: Duration(milliseconds: 300 + i * 180),
              builder: (ctx, v, _) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: XiColors.classicGold.withValues(alpha: v),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ── Fase: giro ────────────────────────────────────────────────────────────────

class _SpinningPhase extends StatelessWidget {
  const _SpinningPhase({
    super.key,
    required this.itemsRuleta,
    required this.entrenadorGanador,
    required this.onFinished,
    required this.rl10n,
  });

  final List<RewardCoachItem> itemsRuleta;
  final RewardCoachItem entrenadorGanador;
  final VoidCallback onFinished;
  final RewardsL10n rl10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '¿QUIÉN SERÁ?',
          style: TextStyle(
            fontFamily: 'Lumiare',
            color: XiColors.techLightGray,
            fontSize: 11,
            letterSpacing: 4.0,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'GIRANDO...',
          style: TextStyle(
            fontFamily: 'Lumiare',
            color: XiColors.warmWhite,
            fontSize: 26,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        CoachRouletteStrip(
          itemsRuleta: itemsRuleta,
          entrenadorGanador: entrenadorGanador,
          onFinished: onFinished,
        ),
        const SizedBox(height: 24),
        Text(
          rl10n.coachRouletteHint,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Lumiare',
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ── Fase: resultado ───────────────────────────────────────────────────────────

class _ResultPhase extends StatelessWidget {
  const _ResultPhase({
    super.key,
    required this.winner,
    required this.celebrate,
    required this.rl10n,
    required this.onClose,
  });

  final RewardCoachItem winner;
  final AnimationController celebrate;
  final RewardsL10n rl10n;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final photoUrl = LeagueCoachPhoto.resolveUrl(
      idEntrenador: winner.idEntrenador,
      foto: winner.foto,
    );
    final hasTeam = winner.idEquipo != null && winner.idEquipo! > 0;
    final teamUrl = hasTeam
        ? LeagueAssetUrls.teamBadge(winner.idEquipo!).toString()
        : null;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Confetti painter
        AnimatedBuilder(
          animation: celebrate,
          builder: (context, _) => CustomPaint(
            size: const Size(double.infinity, 80),
            painter: _ConfettiPainter(
              progress: celebrate.value,
              seed: winner.idEntrenador,
            ),
          ),
        ),

        // Label
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          builder: (context, v, child) =>
              Opacity(opacity: v, child: child),
          child: const Text(
            '¡TU NUEVO ENTRENADOR!',
            style: TextStyle(
              fontFamily: 'Lumiare',
              color: XiColors.classicGold,
              fontSize: 11,
              letterSpacing: 4.0,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Avatar grande del ganador con glow dorado
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.7, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: AnimatedBuilder(
            animation: celebrate,
            builder: (context, child) {
              final glow = 0.25 + math.sin(celebrate.value * math.pi * 2) * 0.2;
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: XiColors.classicGold.withValues(alpha: glow),
                      blurRadius: 50,
                      spreadRadius: 6,
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2A3F60), Color(0xFF151E32)],
                    ),
                    border: Border.fromBorderSide(
                      BorderSide(color: XiColors.classicGold, width: 2.5),
                    ),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: _CoachAvatarLarge(
                    photoUrl: photoUrl,
                    initials: winner.initials,
                  ),
                ),
                if (teamUrl != null)
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: XiColors.surfaceContainer,
                        border: Border.fromBorderSide(
                          BorderSide(color: XiColors.classicGold, width: 1.5),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.network(
                        teamUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.shield_outlined,
                          size: 18,
                          color: XiColors.steelGray,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Nombre del entrenador
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 500),
          builder: (context, v, child) =>
              Opacity(opacity: v, child: child),
          child: Column(
            children: [
              Text(
                winner.displayName.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Lumiare',
                  color: XiColors.warmWhite,
                  fontSize: 26,
                  letterSpacing: 1.2,
                  height: 1.1,
                ),
              ),
              if ((winner.nombreEquipo?.trim() ?? '').isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  winner.nombreEquipo!.trim(),
                  style: const TextStyle(
                    fontFamily: 'Lumiare',
                    color: XiColors.techLightGray,
                    fontSize: 14,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
              if (winner.bonusPuntos > 0) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: XiColors.classicGold.withValues(alpha: 0.12),
                    border: Border.all(
                      color: XiColors.classicGold.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    '+${winner.bonusPuntos} pts bonus',
                    style: const TextStyle(
                      fontFamily: 'Lumiare',
                      color: XiColors.classicGold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 40),

        // Botón cerrar
        GestureDetector(
          onTap: onClose,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 48),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xFF2F62D8), XiColors.royalBlue],
              ),
              boxShadow: [
                BoxShadow(
                  color: XiColors.royalBlue.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Text(
              'CONTINUAR',
              style: TextStyle(
                fontFamily: 'Lumiare',
                color: XiColors.warmWhite,
                fontSize: 14,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Strip de ruleta (widget interno) ─────────────────────────────────────────

class CoachRouletteStrip extends StatefulWidget {
  const CoachRouletteStrip({
    super.key,
    required this.itemsRuleta,
    required this.entrenadorGanador,
    required this.onFinished,
  });

  final List<RewardCoachItem> itemsRuleta;
  final RewardCoachItem entrenadorGanador;
  final VoidCallback onFinished;

  @override
  State<CoachRouletteStrip> createState() => _CoachRouletteStripState();
}

class _CoachRouletteStripState extends State<CoachRouletteStrip>
    with SingleTickerProviderStateMixin {
  final ScrollController _sc = ScrollController();
  static const double _itemW = 110;
  bool _started = false;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_started || !mounted) return;
      _started = true;
      _runAnimation();
    });
  }

  List<RewardCoachItem> get _base {
    if (widget.itemsRuleta.isNotEmpty) return widget.itemsRuleta;
    return List<RewardCoachItem>.filled(6, widget.entrenadorGanador);
  }

  List<RewardCoachItem> _buildStrip() {
    final base = _base;
    final out = <RewardCoachItem>[];
    for (var i = 0; i < 48; i++) {
      out.add(base[i % base.length]);
    }
    const winSlot = 36;
    if (winSlot < out.length) out[winSlot] = widget.entrenadorGanador;
    return out;
  }

  @override
  void dispose() {
    _pulse.dispose();
    _sc.dispose();
    super.dispose();
  }

  Future<void> _runAnimation() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (!mounted || !_sc.hasClients) {
      widget.onFinished();
      return;
    }
    const winSlot = 36;
    final target =
        (winSlot * _itemW).clamp(0.0, _sc.position.maxScrollExtent);
    final jitter =
        math.Random(widget.entrenadorGanador.idEntrenador).nextDouble() * 0.45;
    final ms = (4800 + jitter * 900).round();
    try {
      await _sc.animateTo(
        target,
        duration: Duration(milliseconds: ms),
        curve: Curves.easeOutQuart,
      );
    } catch (_) {}
    if (mounted) widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final strip = _buildStrip();
    return LayoutBuilder(
      builder: (context, c) {
        final vw = c.maxWidth;
        final pad = vw / 2 - _itemW / 2;
        return Container(
          height: 156,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: const Color(0xFF080C14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              // Degradado lateral izquierdo (oscurece los items no centrados)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: vw * 0.22,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        const Color(0xFF080C14),
                        const Color(0xFF080C14).withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),

              // Degradado lateral derecho
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: vw * 0.22,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                        const Color(0xFF080C14),
                        const Color(0xFF080C14).withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),

              // Strip
              ListView.builder(
                controller: _sc,
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: pad),
                itemExtent: _itemW,
                itemCount: strip.length,
                itemBuilder: (_, i) => _CoachMiniCard(coach: strip[i]),
              ),

              // Puntero central con glow
              Positioned(
                left: vw / 2 - 2,
                top: 6,
                bottom: 6,
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, _) {
                    final glow = 0.4 + _pulse.value * 0.55;
                    return Container(
                      width: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            XiColors.classicGold,
                            XiColors.energyOrange,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: XiColors.classicGold.withValues(alpha: glow),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Mini card del strip ───────────────────────────────────────────────────────

class _CoachMiniCard extends StatelessWidget {
  const _CoachMiniCard({required this.coach});

  final RewardCoachItem coach;

  static const double _avatarR = 26;

  @override
  Widget build(BuildContext context) {
    final photoUrl = LeagueCoachPhoto.resolveUrl(
      idEntrenador: coach.idEntrenador,
      foto: coach.foto,
    );
    final hasTeamId = coach.idEquipo != null && coach.idEquipo! > 0;
    final teamUrl =
        hasTeamId ? LeagueAssetUrls.teamBadge(coach.idEquipo!).toString() : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1C2844), Color(0xFF101828)],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                _RouletteCoachAvatar(
                  radius: _avatarR,
                  photoUrl: photoUrl,
                  initials: coach.initials,
                ),
                Positioned(
                  right: -5,
                  bottom: -3,
                  child: _RouletteTeamBadge(teamUrl: teamUrl),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                coach.pila.trim().isNotEmpty ? coach.pila : coach.nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Lumiare',
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                (coach.nombreEquipo ?? '').trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Lumiare',
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Avatar grande para resultado ──────────────────────────────────────────────

class _CoachAvatarLarge extends StatelessWidget {
  const _CoachAvatarLarge({required this.photoUrl, required this.initials});

  final String? photoUrl;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final trimmed = photoUrl?.trim() ?? '';
    if (trimmed.isEmpty) {
      return _Placeholder(initials: initials, fontSize: 40);
    }
    return Image.network(
      trimmed,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) =>
          _Placeholder(initials: initials, fontSize: 40),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.initials, required this.fontSize});

  final String initials;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF1C2844),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontFamily: 'Lumiare',
            color: XiColors.warmWhite,
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }
}

// ── Avatar del strip ──────────────────────────────────────────────────────────

class _RouletteCoachAvatar extends StatelessWidget {
  const _RouletteCoachAvatar({
    required this.radius,
    required this.photoUrl,
    required this.initials,
  });

  final double radius;
  final String? photoUrl;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final d = radius * 2;
    final trimmed = photoUrl?.trim() ?? '';
    Widget placeholder() {
      return Container(
        width: d,
        height: d,
        color: const Color(0xFF1C2844),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: TextStyle(
            fontFamily: 'Lumiare',
            color: XiColors.warmWhite,
            fontSize: radius * 0.55,
          ),
        ),
      );
    }

    if (trimmed.isEmpty) {
      return ClipOval(child: SizedBox(width: d, height: d, child: placeholder()));
    }

    return ClipOval(
      child: SizedBox(
        width: d,
        height: d,
        child: Image.network(
          trimmed,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => placeholder(),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              width: d,
              height: d,
              color: const Color(0xFF1A2233),
              alignment: Alignment.center,
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  color: XiColors.techCyan.withValues(alpha: 0.7),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Escudo del equipo ─────────────────────────────────────────────────────────

class _RouletteTeamBadge extends StatelessWidget {
  const _RouletteTeamBadge({required this.teamUrl});

  final String? teamUrl;

  @override
  Widget build(BuildContext context) {
    const size = 20.0;
    Widget shield() {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF0D1018),
          border: Border.all(color: Colors.white24),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.shield_outlined,
          size: 11,
          color: Colors.white.withValues(alpha: 0.55),
        ),
      );
    }

    final u = teamUrl?.trim() ?? '';
    if (u.isEmpty) return shield();

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF0D1018),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        u,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => shield(),
      ),
    );
  }
}

// ── Painters ──────────────────────────────────────────────────────────────────

class _RouletteBgPainter extends CustomPainter {
  const _RouletteBgPainter({required this.pulse, required this.intense});

  final double pulse;
  final bool intense;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(42);
    final count = intense ? 55 : 20;
    for (var i = 0; i < count; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final r = 0.8 + rnd.nextDouble() * 2.0 + pulse * 1.5;
      final alpha = (0.08 + rnd.nextDouble() * 0.16 + pulse * 0.12).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = XiColors.classicGold.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RouletteBgPainter old) =>
      old.pulse != pulse || old.intense != intense;
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.progress, required this.seed});

  final double progress;
  final int seed;

  static const _colors = [
    XiColors.classicGold,
    XiColors.techCyan,
    XiColors.royalBlue,
    XiColors.energyOrange,
    XiColors.emeraldGreen,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed);
    for (var i = 0; i < 40; i++) {
      final startX = rnd.nextDouble() * size.width;
      final speedX = (rnd.nextDouble() - 0.5) * size.width * 0.4;
      final speedY = size.height * (0.6 + rnd.nextDouble() * 1.2);
      final x = startX + speedX * progress;
      final y = -10 + speedY * progress;
      final color = _colors[i % _colors.length];
      final alpha = (1.0 - progress).clamp(0.0, 1.0);

      // Alterna entre círculos y rectángulos rotados
      if (i.isEven) {
        canvas.drawCircle(
          Offset(x, y),
          2.5 + rnd.nextDouble() * 2.0,
          Paint()..color = color.withValues(alpha: alpha),
        );
      } else {
        final angle = rnd.nextDouble() * math.pi * 2 + progress * math.pi * 3;
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(angle);
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: 5 + rnd.nextDouble() * 5,
            height: 3 + rnd.nextDouble() * 2,
          ),
          Paint()..color = color.withValues(alpha: alpha),
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}
