import 'dart:math' as math;

import 'package:eternal_xi/app/localization/rewards_l10n.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/features/rewards/data/models/reward_card_model.dart';
import 'package:eternal_xi/features/rewards/data/models/reward_pack_open_result.dart';
import 'package:eternal_xi/features/rewards/presentation/widgets/rarity_badge.dart';
import 'package:eternal_xi/features/rewards/utils/reward_formatters.dart';
import 'package:eternal_xi/features/rewards/utils/reward_rarity_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum _PackPhase { waiting, shaking, flapOpen, cardFlying, money, card }

/// Diálogo a pantalla completa con sobre físico dibujado que se abre al tocar.
class PackOpeningAnimationDialog extends StatefulWidget {
  const PackOpeningAnimationDialog({
    super.key,
    required this.result,
    required this.onViewCards,
    required this.onClose,
  });

  final RewardPackOpenResult result;
  final VoidCallback onViewCards;
  final VoidCallback onClose;

  @override
  State<PackOpeningAnimationDialog> createState() =>
      _PackOpeningAnimationDialogState();
}

class _PackOpeningAnimationDialogState
    extends State<PackOpeningAnimationDialog> with TickerProviderStateMixin {
  _PackPhase _phase = _PackPhase.waiting;

  // Shake animation
  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;

  // Flap open animation
  late final AnimationController _flapCtrl;
  late final Animation<double> _flapAnim;

  // Card fly animation
  late final AnimationController _flyCtrl;
  late final Animation<double> _flyAnim;

  // Background pulse
  late final AnimationController _pulseCtrl;

  // Bloom for card reveal
  late final AnimationController _bloomCtrl;

  bool _cardFlipped = false;
  double _flashOpacity = 0.0;
  int _moneyDisplay = 0;

  @override
  void initState() {
    super.initState();

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticOut),
    );

    _flapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _flapAnim = CurvedAnimation(parent: _flapCtrl, curve: Curves.easeOutCubic);

    _flyCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _flyAnim = CurvedAnimation(parent: _flyCtrl, curve: Curves.easeOutBack);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _bloomCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _flapCtrl.dispose();
    _flyCtrl.dispose();
    _pulseCtrl.dispose();
    _bloomCtrl.dispose();
    super.dispose();
  }

  Future<void> _onTapEnvelope() async {
    if (_phase != _PackPhase.waiting) return;

    // 1. Shake
    setState(() => _phase = _PackPhase.shaking);
    await _shakeCtrl.forward();
    _shakeCtrl.reset();
    if (!mounted) return;

    // 2. Flap opens
    setState(() => _phase = _PackPhase.flapOpen);
    await _flapCtrl.forward();
    if (!mounted) return;

    // 3. Flash
    setState(() => _flashOpacity = 0.9);
    await Future<void>.delayed(const Duration(milliseconds: 140));
    if (!mounted) return;
    setState(() => _flashOpacity = 0.0);

    // 4. Card flying out
    setState(() => _phase = _PackPhase.cardFlying);
    await _flyCtrl.forward();
    if (!mounted) return;

    await Future<void>.delayed(const Duration(milliseconds: 480));
    if (!mounted) return;

    // 5. Money counter
    setState(() => _phase = _PackPhase.money);
    final target = widget.result.dineroGanado;
    const steps = 16;
    for (var i = 1; i <= steps; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 75));
      if (!mounted) return;
      setState(() => _moneyDisplay = ((target * i) / steps).round());
    }
    setState(() => _moneyDisplay = target);

    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (!mounted) return;

    // 6. Card reveal
    setState(() {
      _phase = _PackPhase.card;
      _cardFlipped = false;
    });
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _cardFlipped = true);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _bloomCtrl.forward();
  }

  String get _rareza => widget.result.cartaObtenida.rareza.toUpperCase();

  bool get _premium =>
      _rareza == 'LEGENDARY' || _rareza == 'SUPER_RARE' || _rareza == 'SPECIAL';

  @override
  Widget build(BuildContext context) {
    final card = widget.result.cartaObtenida;
    final style = styleForRarity(card.rareza);
    final rl10n = context.rewardsL10n;

    return Dialog.fullscreen(
      backgroundColor: const Color(0xFF050810),
      child: Stack(
        children: [
          // Background particles (always)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => CustomPaint(
                painter: _ParticlePainter(
                  seed: card.idCarta,
                  pulse: _pulseCtrl.value,
                  glowColor: style.glow,
                  premium: _premium,
                ),
              ),
            ),
          ),

          // White flash
          if (_flashOpacity > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _flashOpacity,
                  duration: const Duration(milliseconds: 180),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.0,
                        colors: [
                          Colors.white.withValues(alpha: 0.92),
                          style.glow.withValues(alpha: 0.45),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: widget.onClose,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                            CurvedAnimation(
                              parent: anim,
                              curve: Curves.easeOutBack,
                            ),
                          ),
                          child: child,
                        ),
                      ),
                      child: _buildPhase(style, card, rl10n),
                    ),
                  ),
                  if (_phase == _PackPhase.card && _cardFlipped)
                    _buildActionButtons(rl10n),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhase(
    RewardRarityStyle style,
    RewardCardModel card,
    RewardsL10n rl10n,
  ) {
    switch (_phase) {
      case _PackPhase.waiting:
      case _PackPhase.shaking:
      case _PackPhase.flapOpen:
      case _PackPhase.cardFlying:
        return _PhysicalEnvelope(
          key: const ValueKey('envelope'),
          phase: _phase,
          style: style,
          premium: _premium,
          shakeAnim: _shakeAnim,
          flapAnim: _flapAnim,
          flyAnim: _flyAnim,
          pulse: _pulseCtrl,
          onTap: _onTapEnvelope,
          rl10n: rl10n,
        );
      case _PackPhase.money:
        return _MoneyReveal(
          key: const ValueKey('money'),
          amount: _moneyDisplay,
          rl10n: rl10n,
        );
      case _PackPhase.card:
        return _CardReveal(
          key: ValueKey(_cardFlipped),
          flipped: _cardFlipped,
          style: style,
          card: card,
          bloom: _bloomCtrl,
          rl10n: rl10n,
        );
    }
  }

  Widget _buildActionButtons(RewardsL10n rl10n) {
    return Row(
      children: [
        Expanded(
          child: _XiOutlinedButton(
            label: rl10n.viewMyCards,
            onTap: widget.onViewCards,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _XiFilledButton(label: rl10n.close, onTap: widget.onClose),
        ),
      ],
    );
  }
}

// ── Physical envelope ─────────────────────────────────────────────────────────

class _PhysicalEnvelope extends StatelessWidget {
  const _PhysicalEnvelope({
    super.key,
    required this.phase,
    required this.style,
    required this.premium,
    required this.shakeAnim,
    required this.flapAnim,
    required this.flyAnim,
    required this.pulse,
    required this.onTap,
    required this.rl10n,
  });

  final _PackPhase phase;
  final RewardRarityStyle style;
  final bool premium;
  final Animation<double> shakeAnim;
  final Animation<double> flapAnim;
  final Animation<double> flyAnim;
  final AnimationController pulse;
  final VoidCallback onTap;
  final RewardsL10n rl10n;

  bool get _premium => premium;

  @override
  Widget build(BuildContext context) {
    final isWaiting = phase == _PackPhase.waiting;
    final isShaking = phase == _PackPhase.shaking;
    final isFlapOpen = phase == _PackPhase.flapOpen;
    final isFlying = phase == _PackPhase.cardFlying;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isWaiting)
          AnimatedBuilder(
            animation: pulse,
            builder: (_, child) => Opacity(
              opacity: 0.35 + pulse.value * 0.65,
              child: child,
            ),
            child: Text(
              rl10n.packTapToOpen,
              style: const TextStyle(
                fontFamily: 'Lumiare',
                color: XiColors.techCyan,
                fontSize: 14,
                letterSpacing: 3.5,
              ),
            ),
          ),

        if (!isWaiting)
          SizedBox(
            height: 18,
            child: Text(
              rl10n.packOpening,
              style: TextStyle(
                fontFamily: 'Lumiare',
                color: Colors.white.withValues(alpha: 0.92),
                fontSize: 14,
                letterSpacing: 3.5,
              ),
            ),
          ),

        const SizedBox(height: 32),

        // Envelope with glow
        AnimatedBuilder(
          animation: Listenable.merge([shakeAnim, flapAnim, flyAnim, pulse]),
          builder: (context, _) {
            // Shake offset: sinusoidal horizontal wobble
            final shakeX = isShaking
                ? math.sin(shakeAnim.value * math.pi * 6) * 12
                : 0.0;
            // Envelope lifts up during flap open
            final liftY = isFlapOpen || isFlying
                ? -flapAnim.value * 12
                : 0.0;
            // Card exits envelope flying up
            final cardOffsetY = isFlying ? -flyAnim.value * 220 : 0.0;
            final cardScale = isFlying ? 0.5 + flyAnim.value * 0.5 : 0.5;
            final cardOpacity = isFlying ? flyAnim.value : 0.0;
            final fillPulse = 0.55 + pulse.value * 0.45;
            final sealOpacity =
                (1.0 - (flapAnim.value / 0.55).clamp(0.0, 1.0)).clamp(0.0, 1.0);

            final envScale = 1.0 + pulse.value * 0.012;

            return GestureDetector(
              onTap: isWaiting ? onTap : null,
              child: SizedBox(
                width: 280,
                height: 320,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // 1. Cuerpo del sobre (fondo)
                    Positioned(
                      bottom: 20,
                      child: Transform.translate(
                        offset: Offset(shakeX, liftY),
                        child: Transform.scale(
                          scale: envScale,
                          child: _buildEnvelopePart(
                            part: _EnvelopePart.body,
                            isWaiting: isWaiting,
                            fillPulse: fillPulse,
                          ),
                        ),
                      ),
                    ),

                    // 2. Solapa (detrás de la carta al salir)
                    Positioned(
                      bottom: 20,
                      child: Transform.translate(
                        offset: Offset(shakeX, liftY),
                        child: Transform.scale(
                          scale: envScale,
                          child: CustomPaint(
                            size: const Size(220, 160),
                            painter: _EnvelopePainter(
                              part: _EnvelopePart.flap,
                              flapProgress: flapAnim.value,
                              style: style,
                              fillPulse: fillPulse,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 3. Sello de cera (encima de la solapa)
                    if (sealOpacity > 0.02)
                      Positioned(
                        bottom: 20 + 160 * 0.55 - 14,
                        child: Transform.translate(
                          offset: Offset(shakeX, liftY),
                          child: Transform.scale(
                            scale: envScale,
                            child: Opacity(
                              opacity: sealOpacity,
                              child: CustomPaint(
                                size: const Size(28, 28),
                                painter: _WaxSealPainter(
                                  style: style,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // 4. Carta saliendo (delante de la solapa)
                    if (isFlying)
                      Positioned(
                        top: 72 + cardOffsetY,
                        child: Opacity(
                          opacity: cardOpacity.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: cardScale,
                            child: Container(
                              width: 140,
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: LinearGradient(
                                  colors: [
                                    style.gradient.first,
                                    style.gradient.length > 1
                                        ? style.gradient[1]
                                        : style.gradient.first,
                                    XiColors.navyBlue,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: style.glow.withValues(alpha: 0.6),
                                    blurRadius: 24,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: CustomPaint(
                                  size: Size(60, 60),
                                  painter: _ShieldPainter(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 32),

        if (isWaiting)
          // Tap hint dots
          AnimatedBuilder(
            animation: pulse,
            builder: (_, __) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final phase = (pulse.value + i * 0.33) % 1.0;
                  final dotScale = 0.6 + phase * 0.6;
                  final dotOpacity = 0.25 + phase * 0.75;
                  return Transform.scale(
                    scale: dotScale,
                    child: Opacity(
                      opacity: dotOpacity,
                      child: Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: XiColors.techCyan,
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
      ],
    );
  }

  Widget _buildEnvelopePart({
    required _EnvelopePart part,
    required bool isWaiting,
    required double fillPulse,
  }) {
    final glowIntensity = 0.18 + pulse.value * 0.30;
    final painter = CustomPaint(
      size: const Size(220, 160),
      painter: _EnvelopePainter(
        part: part,
        flapProgress: flapAnim.value,
        style: style,
        fillPulse: fillPulse,
      ),
    );

    if (part != _EnvelopePart.body) {
      return painter;
    }

    return Container(
      width: 220,
      height: 160,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: style.glow.withValues(alpha: glowIntensity),
            blurRadius: _premium ? 44 : 28,
            spreadRadius: _premium ? 4 : 1,
          ),
        ],
      ),
      child: painter
          .animate(
            target: isWaiting ? 1 : 0,
            onPlay: (c) => isWaiting ? c.repeat() : null,
          )
          .shimmer(
            duration: 1400.ms,
            color: XiColors.classicGold.withValues(alpha: 0.35),
          )
          .scale(
            begin: const Offset(0.98, 0.98),
            end: const Offset(1.02, 1.02),
            duration: 900.ms,
            curve: Curves.easeInOut,
          ),
    );
  }
}

enum _EnvelopePart { body, flap }

// ── Envelope painter ──────────────────────────────────────────────────────────

class _EnvelopePainter extends CustomPainter {
  static const double _foldYRatio = 0.12;
  static const double _foldOverlap = 2.5;

  final _EnvelopePart part;
  final double flapProgress;
  final RewardRarityStyle style;
  final double fillPulse;

  const _EnvelopePainter({
    required this.part,
    required this.flapProgress,
    required this.style,
    required this.fillPulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (part == _EnvelopePart.body) {
      _paintBody(canvas, size);
    } else {
      _paintFlap(canvas, size);
    }
  }

  List<Color> get _bodyColors {
    final g = style.gradient;
    if (g.length >= 3) {
      return [
        Color.lerp(const Color(0xFF0E1628), g[0], 0.35 + fillPulse * 0.25)!,
        Color.lerp(const Color(0xFF0E1628), g[1], 0.45 + fillPulse * 0.35)!,
        Color.lerp(const Color(0xFF0E1628), g[2], 0.55 + fillPulse * 0.40)!,
      ];
    }
    return [
      Color.lerp(const Color(0xFF0E1628), g.first, 0.40 + fillPulse * 0.30)!,
      Color.lerp(const Color(0xFF0E1628), g.last, 0.55 + fillPulse * 0.45)!,
    ];
  }

  void _paintBody(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final foldY = h * _foldYRatio;

    // Cuerpo con borde superior recto (sin radio) para unirse a la solapa.
    final bodyRect = Rect.fromLTWH(0, foldY - _foldOverlap, w, h - foldY + _foldOverlap);
    final bodyPath = Path()
      ..moveTo(bodyRect.left, bodyRect.top)
      ..lineTo(bodyRect.right, bodyRect.top)
      ..lineTo(bodyRect.right, bodyRect.bottom - 10)
      ..quadraticBezierTo(
        bodyRect.right,
        bodyRect.bottom,
        bodyRect.right - 10,
        bodyRect.bottom,
      )
      ..lineTo(bodyRect.left + 10, bodyRect.bottom)
      ..quadraticBezierTo(
        bodyRect.left,
        bodyRect.bottom,
        bodyRect.left,
        bodyRect.bottom - 10,
      )
      ..close();

    final bodyColors = _bodyColors;
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: bodyColors,
        stops: bodyColors.length == 3
            ? const [0.0, 0.45, 1.0]
            : const [0.0, 1.0],
      ).createShader(bodyRect);
    canvas.drawPath(bodyPath, bodyPaint);

    // Brillo de rareza que “rellena” el sobre desde abajo.
    final fillRect = Rect.fromLTWH(
      0,
      foldY + (h - foldY) * (1.0 - fillPulse),
      w,
      h,
    );
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          style.glow.withValues(alpha: 0.42 * fillPulse),
          style.glow.withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(fillRect);
    canvas.save();
    canvas.clipPath(bodyPath);
    canvas.drawRect(fillRect, fillPaint);
    canvas.restore();

    final borderPaint = Paint()
      ..color = style.border.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawPath(bodyPath, borderPaint);

    final foldPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final cx = w / 2;
    final by = h;
    canvas.drawLine(Offset(0, foldY), Offset(cx, h * 0.6), foldPaint);
    canvas.drawLine(Offset(w, foldY), Offset(cx, h * 0.6), foldPaint);
    canvas.drawLine(Offset(0, by), Offset(cx, h * 0.6), foldPaint);
    canvas.drawLine(Offset(w, by), Offset(cx, h * 0.6), foldPaint);

    if (flapProgress > 0.35) {
      final rayOpacity = ((flapProgress - 0.35) / 0.65).clamp(0.0, 1.0);
      final rayPaint = Paint()
        ..shader = RadialGradient(
          center: Alignment.topCenter,
          radius: 1.0,
          colors: [
            style.glow.withValues(alpha: 0.45 * rayOpacity),
            Colors.white.withValues(alpha: 0.18 * rayOpacity),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h));
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), rayPaint);
    }
  }

  void _paintFlap(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final foldY = h * _foldYRatio;

    final flapApexY = h * 0.6 - flapProgress * h * 1.1;
    final flapPath = Path()
      ..moveTo(0, foldY + _foldOverlap)
      ..lineTo(w, foldY + _foldOverlap)
      ..lineTo(cx, flapApexY)
      ..close();

    final flapColors = style.gradient.length >= 2
        ? [
            Color.lerp(const Color(0xFF1A2C48), style.gradient[0], 0.55)!,
            Color.lerp(const Color(0xFF1A2C48), style.gradient[1], 0.65)!,
          ]
        : [
            Color.lerp(const Color(0xFF1A2C48), style.gradient.first, 0.60)!,
            Color.lerp(const Color(0xFF1A2C48), style.gradient.last, 0.70)!,
          ];

    final flapPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: flapColors,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(flapPath, flapPaint);

    final flapBorderPaint = Paint()
      ..color = style.border.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    canvas.drawPath(flapPath, flapBorderPaint);

    // Línea de pliegue compartida (tapada sobre el cuerpo).
    final hingePaint = Paint()
      ..color = style.border.withValues(alpha: 0.35)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(0, foldY), Offset(w, foldY), hingePaint);
  }

  @override
  bool shouldRepaint(covariant _EnvelopePainter old) =>
      old.part != part ||
      old.flapProgress != flapProgress ||
      old.style != style ||
      old.fillPulse != fillPulse;
}

class _WaxSealPainter extends CustomPainter {
  const _WaxSealPainter({required this.style});

  final RewardRarityStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const radius = 13.0;

    canvas.drawCircle(
      Offset(cx, cy),
      radius + 2,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    final sealPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          style.badgeBackground,
          Color.lerp(style.badgeBackground, style.glow, 0.45)!,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius));
    canvas.drawCircle(Offset(cx, cy), radius, sealPaint);

    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..color = style.border.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: 'XI',
        style: TextStyle(
          color: style.badgeForeground,
          fontSize: 11,
          letterSpacing: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _WaxSealPainter old) => old.style != style;
}

// ── Money reveal ──────────────────────────────────────────────────────────────

String _packOpeningMoneyLabel(int amount) {
  return formatRewardMoney(amount)
      .replaceAll('M €', ' M €')
      .replaceAll('k €', ' k €')
      .replaceAll('B €', ' B €');
}

class _MoneyReveal extends StatelessWidget {
  const _MoneyReveal({super.key, required this.amount, required this.rl10n});
  final int amount;
  final RewardsL10n rl10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          rl10n.packReward,
          style: TextStyle(
            fontFamily: 'Lumiare',
            color: XiColors.classicGold.withValues(alpha: 0.85),
            fontSize: 14,
            letterSpacing: 4.0,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '+${_packOpeningMoneyLabel(amount)}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Lumiare',
            color: XiColors.classicGold,
            fontSize: 72,
            height: 1.0,
            letterSpacing: 2,
            shadows: [
              Shadow(color: Color(0xAAD9A441), blurRadius: 32),
              Shadow(color: Color(0x55D9A441), blurRadius: 64),
            ],
          ),
        ),
        const SizedBox(height: 20),
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
        const SizedBox(height: 20),
        Text(
          rl10n.openingPack.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Lumiare',
            color: Colors.white.withValues(alpha: 0.92),
            fontSize: 15,
            letterSpacing: 2.2,
          ),
        ),
      ],
    );
  }
}

// ── Card reveal ───────────────────────────────────────────────────────────────

class _CardReveal extends StatelessWidget {
  const _CardReveal({
    super.key,
    required this.flipped,
    required this.style,
    required this.card,
    required this.bloom,
    required this.rl10n,
  });

  final bool flipped;
  final RewardRarityStyle style;
  final RewardCardModel card;
  final AnimationController bloom;
  final RewardsL10n rl10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!flipped) ...[
          Text(
            rl10n.packYourCard,
            style: TextStyle(
              fontFamily: 'Lumiare',
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 14,
              letterSpacing: 3.5,
            ),
          ),
          const SizedBox(height: 24),
        ],
        _FlipCard3D(
          flipped: flipped,
          front: _CardFace(
            style: style,
            card: card,
            revealed: false,
            bloom: bloom,
            rl10n: rl10n,
          ),
          back: _CardFace(
            style: style,
            card: card,
            revealed: true,
            bloom: bloom,
            rl10n: rl10n,
          ),
        ),
        if (flipped) ...[
          const SizedBox(height: 28),
          RarityBadge(rarity: card.rareza),
        ],
      ],
    );
  }
}

// ── Card face ─────────────────────────────────────────────────────────────────

class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.style,
    required this.card,
    required this.revealed,
    required this.bloom,
    required this.rl10n,
  });

  final RewardRarityStyle style;
  final RewardCardModel card;
  final bool revealed;
  final AnimationController bloom;
  final RewardsL10n rl10n;

  @override
  Widget build(BuildContext context) {
    final effectLabel = rl10n.tipoEfectoLabel(card.tipoEfecto);
    final displayName = rl10n.cardDisplayName(card).trim();
    final cardTitle = displayName.isNotEmpty ? displayName : card.codigo;

    if (!revealed) {
      return Container(
        width: 260,
        height: 360,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A2540), Color(0xFF0D1525)],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          boxShadow: const [BoxShadow(color: Color(0xAA000000), blurRadius: 20)],
        ),
        child: Center(
          child: Opacity(
            opacity: 0.25,
            child: CustomPaint(
              size: const Size(120, 120),
              painter: _ShieldPainter(),
            ),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: bloom,
      builder: (context, child) {
        final sigma = rarityGlowSigma(card.rareza);
        final bloomSigma = sigma + bloom.value * sigma * 1.8;
        final bloomAlpha = 0.55 + bloom.value * 0.35;
        return Container(
          width: 260,
          height: 360,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: style.gradient,
            ),
            border: Border.all(color: style.border, width: 2.0),
            boxShadow: [
              BoxShadow(
                color: style.glow.withValues(alpha: bloomAlpha),
                blurRadius: bloomSigma,
                spreadRadius: bloom.value * 4,
              ),
            ],
          ),
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RarityBadge(rarity: card.rareza),
              const SizedBox(height: 14),
              Text(
                cardTitle,
                style: const TextStyle(
                  fontFamily: 'Lumiare',
                  color: Colors.white,
                  fontSize: 22,
                  height: 1.1,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 10),
              if (effectLabel.isNotEmpty) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Text(
                    effectLabel,
                    style: TextStyle(
                      fontFamily: 'Lumiare',
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Expanded(
                child: Text(
                  rl10n.cardDisplayDescription(card),
                  style: TextStyle(
                    fontFamily: 'Lumiare',
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 3D flip ───────────────────────────────────────────────────────────────────

class _FlipCard3D extends StatelessWidget {
  const _FlipCard3D({
    required this.flipped,
    required this.front,
    required this.back,
  });

  final bool flipped;
  final Widget front;
  final Widget back;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: flipped ? math.pi : 0),
      duration: const Duration(milliseconds: 760),
      curve: Curves.easeInOutCubic,
      builder: (context, angle, _) {
        final showBack = angle > math.pi / 2;
        final m = Matrix4.identity()..setEntry(3, 2, 0.0008);
        if (showBack) {
          m.rotateY(angle - math.pi);
          return Transform(alignment: Alignment.center, transform: m, child: back);
        }
        m.rotateY(angle);
        return Transform(alignment: Alignment.center, transform: m, child: front);
      },
    );
  }
}

// ── Particles ─────────────────────────────────────────────────────────────────

class _ParticlePainter extends CustomPainter {
  const _ParticlePainter({
    required this.seed,
    required this.pulse,
    required this.glowColor,
    required this.premium,
  });

  final int seed;
  final double pulse;
  final Color glowColor;
  final bool premium;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed);
    final count = premium ? 60 : 28;
    for (var i = 0; i < count; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final r = 0.9 + rnd.nextDouble() * 2.4 + pulse * 1.8;
      final alpha =
          (0.12 + rnd.nextDouble() * 0.22 + pulse * 0.18).clamp(0.0, 1.0);
      final isCross = rnd.nextBool() && premium;
      if (isCross) {
        final p = Paint()
          ..color = glowColor.withValues(alpha: alpha * 0.85)
          ..strokeWidth = r * 0.5
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(x - r, y), Offset(x + r, y), p);
        canvas.drawLine(Offset(x, y - r), Offset(x, y + r), p);
      } else {
        canvas.drawCircle(
          Offset(x, y),
          r,
          Paint()..color = glowColor.withValues(alpha: alpha),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) =>
      old.pulse != pulse || old.seed != seed;
}

// ── Shield painter ─────────────────────────────────────────────────────────────

class _ShieldPainter extends CustomPainter {
  const _ShieldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(w * 0.50, h * 0.04)
      ..lineTo(w * 0.92, h * 0.18)
      ..lineTo(w * 0.92, h * 0.56)
      ..quadraticBezierTo(w * 0.92, h * 0.80, w * 0.50, h * 0.96)
      ..quadraticBezierTo(w * 0.08, h * 0.80, w * 0.08, h * 0.56)
      ..lineTo(w * 0.08, h * 0.18)
      ..close();
    canvas.drawPath(path, paint);

    final divPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(w * 0.50, h * 0.04), Offset(w * 0.50, h * 0.96), divPaint);
    canvas.drawLine(Offset(w * 0.08, h * 0.46), Offset(w * 0.92, h * 0.46), divPaint);

    final tp = TextPainter(
      text: const TextSpan(
        text: 'XI',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(w * 0.5 - tp.width / 2, h * 0.5 - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Buttons ───────────────────────────────────────────────────────────────────

class _XiFilledButton extends StatelessWidget {
  const _XiFilledButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
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
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Lumiare',
            color: XiColors.warmWhite,
            fontSize: 14,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

class _XiOutlinedButton extends StatelessWidget {
  const _XiOutlinedButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: XiColors.techCyan.withValues(alpha: 0.5)),
          color: XiColors.techCyan.withValues(alpha: 0.06),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Lumiare',
            color: XiColors.techCyan,
            fontSize: 14,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

// ── Convenience function ──────────────────────────────────────────────────────

Future<void> showPackOpeningAnimationDialog({
  required BuildContext context,
  required RewardPackOpenResult result,
  required VoidCallback onViewCards,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PackOpeningAnimationDialog(
      result: result,
      onViewCards: () {
        Navigator.of(ctx).pop();
        onViewCards();
      },
      onClose: () => Navigator.of(ctx).pop(),
    ),
  );
}
