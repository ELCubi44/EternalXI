import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/core/constants/api_constants.dart';
import 'package:eternal_xi/data/models/user_preferences_response.dart';
import 'package:eternal_xi/features/auth/controller/auth_controller.dart';
import 'package:eternal_xi/features/profile/controller/account_progress_controller.dart';
import 'package:eternal_xi/features/profile/controller/profile_controller.dart';
import 'package:eternal_xi/features/profile/controller/user_preferences_controller.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  Future<void> _loadProfile() async {
    final auth = context.read<AuthController>();
    final profileController = context.read<ProfileController>();
    final preferencesController = context.read<UserPreferencesController>();
    final userId = auth.currentUser?.id;
    if (userId == null) {
      return;
    }
    await profileController.loadProfile(userId);
    await context.read<AccountProgressController>().loadProgress(userId);
    await preferencesController.loadAll();
    if (!mounted) {
      return;
    }
    setState(() {
      _photoVersion = DateTime.now().millisecondsSinceEpoch;
    });
  }

  Future<void> _saveTheme(UserThemePreference themeMode) async {
    final l10n = context.l10n;
    final controller = context.read<UserPreferencesController>();
    final ok = await controller.updateTheme(themeMode);
    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    if (ok) {
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(l10n.preferencesUpdated),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text(controller.errorMessage ?? l10n.preferencesSaveError),
        ),
      );
    }
  }

  Future<void> _saveLanguage(UserLanguagePreference languageCode) async {
    final l10n = context.l10n;
    final controller = context.read<UserPreferencesController>();
    final ok = await controller.updateLanguage(languageCode);
    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    if (ok) {
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(l10n.preferencesUpdated),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text(controller.errorMessage ?? l10n.preferencesSaveError),
        ),
      );
    }
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
    final preferencesController = context.watch<UserPreferencesController>();
    final auth = context.watch<AuthController>();
    final user = profile.user ?? auth.currentUser;
    final userId = auth.currentUser?.id;
    final initial = _initials(user?.nickname);

    return AppLoadingOverlay(
      isLoading: profile.isLoading,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.profile)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Center(
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
                ),
              ),
              const SizedBox(height: 20),
              Text(
                user?.nickname ?? 'Jugador',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 22),
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.55,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.accountData,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      AccountLevelDisplay(
                        compact: true,
                        nivel: progress?.nivel ?? user?.nivel ?? 1,
                        rango: progress?.rango ?? 'Novato',
                        xpEnNivel: progress?.xpEnNivel ?? 0,
                        xpParaSiguiente: progress?.xpParaSiguienteNivel ?? 100,
                      ),
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 16),
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.55,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.preferencesTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.themeModeLabel,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SegmentedButton<UserThemePreference>(
                        segments: [
                          ButtonSegment(
                            value: UserThemePreference.light,
                            label: Text(l10n.lightOption),
                          ),
                          ButtonSegment(
                            value: UserThemePreference.dark,
                            label: Text(l10n.darkOption),
                          ),
                        ],
                        selected: {preferencesController.uiThemeSelection},
                        emptySelectionAllowed: false,
                        onSelectionChanged: preferencesController.isSaving
                            ? null
                            : (selection) {
                                final value = selection.first;
                                if (value !=
                                    preferencesController
                                        .storedThemePreference) {
                                  _saveTheme(value);
                                }
                              },
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.languageLabel,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SegmentedButton<UserLanguagePreference>(
                        segments: [
                          ButtonSegment(
                            value: UserLanguagePreference.es,
                            label: Text(l10n.spanishOption),
                          ),
                          ButtonSegment(
                            value: UserLanguagePreference.en,
                            label: Text(l10n.englishOption),
                          ),
                        ],
                        selected: {preferencesController.uiLanguageSelection},
                        emptySelectionAllowed: false,
                        onSelectionChanged: preferencesController.isSaving
                            ? null
                            : (selection) {
                                final value = selection.first;
                                if (value !=
                                    preferencesController
                                        .storedLanguagePreference) {
                                  _saveLanguage(value);
                                }
                              },
                      ),
                      if (preferencesController.isSaving) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.savingPreferences,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () async {
                  await auth.logout();
                  if (context.mounted) {
                    context.go(AppRoutes.login);
                  }
                },
                icon: const Icon(Icons.logout_rounded),
                label: Text(l10n.logout),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: userId == null
                    ? null
                    : () => _confirmDelete(context, userId),
                child: Text(
                  l10n.deleteAccount,
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            ],
          ),
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

  Future<void> _confirmDelete(BuildContext context, int id) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteAccountConfirmTitle),
        content: Text(context.l10n.deleteAccountConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(context.l10n.deleteAccountRequestEmail),
          ),
        ],
      ),
    );
    if (accepted != true || !context.mounted) {
      return;
    }
    final auth = context.read<AuthController>();
    final message = await auth.requestAccountDeletion();
    if (!context.mounted) {
      return;
    }
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      context.push(AppRoutes.deleteAccountConfirm);
      return;
    }
    final error = auth.errorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? context.l10n.accountDeletionRequestFailed)),
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
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cleanValue,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
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
  });

  final int? userId;
  final bool hasPhoto;
  final int photoVersion;
  final String initial;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final VoidCallback? onEditTap;

  static const double _size = 88;

  @override
  Widget build(BuildContext context) {
    final imageUrl = (userId != null && hasPhoto)
        ? ApiConstants.userProfilePhotoUrl(userId!, cacheBuster: photoVersion)
        : null;

    return SizedBox(
      width: _size + 8,
      height: _size + 8,
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
                width: _size,
                height: _size,
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
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
