import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/features/auth/controller/auth_controller.dart';
import 'package:eternal_xi/shared/widgets/app_loading_overlay.dart';
import 'package:eternal_xi/shared/widgets/app_primary_button.dart';
import 'package:eternal_xi/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ConfirmAccountDeletionScreen extends StatefulWidget {
  const ConfirmAccountDeletionScreen({super.key});

  @override
  State<ConfirmAccountDeletionScreen> createState() =>
      _ConfirmAccountDeletionScreenState();
}

class _ConfirmAccountDeletionScreenState
    extends State<ConfirmAccountDeletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = context.watch<AuthController>();
    final theme = Theme.of(context);
    final correo = (auth.currentUser?.correo ?? '').trim();

    return AppLoadingOverlay(
      isLoading: auth.isLoading,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.confirmAccountDeletionTitle)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.confirmAccountDeletionHint,
                  style: theme.textTheme.bodyMedium,
                ),
                if (correo.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    correo,
                    style: theme.textTheme.titleMedium?.copyWith(
                      ),
                  ),
                ],
                const SizedBox(height: 20),
                AppTextField(
                  controller: _codigoController,
                  label: l10n.accountDeletionCodeLabel,
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) {
                    final code = value?.trim() ?? '';
                    if (code.length < 4) {
                      return l10n.accountDeletionCodeInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                AppPrimaryButton(
                  label: l10n.confirmAccountDeletionAction,
                  onPressed: () async {
                    if (!(_formKey.currentState?.validate() ?? false)) {
                      return;
                    }
                    final message = await auth.confirmAccountDeletion(
                      codigo: _codigoController.text.trim(),
                    );
                    if (!context.mounted) {
                      return;
                    }
                    if (message != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.accountDeletedSuccess)),
                      );
                      context.go(AppRoutes.login);
                      return;
                    }
                    final error = auth.errorMessage;
                    if (error != null && error.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error)),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
