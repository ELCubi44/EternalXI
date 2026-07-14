import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/core/constants/legal_constants.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class LegalHubScreen extends StatelessWidget {
  const LegalHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: context.xiBackground,
      appBar: AppBar(
        title: Text(l10n.legalHubTitle),
        backgroundColor: context.xiBackground,
        foregroundColor: context.xiTextPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.legalHubIntro,
            style: TextStyle(
              fontFamily: 'Lumiare',
              fontSize: 14,
              height: 1.5,
              color: context.xiTextSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _LegalTile(
            title: l10n.legalTermsLink,
            onTap: () => context.push(AppRoutes.legalDocument('terms')),
          ),
          _LegalTile(
            title: l10n.legalPrivacyLink,
            onTap: () =>
                context.push(AppRoutes.legalDocument('privacySummary')),
          ),
          _LegalTile(
            title: l10n.legalCommunityLink,
            onTap: () => context.push(
              AppRoutes.legalDocument('communityGuidelines'),
            ),
          ),
          const Divider(height: 28),
          Text(
            l10n.legalWebSectionTitle,
            style: TextStyle(
              fontFamily: 'Lumiare',
              color: context.xiTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.legalWebSectionNote,
            style: TextStyle(
              fontFamily: 'Lumiare',
              fontSize: 12,
              color: context.xiTextSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 8),
          _LegalTile(
            title: l10n.legalTermsLink,
            subtitle: LegalConstants.termsOfServiceUrl,
            onTap: () => _openUrl(LegalConstants.termsOfServiceUrl),
          ),
          _LegalTile(
            title: l10n.legalPrivacyLink,
            subtitle: LegalConstants.privacyPolicyUrl,
            onTap: () => _openUrl(LegalConstants.privacyPolicyUrl),
          ),
          _LegalTile(
            title: l10n.legalCommunityLink,
            subtitle: LegalConstants.communityGuidelinesUrl,
            onTap: () => _openUrl(LegalConstants.communityGuidelinesUrl),
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _LegalTile extends StatelessWidget {
  const _LegalTile({
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: context.xiCardSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.xiDivider),
      ),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Lumiare',
            color: context.xiTextPrimary,
          ),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle!,
                style: TextStyle(
                  fontFamily: 'Lumiare',
                  fontSize: 11,
                  color: context.xiTextSecondary,
                ),
              ),
        trailing: Icon(
          subtitle == null
              ? Icons.chevron_right_rounded
              : Icons.open_in_new_rounded,
          size: 18,
          color: context.xiTextSecondary,
        ),
        onTap: onTap,
      ),
    );
  }
}
