import 'dart:math' as math;

import 'package:eternal_xi/app/localization/rewards_l10n.dart';
import 'package:eternal_xi/features/rewards/data/models/reward_pack_open_result.dart';
import 'package:eternal_xi/features/rewards/data/models/reward_card_model.dart';
import 'package:eternal_xi/features/rewards/presentation/widgets/rarity_badge.dart';
import 'package:eternal_xi/features/rewards/utils/reward_formatters.dart';
import 'package:eternal_xi/features/rewards/utils/reward_rarity_style.dart';
import 'package:flutter/material.dart';

enum _PackPhase { intro, opening, money, card }

/// Diálogo a pantalla completa con fases de apertura de sobre (solo Flutter).
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

class _PackOpeningAnimationDialogState extends State<PackOpeningAnimationDialog>
    with TickerProviderStateMixin {
  _PackPhase _phase = _PackPhase.intro;
  late final AnimationController _pulse;
  int _moneyDisplay = 0;
  bool _cardFlipped = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _run();
  }

  Future<void> _run() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) {
      return;
    }
    setState(() => _phase = _PackPhase.intro);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) {
      return;
    }
    setState(() => _phase = _PackPhase.opening);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) {
      return;
    }
    setState(() => _phase = _PackPhase.money);
    final target = widget.result.dineroGanado;
    const steps = 14;
    for (var i = 1; i <= steps; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 65));
      if (!mounted) {
        return;
      }
      setState(() {
        _moneyDisplay = ((target * i) / steps).round();
      });
    }
    setState(() => _moneyDisplay = target);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) {
      return;
    }
    setState(() {
      _phase = _PackPhase.card;
      _cardFlipped = false;
    });
    await Future<void>.delayed(const Duration(milliseconds: 750));
    if (!mounted) {
      return;
    }
    setState(() => _cardFlipped = true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  bool get _epic {
    final r = widget.result.cartaObtenida.rareza.toUpperCase();
    return r == 'LEGENDARY' || r == 'SUPER_RARE';
  }

  @override
  Widget build(BuildContext context) {
    final rl10n = context.rewardsL10n;
    final card = widget.result.cartaObtenida;
    final style = styleForRarity(card.rareza);
    return Dialog.fullscreen(
      backgroundColor: const Color(0xFF05060A),
      child: Stack(
        children: [
          if (_epic)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _SparklePainter(
                      seed: card.idCarta,
                      pulse: _pulse.value,
                    ),
                  );
                },
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close_rounded, color: Colors.white54),
                    ),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 420),
                      child: _buildPhase(style, card, rl10n),
                    ),
                  ),
                  if (_phase == _PackPhase.card && _cardFlipped) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.onViewCards,
                            child: Text(rl10n.viewMyCards),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: widget.onClose,
                            child: Text(rl10n.close),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhase(RewardRarityStyle style, RewardCardModel card, RewardsL10n rl10n) {
    switch (_phase) {
      case _PackPhase.intro:
      case _PackPhase.opening:
        return _PackEnvelope(phase: _phase, epic: _epic, rl10n: rl10n);
      case _PackPhase.money:
        return Column(
          key: const ValueKey('money'),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '+${formatRewardMoney(_moneyDisplay)}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: const Color(0xFFFFD54F),
                fontWeight: FontWeight.w900,
                shadows: const [
                  Shadow(color: Color(0x88FFCA28), blurRadius: 24),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              rl10n.openingPack,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        );
      case _PackPhase.card:
        return Column(
          key: const ValueKey('card'),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _FlipCardY(
              key: ValueKey(_cardFlipped),
              flipped: _cardFlipped,
              front: _cardFace(style, card, revealed: false, rl10n: rl10n),
              back: _cardFace(style, card, revealed: true, rl10n: rl10n),
            ),
          ],
        );
    }
  }

  Widget _cardFace(
    RewardRarityStyle style,
    RewardCardModel card, {
    required bool revealed,
    required RewardsL10n rl10n,
  }) {
    final effectLabel = rl10n.tipoEfectoLabel(card.tipoEfecto);
    final displayName = rl10n.cardDisplayName(card).trim();
    final cardTitle = displayName.isNotEmpty ? displayName : card.codigo;
    return Container(
      width: 260,
      height: 360,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: revealed
              ? style.gradient
              : const [Color(0xFF263238), Color(0xFF102027)],
        ),
        border: Border.all(
          color: revealed ? style.border : Colors.white24,
          width: revealed ? 2.2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (revealed ? style.glow : Colors.black).withValues(
              alpha: revealed ? 0.55 : 0.5,
            ),
            blurRadius: revealed ? rarityGlowSigma(card.rareza) : 16,
          ),
        ],
      ),
      child: revealed
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RarityBadge(rarity: card.rareza),
                  const SizedBox(height: 12),
                  Text(
                    cardTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (effectLabel.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Chip(
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        label: Text(
                          effectLabel,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  if (effectLabel.isNotEmpty)
                    const SizedBox(height: 8),
                  Expanded(
                    child: Text(
                      rl10n.cardDisplayDescription(card),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Center(
              child: Icon(
                Icons.style_rounded,
                size: 72,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
    );
  }
}

class _PackEnvelope extends StatelessWidget {
  const _PackEnvelope({
    required this.phase,
    required this.epic,
    required this.rl10n,
  });

  final _PackPhase phase;
  final bool epic;
  final RewardsL10n rl10n;

  @override
  Widget build(BuildContext context) {
    final open = phase == _PackPhase.opening;
    return Column(
      key: ValueKey(phase),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.85, end: 1),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: SizedBox(
            width: 200,
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2837),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                    boxShadow: [
                      BoxShadow(
                        color: epic
                            ? const Color(0x66FFD54F)
                            : Colors.black.withValues(alpha: 0.45),
                        blurRadius: epic ? 28 : 14,
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: AnimatedRotation(
                    turns: open ? -0.12 : 0,
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    child: Container(
                      width: 200,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C3B52),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(11),
                        ),
                        border: Border.all(color: Colors.white24),
                      ),
                    ),
                  ),
                ),
                Text(
                  open ? '…' : rl10n.openingPack,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FlipCardY extends StatelessWidget {
  const _FlipCardY({
    super.key,
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
      duration: const Duration(milliseconds: 720),
      curve: Curves.easeInOutCubic,
      builder: (context, angle, _) {
        final showBack = angle > math.pi / 2;
        if (showBack) {
          final m = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle - math.pi);
          return Transform(
            alignment: Alignment.center,
            transform: m,
            child: back,
          );
        }
        final m = Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(angle);
        return Transform(
          alignment: Alignment.center,
          transform: m,
          child: front,
        );
      },
    );
  }
}

class _SparklePainter extends CustomPainter {
  _SparklePainter({required this.seed, required this.pulse});

  final int seed;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed);
    final paint = Paint()..color = const Color(0x55FFD54F);
    for (var i = 0; i < 36; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final r = 1.2 + rnd.nextDouble() * 2.2 + pulse * 1.5;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) =>
      oldDelegate.pulse != pulse;
}

Future<void> showPackOpeningAnimationDialog({
  required BuildContext context,
  required RewardPackOpenResult result,
  required VoidCallback onViewCards,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return PackOpeningAnimationDialog(
        result: result,
        onViewCards: () {
          Navigator.of(ctx).pop();
          onViewCards();
        },
        onClose: () => Navigator.of(ctx).pop(),
      );
    },
  );
}
