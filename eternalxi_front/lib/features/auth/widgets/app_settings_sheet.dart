import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/app/theme/xi_typography.dart';
import 'package:eternal_xi/data/models/user_preferences_response.dart';
import 'package:eternal_xi/features/auth/controller/auth_controller.dart';
import 'package:eternal_xi/features/auth/widgets/oauth_social_button.dart';
import 'package:eternal_xi/features/legal/screens/legal_document_screen.dart';
import 'package:eternal_xi/features/profile/controller/user_preferences_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Ajustes globales: idioma, tema, cuentas vinculadas y legales.
class AppSettingsSheet extends StatefulWidget {
  const AppSettingsSheet({super.key});

  static Future<void> show(BuildContext context) async {
    await context.read<UserPreferencesController>().loadAll();
    final auth = context.read<AuthController>();
    if (auth.currentUser != null) {
      await auth.loadOAuthProviders();
    }
    if (!context.mounted) return;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AppSettingsSheet(),
    );
  }

  @override
  State<AppSettingsSheet> createState() => _AppSettingsSheetState();
}

class _AppSettingsSheetState extends State<AppSettingsSheet> {
  bool _linkingGoogle = false;
  bool _linkingApple = false;

  Future<void> _linkGoogle() async {
    if (_linkingGoogle) return;
    setState(() => _linkingGoogle = true);
    final auth = context.read<AuthController>();
    final l10n = context.l10n;
    final ok = await auth.linkGoogleAccount();
    if (!mounted) return;
    setState(() => _linkingGoogle = false);
    final messenger = ScaffoldMessenger.of(context);
    if (ok) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.oauthLinkedGoogle)),
      );
    } else if (auth.errorMessage != null) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text(auth.errorMessage!),
        ),
      );
    }
  }

  Future<void> _linkApple() async {
    if (_linkingApple) return;
    setState(() => _linkingApple = true);
    final auth = context.read<AuthController>();
    final l10n = context.l10n;
    final ok = await auth.linkAppleAccount();
    if (!mounted) return;
    setState(() => _linkingApple = false);
    final messenger = ScaffoldMessenger.of(context);
    if (ok) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.oauthLinkedApple)),
      );
    } else if (auth.errorMessage != null) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text(auth.errorMessage!),
        ),
      );
    }
  }

  Future<void> _logout() async {
    final auth = context.read<AuthController>();
    await auth.logout();
    if (!mounted) return;
    Navigator.pop(context);
    context.go(AppRoutes.splash);
  }

  Future<void> _confirmDeleteAccount() async {
    final l10n = context.l10n;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAccountConfirmTitle),
        content: Text(l10n.deleteAccountConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.deleteAccountRequestEmail),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) {
      return;
    }

    final auth = context.read<AuthController>();
    final message = await auth.requestAccountDeletion();
    if (!mounted) {
      return;
    }

    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      Navigator.pop(context);
      context.push(AppRoutes.deleteAccountConfirm);
      return;
    }

    final error = auth.errorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? l10n.accountDeletionRequestFailed),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final prefs = context.watch<UserPreferencesController>();
    final auth = context.watch<AuthController>();
    final session = auth.currentUser != null;
    final providers = auth.oauthProviders;
    final isDark = prefs.uiThemeSelection == UserThemePreference.dark;

    final sheetBg = isDark ? XiColors.surfaceElevated : XiColors.warmWhite;
    final textPrimary = isDark ? XiColors.warmWhite : XiColors.nightBlue;
    final textSecondary = isDark
        ? XiColors.warmWhite.withValues(alpha: 0.72)
        : XiColors.steelGray;
    final divider = isDark ? XiColors.divider : const Color(0xFFD8CEBC);
    final insetBg = isDark ? const Color(0xFF0D1525) : const Color(0xFFEDE4D0);

    return Material(
      color: sheetBg,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            24,
            20,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: XiText(
                      l10n.splashSettingsTitle,
                      style: XiTypography.lumiare(
                        fontSize: 20,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    tooltip: l10n.close,
                    icon: Icon(Icons.close_rounded, color: textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SectionLabel(text: l10n.languageLabel, color: textPrimary),
              const SizedBox(height: 8),
              SegmentedButton<UserLanguagePreference>(
                style: SegmentedButton.styleFrom(
                  backgroundColor: insetBg,
                  selectedBackgroundColor: XiColors.royalBlue,
                  selectedForegroundColor: Colors.white,
                  foregroundColor: textPrimary,
                ),
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
                selected: {prefs.uiLanguageSelection},
                onSelectionChanged: prefs.isSaving
                    ? null
                    : (value) => _saveLanguage(context, value.first),
              ),
              const SizedBox(height: 18),
              _SectionLabel(text: l10n.themeModeLabel, color: textPrimary),
              const SizedBox(height: 8),
              SegmentedButton<UserThemePreference>(
                style: SegmentedButton.styleFrom(
                  backgroundColor: insetBg,
                  selectedBackgroundColor: XiColors.royalBlue,
                  selectedForegroundColor: Colors.white,
                  foregroundColor: textPrimary,
                ),
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
                selected: {prefs.uiThemeSelection},
                onSelectionChanged: prefs.isSaving
                    ? null
                    : (value) => _saveTheme(context, value.first),
              ),
              if (prefs.isSaving) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.savingPreferences,
                      style: TextStyle(
                        fontFamily: 'Lumiare',
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
              if (session) ...[
                const SizedBox(height: 22),
                _SectionLabel(
                  text: l10n.oauthLinkSectionTitle,
                  color: textPrimary,
                ),
                const SizedBox(height: 10),
                if (auth.isLoadingOAuthProviders)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else ...[
                  OAuthLinkButton(
                    variant: OAuthSocialVariant.google,
                    label: l10n.oauthLinkGoogle,
                    linkedLabel: l10n.oauthLinkedGoogle,
                    linked: providers?.google == true,
                    isLoading: _linkingGoogle || auth.isLoading,
                    onPressed: providers?.google == true ? null : _linkGoogle,
                  ),
                  if (Theme.of(context).platform == TargetPlatform.iOS ||
                      defaultTargetPlatform == TargetPlatform.iOS ||
                      defaultTargetPlatform == TargetPlatform.macOS) ...[
                    const SizedBox(height: 8),
                    OAuthLinkButton(
                      variant: OAuthSocialVariant.apple,
                      label: l10n.oauthLinkApple,
                      linkedLabel: l10n.oauthLinkedApple,
                      linked: providers?.apple == true,
                      isLoading: _linkingApple || auth.isLoading,
                      onPressed: providers?.apple == true ? null : _linkApple,
                    ),
                  ],
                ],
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: auth.isLoading ? null : _logout,
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(l10n.logout),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: auth.isLoading ? null : _confirmDeleteAccount,
                  icon: Icon(
                    Icons.delete_forever_rounded,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  label: Text(
                    l10n.deleteAccount,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              _SectionLabel(text: l10n.legalSectionTitle, color: textPrimary),
              const SizedBox(height: 4),
              _SettingsTile(
                title: l10n.legalHubTitle,
                color: textPrimary,
                chevronColor: textSecondary,
                onTap: () {
                  Navigator.pop(context);
                  context.push(AppRoutes.legalHub);
                },
              ),
              _SettingsTile(
                title: l10n.legalTermsLink,
                color: textPrimary,
                chevronColor: textSecondary,
                onTap: () => _openDoc(context, LegalDocumentType.terms),
              ),
              _SettingsTile(
                title: l10n.legalPrivacyLink,
                color: textPrimary,
                chevronColor: textSecondary,
                onTap: () =>
                    _openDoc(context, LegalDocumentType.privacySummary),
              ),
              _SettingsTile(
                title: l10n.legalCommunityLink,
                color: textPrimary,
                chevronColor: textSecondary,
                onTap: () => _openDoc(
                  context,
                  LegalDocumentType.communityGuidelines,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveTheme(
    BuildContext context,
    UserThemePreference theme,
  ) async {
    final prefs = context.read<UserPreferencesController>();
    if (theme == prefs.storedThemePreference) return;
    await prefs.updateTheme(theme);
  }

  Future<void> _saveLanguage(
    BuildContext context,
    UserLanguagePreference language,
  ) async {
    final prefs = context.read<UserPreferencesController>();
    if (language == prefs.storedLanguagePreference) return;
    await prefs.updateLanguage(language);
  }

  void _openDoc(BuildContext context, LegalDocumentType type) {
    Navigator.pop(context);
    context.push(AppRoutes.legalDocument(type.name));
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Lumiare',
        fontSize: 13,
        color: color,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.title,
    required this.onTap,
    required this.color,
    required this.chevronColor,
  });

  final String title;
  final VoidCallback onTap;
  final Color color;
  final Color chevronColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Lumiare',
          color: color,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: chevronColor),
      onTap: onTap,
    );
  }
}
