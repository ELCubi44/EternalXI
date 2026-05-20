import 'dart:math' as math;

import 'package:eternal_xi/core/utils/league_coach_photo.dart';
import 'package:eternal_xi/core/utils/league_asset_urls.dart';
import 'package:eternal_xi/features/rewards/data/models/reward_coach_item.dart';
import 'package:flutter/material.dart';

/// Cinta horizontal estilo CS: el backend ya fijó el ganador; solo animamos scroll.
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

class _CoachRouletteStripState extends State<CoachRouletteStrip> {
  final ScrollController _sc = ScrollController();
  static const double _itemW = 108;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_started || !mounted) {
        return;
      }
      _started = true;
      _runAnimation();
    });
  }

  List<RewardCoachItem> get _base {
    if (widget.itemsRuleta.isNotEmpty) {
      return widget.itemsRuleta;
    }
    return List<RewardCoachItem>.filled(6, widget.entrenadorGanador);
  }

  List<RewardCoachItem> _buildStrip() {
    final base = _base;
    final out = <RewardCoachItem>[];
    for (var i = 0; i < 48; i++) {
      out.add(base[i % base.length]);
    }
    const winSlot = 36;
    if (winSlot < out.length) {
      out[winSlot] = widget.entrenadorGanador;
    }
    return out;
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  Future<void> _runAnimation() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted || !_sc.hasClients) {
      widget.onFinished();
      return;
    }
    const winSlot = 36;
    final target = (winSlot * _itemW).clamp(0.0, _sc.position.maxScrollExtent);
    final jitter = math.Random(widget.entrenadorGanador.idEntrenador).nextDouble() * 0.4;
    final ms = (4500 + jitter * 1000).round();
    try {
      await _sc.animateTo(
        target,
        duration: Duration(milliseconds: ms),
        curve: Curves.easeOutQuart,
      );
    } catch (_) {}
    if (mounted) {
      widget.onFinished();
    }
  }

  @override
  Widget build(BuildContext context) {
    final strip = _buildStrip();
    return LayoutBuilder(
      builder: (context, c) {
        final vw = c.maxWidth;
        final pad = vw / 2 - _itemW / 2;
        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            height: 148,
            decoration: BoxDecoration(
              color: const Color(0xFF0D1018),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Stack(
              children: [
                ListView.builder(
                  controller: _sc,
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: pad),
                  itemExtent: _itemW,
                  itemCount: strip.length,
                  itemBuilder: (_, i) {
                    return _CoachMiniCard(coach: strip[i]);
                  },
                ),
                Positioned(
                  left: vw / 2 - 1.5,
                  top: 8,
                  bottom: 8,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFFFD54F),
                          Color(0xFFFF6F00),
                        ],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x88FFD54F),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CoachMiniCard extends StatelessWidget {
  const _CoachMiniCard({required this.coach});

  final RewardCoachItem coach;

  static const double _avatarR = 22;

  @override
  Widget build(BuildContext context) {
    final photoUrl = LeagueCoachPhoto.resolveUrl(
      idEntrenador: coach.idEntrenador,
      foto: coach.foto,
    );
    final hasTeamId = coach.idEquipo != null && coach.idEquipo! > 0;
    final teamUrl = hasTeamId
        ? LeagueAssetUrls.teamBadge(coach.idEquipo!).toString()
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: const Color(0xFF1A2233),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
                  right: -4,
                  bottom: -2,
                  child: _RouletteTeamBadge(teamUrl: teamUrl),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              coach.pila.trim().isNotEmpty ? coach.pila : coach.nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              (coach.nombreEquipo ?? '').trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white54,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
        color: const Color(0xFF263238),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontSize: 15,
          ),
        ),
      );
    }

    if (trimmed.isEmpty) {
      return ClipOval(child: placeholder());
    }

    return ClipOval(
      child: SizedBox(
        width: d,
        height: d,
        child: Image.network(
          trimmed,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => placeholder(),
          loadingBuilder: (context, child, progress) {
            if (progress == null) {
              return child;
            }
            return Container(
              width: d,
              height: d,
              color: const Color(0xFF1E272E),
              alignment: Alignment.center,
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

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
          size: 12,
          color: Colors.white.withValues(alpha: 0.65),
        ),
      );
    }

    final u = teamUrl?.trim() ?? '';
    if (u.isEmpty) {
      return shield();
    }

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
        errorBuilder: (context, error, stackTrace) => shield(),
      ),
    );
  }
}

Future<void> showCoachRouletteDialog({
  required BuildContext context,
  required List<RewardCoachItem> itemsRuleta,
  required RewardCoachItem entrenadorGanador,
}) async {
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'roulette',
    barrierColor: Colors.black.withValues(alpha: 0.92),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (ctx, animation, secondaryAnimation) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Material(
            color: const Color(0xFF0B0E16),
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ruleta de entrenador',
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  CoachRouletteStrip(
                    itemsRuleta: itemsRuleta,
                    entrenadorGanador: entrenadorGanador,
                    onFinished: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

Future<void> showCoachWonDialog({
  required BuildContext context,
  required RewardCoachItem coach,
}) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('¡Entrenador conseguido!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              coach.displayName,
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if ((coach.nombreEquipo ?? '').trim().isNotEmpty)
              Text('Equipo: ${coach.nombreEquipo}'),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continuar'),
          ),
        ],
      );
    },
  );
}
