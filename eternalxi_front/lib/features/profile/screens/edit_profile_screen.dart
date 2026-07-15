import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/app/theme/xi_typography.dart';
import 'package:eternal_xi/core/constants/api_constants.dart';
import 'package:eternal_xi/features/auth/controller/auth_controller.dart';
import 'package:eternal_xi/core/utils/user_public_tag.dart';
import 'package:eternal_xi/features/profile/controller/account_progress_controller.dart';
import 'package:eternal_xi/features/profile/controller/friends_pending_controller.dart';
import 'package:eternal_xi/features/profile/screens/favorite_player_picker_screen.dart';
import 'package:eternal_xi/data/models/user_public_profile.dart';
import 'package:eternal_xi/data/services/user_api_service.dart';
import 'package:eternal_xi/shared/widgets/pending_notification_badge.dart';
import 'package:eternal_xi/features/profile/controller/profile_controller.dart';
import 'package:eternal_xi/features/profile/widgets/account_level_display.dart';
import 'package:eternal_xi/shared/widgets/app_loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

const Color _kAndroidUcropToolbar = Color(0xFF2C2830);

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  int _photoVersion = DateTime.now().millisecondsSinceEpoch;
  UserPublicProfile? _publicProfile;
  bool _loadingPublicProfile = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  Future<void> _loadProfile() async {
    final auth = context.read<AuthController>();
    final profileController = context.read<ProfileController>();
    final userId = auth.currentUser?.id;
    if (userId == null) {
      return;
    }
    await profileController.loadProfile(userId);
    await context.read<AccountProgressController>().loadProgress(userId);
    await context.read<FriendsPendingController>().refresh(userId);
    await _loadPublicProfile(userId);
    if (!mounted) {
      return;
    }
    setState(() {
      _photoVersion = DateTime.now().millisecondsSinceEpoch;
    });
  }

  Future<void> _loadPublicProfile(int userId) async {
    setState(() => _loadingPublicProfile = true);
    try {
      final profile = await context.read<UserApiService>().getPublicProfile(
        targetUserId: userId,
        viewerUserId: userId,
      );
      if (!mounted) return;
      setState(() {
        _publicProfile = profile;
        _loadingPublicProfile = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingPublicProfile = false);
    }
  }

  Future<void> _openFavoritePlayerPicker(int userId) async {
    final currentId = _publicProfile?.jugadorFavorito?.idJugador;
    final picked = await Navigator.of(context).push<int>(
      MaterialPageRoute<int>(
        builder: (_) => FavoritePlayerPickerScreen(
          userId: userId,
          currentPlayerId: currentId,
        ),
      ),
    );
    if (picked == null || !mounted) return;
    await _loadPublicProfile(userId);
  }

  Future<void> _showPhotoSourcePicker(int userId) async {
    final theme = Theme.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(
                    Icons.photo_camera_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Cámara'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickCropAndUpload(userId, ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.photo_library_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Galería'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickCropAndUpload(userId, ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickCropAndUpload(int userId, ImageSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 92);
      if (picked == null || !mounted) {
        return;
      }
      final cs = Theme.of(context).colorScheme;
      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
        maxWidth: 1024,
        maxHeight: 1024,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Foto de perfil',
            toolbarColor: _kAndroidUcropToolbar,
            toolbarWidgetColor: const Color(0xFFF7F2FA),
            statusBarLight: false,
            navBarLight: false,
            backgroundColor: Colors.black.withValues(alpha: 0.92),
            dimmedLayerColor: Colors.black.withValues(alpha: 0.72),
            cropFrameColor: cs.primary,
            cropGridColor: cs.outline.withValues(alpha: 0.75),
            cropGridColumnCount: 3,
            cropGridRowCount: 3,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            activeControlsWidgetColor: cs.primary,
            hideBottomControls: false,
            cropStyle: CropStyle.circle,
            aspectRatioPresets: const [CropAspectRatioPreset.square],
            showCropGrid: true,
          ),
          IOSUiSettings(
            title: 'Foto de perfil',
            embedInNavigationController: true,
            hidesNavigationBar: false,
            aspectRatioLockEnabled: true,
            aspectRatioPickerButtonHidden: true,
            resetAspectRatioEnabled: false,
            cropStyle: CropStyle.circle,
            aspectRatioPresets: const [CropAspectRatioPreset.square],
            doneButtonTitle: 'Hecho',
            cancelButtonTitle: 'Cancelar',
          ),
        ],
      );
      if (cropped == null || !mounted) {
        return;
      }
      final profile = context.read<ProfileController>();
      final auth = context.read<AuthController>();
      final ok = await profile.uploadProfilePhoto(
        id: userId,
        filePath: cropped.path,
      );
      if (!mounted) {
        return;
      }
      if (ok) {
        auth.setCurrentUser(profile.user);
        setState(() {
          _photoVersion = DateTime.now().millisecondsSinceEpoch;
        });
        messenger.showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              profile.successMessage ?? 'Foto de perfil actualizada',
            ),
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: colorScheme.error,
            content: Text(profile.errorMessage ?? 'No se pudo subir la foto'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: colorScheme.error,
          content: const Text('Error al procesar la imagen. Inténtalo de nuevo.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final colorScheme = theme.colorScheme;
    final profile = context.watch<ProfileController>();
    final progressCtrl = context.watch<AccountProgressController>();
    final progress = progressCtrl.progress;
    final auth = context.watch<AuthController>();
    final pending = context.watch<FriendsPendingController>().incomingCount;
    final user = profile.user ?? auth.currentUser;
    final userId = auth.currentUser?.id;
    final initial = _initials(user?.nickname);

    return AppLoadingOverlay(
      isLoading: profile.isLoading,
      child: Scaffold(
        backgroundColor: context.xiBackground,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: context.xiBackground,
              foregroundColor: context.xiTextPrimary,
              title: Text(l10n.profile),
              expandedHeight: 236,
              flexibleSpace: FlexibleSpaceBar(
                background: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: context.xiHeaderGradient,
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 28, 12, 0),
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              PendingNotificationBadge(
                                count: pending,
                                child: AccountLevelAvatarRing(
                                  nivel: progress?.nivel ?? user?.nivel ?? 1,
                                  xpEnNivel: progress?.xpEnNivel ?? 0,
                                  xpParaSiguiente:
                                      progress?.xpParaSiguienteNivel ?? 100,
                                  ringStroke: 3,
                                  ringGap: 2.5,
                                  child: _ProfileAvatar(
                                    userId: userId,
                                    hasPhoto: user?.hasProfilePhoto ?? false,
                                    photoVersion: _photoVersion,
                                    initial: initial,
                                    colorScheme: colorScheme,
                                    theme: theme,
                                    onEditTap: userId == null
                                        ? null
                                        : () => _showPhotoSourcePicker(userId),
                                    size: 84,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              XiText(
                                user?.nickname ?? 'Jugador',
                                style: XiTypography.lumiare(
                                  fontSize: 22,
                                  letterSpacing: 0.4,
                                  color: context.xiTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (userId != null)
                                XiText(
                                  UserPublicTag.format(userId),
                                  style: XiTypography.lumiare(
                                    fontSize: 13,
                                    color: XiColors.classicGold,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              XiText(
                                '${progress?.rango ?? 'Novato'} · ${progress?.xpEnNivel ?? 0}/${progress?.xpParaSiguienteNivel ?? 100} XP',
                                style: XiTypography.lumiare(
                                  fontSize: 13,
                                  color: context.xiTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],
                          ),
                          Positioned(
                            right: 8,
                            bottom: 14,
                            child: _FavoritePlayerSlot(
                              loading: _loadingPublicProfile,
                              favorite: _publicProfile?.jugadorFavorito,
                              onTap: userId == null
                                  ? null
                                  : () => _openFavoritePlayerPicker(userId),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: PendingNotificationBadge(
                          count: pending,
                          child: _ProfileActionCard(
                            icon: Icons.people_alt_rounded,
                            label: l10n.friendsTitle,
                            onTap: () => context.push(AppRoutes.profileFriends),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ProfileActionCard(
                          icon: Icons.home_rounded,
                          label: l10n.profileBackToTitle,
                          onTap: () => context.go(AppRoutes.splash),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l10n.accountData,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: context.xiTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ReadOnlyInfoTile(
                    label: l10n.email,
                    value: user?.correo ?? '—',
                    icon: Icons.alternate_email_rounded,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: userId == null
                          ? null
                          : () => context.push(AppRoutes.changeEmailRequest),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: Text(l10n.changeEmail),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ReadOnlyInfoTile(
                    label: l10n.nickname,
                    value: user?.nickname ?? '—',
                    icon: Icons.person_rounded,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: userId == null
                          ? null
                          : () => context.push(AppRoutes.changeNicknameRequest),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: Text(l10n.changeNickname),
                    ),
                  ),
                  const SizedBox(height: 28),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await auth.logout();
                      if (context.mounted) {
                        context.go(AppRoutes.splash);
                      }
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: Text(l10n.logout),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String? nickname) {
    final n = nickname?.trim();
    if (n == null || n.isEmpty) {
      return '?';
    }
    return n.substring(0, 1).toUpperCase();
  }
}

class _ProfileActionCard extends StatelessWidget {
  const _ProfileActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.xiCardSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.xiDivider),
          ),
          child: Column(
            children: [
              Icon(icon, color: XiColors.royalBlue, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Lumiare',
                  fontSize: 11,
                  color: context.xiTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyInfoTile extends StatelessWidget {
  const _ReadOnlyInfoTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cleanValue = value.trim().isEmpty ? '—' : value.trim();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cleanValue,
                    style: theme.textTheme.titleSmall?.copyWith(
                      ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.userId,
    required this.hasPhoto,
    required this.photoVersion,
    required this.initial,
    required this.colorScheme,
    required this.theme,
    required this.onEditTap,
    this.size = 88,
  });

  final int? userId;
  final bool hasPhoto;
  final int photoVersion;
  final String initial;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final VoidCallback? onEditTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final imageUrl = (userId != null && hasPhoto)
        ? ApiConstants.userProfilePhotoUrl(userId!, cacheBuster: photoVersion)
        : null;

    return SizedBox(
      width: size + 8,
      height: size + 8,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipOval(
              child: SizedBox(
                width: size,
                height: size,
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) {
                            return child;
                          }
                          return ColoredBox(
                            color: colorScheme.surfaceContainerHigh,
                            child: Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            _AvatarPlaceholder(
                              initial: initial,
                              colorScheme: colorScheme,
                              theme: theme,
                            ),
                      )
                    : _AvatarPlaceholder(
                        initial: initial,
                        colorScheme: colorScheme,
                        theme: theme,
                      ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Material(
              elevation: 4,
              shape: const CircleBorder(),
              color: colorScheme.primary,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onEditTap,
                child: SizedBox(
                  width: 34,
                  height: 34,
                  child: Icon(
                    Icons.edit_rounded,
                    size: 18,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder({
    required this.initial,
    required this.colorScheme,
    required this.theme,
  });

  final String initial;
  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primaryContainer, colorScheme.tertiaryContainer],
        ),
      ),
      child: Center(
        child: initial == '?'
            ? Icon(
                Icons.person_rounded,
                size: 44,
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.88),
              )
            : Text(
                initial,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
      ),
    );
  }
}

class _FavoritePlayerSlot extends StatelessWidget {
  const _FavoritePlayerSlot({
    required this.loading,
    required this.favorite,
    required this.onTap,
  });

  final bool loading;
  final UserPublicFavoritePlayer? favorite;
  final VoidCallback? onTap;

  static const double _size = 52;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = favorite?.photoUrl?.isNotEmpty == true;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_size / 2),
      child: SizedBox(
        height: _size,
        child: Center(
          child: loading
              ? const SizedBox(
                  width: _size,
                  height: _size,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : hasPhoto
              ? ClipOval(
                  child: Image.network(
                    favorite!.photoUrl!,
                    width: _size,
                    height: _size,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _emptySlot(context),
                  ),
                )
              : _emptySlot(context),
        ),
      ),
    );
  }

  Widget _emptySlot(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: context.xiTextSecondary.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
          ),
          Icon(
            Icons.person_rounded,
            size: 34,
            color: context.xiTextSecondary.withValues(alpha: 0.55),
          ),
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: context.xiCardSurface,
              shape: BoxShape.circle,
              border: Border.all(
                color: context.xiTextSecondary.withValues(alpha: 0.35),
              ),
            ),
            child: Icon(
              Icons.add_rounded,
              size: 16,
              color: context.xiTextSecondary.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}
