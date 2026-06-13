import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:flutter/material.dart';

enum LegalDocumentType { terms, communityGuidelines, privacySummary }

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.type});

  final LegalDocumentType type;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = switch (type) {
      LegalDocumentType.terms => l10n.legalTermsTitle,
      LegalDocumentType.communityGuidelines => l10n.legalCommunityTitle,
      LegalDocumentType.privacySummary => l10n.legalPrivacyTitle,
    };
    final body = switch (type) {
      LegalDocumentType.terms => l10n.legalTermsBody,
      LegalDocumentType.communityGuidelines => l10n.legalCommunityBody,
      LegalDocumentType.privacySummary => l10n.legalPrivacyBody,
    };

    return Scaffold(
      backgroundColor: context.xiBackground,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: context.xiBackground,
        foregroundColor: context.xiTextPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            body,
            style: TextStyle(
              fontFamily: 'Lumiare',
              fontSize: 14,
              height: 1.55,
              color: context.xiTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
