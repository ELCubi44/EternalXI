import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/core/constants/api_constants.dart';
import 'package:eternal_xi/features/auth/controller/auth_controller.dart';
import 'package:eternal_xi/shared/widgets/user_tokens_action.dart';
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
    final initial = _initialLetter(nickname);
    final photoUrl = (user != null && user.hasProfilePhoto)
        ? ApiConstants.userProfilePhotoUrl(
            user.id,
            cacheBuster: user.foto.hashCode,
          )
        : null;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eternal XI'),
        actions: [
          const UserTokensAction(),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _ProfileBarButton(
              nivel: nivel,
              initial: initial,
              photoUrl: photoUrl,
              onTap: () => context.push(AppRoutes.profile),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Modos de juego',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            _ModeCard(
              title: 'Modo Fantasy',
              subtitle: 'Compite en ligas, mercado y alineaciones.',
              icon: Icons.emoji_events_outlined,
              onTap: () => context.push(AppRoutes.leagues),
              locked: false,
            ),
            const SizedBox(height: 12),
            const _ModeCard(
              title: 'Modo Carrera',
              subtitle: 'Bloqueado',
              icon: Icons.lock_outline_rounded,
              locked: true,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.45),
                ),
              ),
              child: Text(
                'Mas modos de juego proximamente',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _initialLetter(String nickname) {
    final t = nickname.trim();
    if (t.isEmpty) {
      return '?';
    }
    return t.substring(0, 1).toUpperCase();
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
    required this.locked,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHigh,
      child: InkWell(
        onTap: locked ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(
                icon,
                color: locked ? colorScheme.onSurfaceVariant : colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (locked)
                Icon(Icons.lock_rounded, color: colorScheme.onSurfaceVariant)
              else
                Icon(Icons.chevron_right_rounded, color: colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileBarButton extends StatelessWidget {
  const _ProfileBarButton({
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Tooltip(
      message: 'Perfil',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _ProfileAvatar(
                    radius: 20,
                    photoUrl: photoUrl,
                    initial: initial,
                    colorScheme: colorScheme,
                    theme: theme,
                  ),
                  Positioned(
                    right: -6,
                    bottom: -4,
                    child: Material(
                      elevation: 2,
                      shape: const CircleBorder(),
                      color: colorScheme.primary,
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: Center(
                          child: Text(
                            '$nivel',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.radius,
    required this.photoUrl,
    required this.initial,
    required this.colorScheme,
    required this.theme,
  });

  final double radius;
  final String? photoUrl;
  final String initial;
  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final fallback = ColoredBox(
      color: colorScheme.primaryContainer,
      child: Center(
        child: Text(
          initial,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: photoUrl == null
            ? fallback
            : Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
  }
}
