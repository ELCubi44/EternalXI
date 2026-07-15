import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/data/models/eligible_favorite_player.dart';
import 'package:eternal_xi/features/leagues/widgets/league_team_logo.dart';
import 'package:flutter/material.dart';

/// Tarjeta desplegable por equipo (mismo formato que compra directa del mercado).
class FavoritePickerTeamExpandCard extends StatefulWidget {
  const FavoritePickerTeamExpandCard({
    required this.group,
    required this.saving,
    required this.onPick,
    super.key,
  });

  final FavoritePickerTeamGroup group;
  final bool saving;
  final ValueChanged<EligibleFavoritePlayer> onPick;

  @override
  State<FavoritePickerTeamExpandCard> createState() =>
      _FavoritePickerTeamExpandCardState();
}

class _FavoritePickerTeamExpandCardState extends State<FavoritePickerTeamExpandCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _rotCtrl;

  @override
  void initState() {
    super.initState();
    _rotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void dispose() {
    _rotCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _rotCtrl.forward();
    } else {
      _rotCtrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: context.xiCompactCardGradient,
        ),
        border: Border.all(color: context.xiBorderSubtle),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _toggle,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Row(
                  children: [
                    LeagueTeamLogo(
                      idEquipo: widget.group.idEquipo,
                      size: 38,
                      networkImageUrl: widget.group.fotoEquipo,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.group.nombreEquipo,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Lumiare',
                              fontSize: 14,
                              color: context.xiTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.group.players.length} jugadores',
                            style: TextStyle(
                              fontFamily: 'Lumiare',
                              fontSize: 10,
                              color: XiColors.royalBlue.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    RotationTransition(
                      turns: Tween(begin: 0.0, end: 0.5).animate(
                        CurvedAnimation(parent: _rotCtrl, curve: Curves.easeOut),
                      ),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: XiColors.steelGray,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              child: _expanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Column(
                        children: [
                          for (final player in widget.group.players)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _FavoritePickerPlayerRow(
                                player: player,
                                saving: widget.saving,
                                onPick: () => widget.onPick(player),
                              ),
                            ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoritePickerPlayerRow extends StatelessWidget {
  const _FavoritePickerPlayerRow({
    required this.player,
    required this.saving,
    required this.onPick,
  });

  final EligibleFavoritePlayer player;
  final bool saving;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final photo = player.photoUrl;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: context.xiCompactCardGradient,
        ),
        border: Border.all(color: context.xiBorderSubtle),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      child: Row(
        children: [
          ClipOval(
            child: photo != null
                ? Image.network(
                    photo,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _photoFallback(),
                  )
                : _photoFallback(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              player.nombre,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Lumiare',
                fontSize: 14,
                color: context.xiTextPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: saving ? null : onPick,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Elegir'),
          ),
        ],
      ),
    );
  }

  Widget _photoFallback() {
    return ColoredBox(
      color: XiColors.royalBlue.withValues(alpha: 0.12),
      child: const SizedBox(
        width: 48,
        height: 48,
        child: Icon(Icons.person_rounded, color: XiColors.royalBlue),
      ),
    );
  }
}
