import 'package:eternal_xi/app/icons/xi_icons.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/app/theme/xi_typography.dart';
import 'package:eternal_xi/shared/widgets/xi_brand_wordmark.dart';
import 'package:eternal_xi/core/constants/api_constants.dart';
import 'package:eternal_xi/features/auth/controller/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;
    final nickname = user?.nickname ?? 'Jugador';
    final nivel = user?.nivel ?? 1;
    final initial = nickname.trim().isEmpty ? '?' : nickname.trim()[0].toUpperCase();
    final photoUrl = (user != null && user.hasProfilePhoto)
        ? ApiConstants.userProfilePhotoUrl(
            user.id,
            cacheBuster: user.foto.hashCode,
          )
        : null;

    return Scaffold(
      backgroundColor: context.xiBackground,
      body: Stack(
        children: [
          // Glow de fondo — esquina superior
          Positioned(
            top: -120,
            left: -60,
            right: -60,
            child: IgnorePointer(
              child: Container(
                height: 380,
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 0.85,
                    colors: [
                      Color(0x282457C5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Barra superior ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 14, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const _BrandMark(),
                      const Spacer(),
                      _ProfileButton(
                        nivel: nivel,
                        initial: initial,
                        photoUrl: photoUrl,
                        onTap: () => context.push(AppRoutes.profile),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // ── Saludo ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BIENVENIDO',
                        style: TextStyle(
                          fontFamily: 'Lumiare',
                          color: XiColors.classicGold,
                          fontSize: 11,
                          letterSpacing: 4.0,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        nickname.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Lumiare',
                          color: context.xiTextPrimary,
                          fontSize: 30,
                          letterSpacing: 1.2,
                          height: 1.05,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      // Línea decorativa cyan
                      Container(
                        height: 2,
                        width: 56,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [XiColors.classicGold, Colors.transparent],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // ── Label sección ───────────────────────────────────
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 22),
                  child: Text(
                    'MODOS DE JUEGO',
                    style: TextStyle(
                      fontFamily: 'Lumiare',
                      color: XiColors.steelGray,
                      fontSize: 10,
                      letterSpacing: 3.5,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ── Tarjetas de modo ─────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _GameModeCard(
                        title: 'MODO FANTASY',
                        subtitle: 'Ligas · Mercado · Alineaciones',
                        iconType: XiIconType.stadium,
                        locked: false,
                        accentColor: XiColors.royalBlue,
                        glowColor: XiColors.royalBlue,
                        onTap: () => context.push(AppRoutes.leagues),
                      ),
                      const SizedBox(height: 12),
                      const _GameModeCard(
                        title: 'MODO CARRERA',
                        subtitle: 'Próximamente disponible',
                        iconType: XiIconType.crest,
                        locked: true,
                        accentColor: XiColors.steelGray,
                        glowColor: XiColors.steelGray,
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // ── Banner próximos modos ─────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: XiColors.divider,
                        width: 0.5,
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          XiColors.royalBlue.withValues(alpha: 0.10),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        const XiIcon(
                          XiIconType.burstStar,
                          size: 18,
                          color: XiColors.classicGold,
                          filled: true,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Más modos de juego en camino',
                            style: TextStyle(
                              fontFamily: 'Lumiare',
                              color: context.xiTextPrimary,
                              fontSize: 12,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Logo marca ────────────────────────────────────────────────────────────────

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [XiColors.royalBlue, XiColors.navyBlue],
            ),
            boxShadow: [
              BoxShadow(
                color: XiColors.royalBlue.withValues(alpha: 0.35),
                blurRadius: 10,
                spreadRadius: -2,
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'XI',
              style: XiTypography.brandWordmark(
                color: XiColors.warmWhite,
                fontSize: 11,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        XiBrandWordmark(
          fontSize: 18,
          color: context.xiTextPrimary,
          letterSpacing: 0.8,
        ),
      ],
    );
  }
}

// ── Botón de perfil ───────────────────────────────────────────────────────────

class _ProfileButton extends StatelessWidget {
  const _ProfileButton({
    required this.nivel,
    required this.initial,
    required this.photoUrl,
    required this.onTap,
  });

  final int nivel;
  final String initial;
  final String? photoUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: XiColors.royalBlue.withValues(alpha: 0.65),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: XiColors.royalBlue.withValues(alpha: 0.25),
                  blurRadius: 8,
                  spreadRadius: -1,
                ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: photoUrl != null
                ? Image.network(
                    photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _AvatarInitial(initial: initial),
                  )
                : _AvatarInitial(initial: initial),
          ),
          Positioned(
            right: -3,
            bottom: -3,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [XiColors.royalBlue, XiColors.navyBlue],
                ),
                border: Border.all(
                  color: XiColors.background,
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '$nivel',
                style: const TextStyle(
                  fontFamily: 'Lumiare',
                  color: XiColors.warmWhite,
                  fontSize: 9,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarInitial extends StatelessWidget {
  const _AvatarInitial({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: XiColors.navyBlue,
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontFamily: 'Lumiare',
            color: XiColors.warmWhite,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}

// ── Tarjeta de modo de juego ──────────────────────────────────────────────────

class _GameModeCard extends StatefulWidget {
  const _GameModeCard({
    required this.title,
    required this.subtitle,
    required this.iconType,
    required this.locked,
    required this.accentColor,
    required this.glowColor,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final XiIconType iconType;
  final bool locked;
  final Color accentColor;
  final Color glowColor;
  final VoidCallback? onTap;

  @override
  State<_GameModeCard> createState() => _GameModeCardState();
}

class _GameModeCardState extends State<_GameModeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.965).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  void _onDown(TapDownDetails _) {
    if (!widget.locked) _pressCtrl.forward();
  }

  void _onUp(TapUpDetails _) {
    if (!widget.locked) {
      _pressCtrl.reverse();
      widget.onTap?.call();
    }
  }

  void _onCancel() {
    if (!widget.locked) _pressCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final dark = context.isXiDark;
    return GestureDetector(
      onTapDown: _onDown,
      onTapUp: _onUp,
      onTapCancel: _onCancel,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: Container(
          height: 148,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: widget.locked
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: dark
                        ? [const Color(0xFF0D1526), const Color(0xFF0A1018)]
                        : [const Color(0xFFE8E4DC), const Color(0xFFDED8CE)],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: dark
                        ? [XiColors.navyBlue, XiColors.surfaceContainer]
                        : [XiColors.warmWhite, const Color(0xFFFFF3DC)],
                  ),
            border: Border.all(
              color: widget.accentColor.withValues(
                alpha: widget.locked ? 0.15 : 0.45,
              ),
              width: widget.locked ? 0.5 : 1.5,
            ),
            boxShadow: widget.locked
                ? []
                : [
                    BoxShadow(
                      color: widget.glowColor.withValues(alpha: 0.14),
                      blurRadius: 24,
                      spreadRadius: -4,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              // Icono gigante decorativo en el fondo
              Positioned(
                right: -22,
                top: -18,
                child: Opacity(
                  opacity: widget.locked ? 0.04 : 0.09,
                  child: XiIcon(
                    widget.iconType,
                    size: 170,
                    color: widget.accentColor,
                  ),
                ),
              ),

              // Barra de acento izquierda
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(22),
                      bottomLeft: Radius.circular(22),
                    ),
                    gradient: widget.locked
                        ? const LinearGradient(
                            colors: [Colors.transparent, Colors.transparent],
                          )
                        : LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [widget.accentColor, widget.glowColor],
                          ),
                  ),
                ),
              ),

              // Contenido
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 18, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.locked) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: XiColors.steelGray.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: XiColors.steelGray.withValues(alpha: 0.25),
                                  width: 0.5,
                                ),
                              ),
                              child: const Text(
                                'BLOQUEADO',
                                style: TextStyle(
                                  fontFamily: 'Lumiare',
                                  color: XiColors.steelGray,
                                  fontSize: 9,
                                  letterSpacing: 2.2,
                                ),
                              ),
                            ),
                          ],
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontFamily: 'Lumiare',
                              color: widget.locked
                                  ? context.xiTextPrimary.withValues(alpha: 0.55)
                                  : context.xiTextPrimary,
                              fontSize: 22,
                              letterSpacing: 0.5,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.subtitle,
                            style: TextStyle(
                              fontFamily: 'Lumiare',
                              color: widget.locked
                                  ? context.xiTextPrimary.withValues(alpha: 0.45)
                                  : context.xiTextPrimary,
                              fontSize: 12,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (!widget.locked)
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.accentColor.withValues(alpha: 0.12),
                          border: Border.all(
                            color: widget.accentColor.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: widget.accentColor,
                          size: 28,
                        ),
                      )
                    else
                      Opacity(
                        opacity: 0.5,
                        child: XiIcon(
                          XiIconType.lock,
                          size: 26,
                          color: XiColors.steelGray,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
