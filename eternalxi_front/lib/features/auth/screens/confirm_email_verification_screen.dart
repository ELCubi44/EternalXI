import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/core/utils/validators.dart';
import 'package:eternal_xi/features/auth/controller/auth_controller.dart';
import 'package:eternal_xi/features/auth/widgets/auth_shell.dart';
import 'package:eternal_xi/shared/widgets/app_loading_overlay.dart';
import 'package:eternal_xi/shared/widgets/app_primary_button.dart';
import 'package:eternal_xi/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ConfirmEmailVerificationScreen extends StatefulWidget {
  const ConfirmEmailVerificationScreen({super.key, this.prefilledCorreo});
  final String? prefilledCorreo;

  @override
  State<ConfirmEmailVerificationScreen> createState() =>
      _ConfirmEmailVerificationScreenState();
}

class _ConfirmEmailVerificationScreenState
    extends State<ConfirmEmailVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _correoController;
  final _codigoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _correoController = TextEditingController(
      text: widget.prefilledCorreo ?? '',
    );
  }

  @override
  void dispose() {
    _correoController.dispose();
    _codigoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = context.watch<AuthController>();
    final colorScheme = Theme.of(context).colorScheme;

    return AppLoadingOverlay(
      isLoading: auth.isLoading,
      child: Scaffold(
        body: AuthShell(
          title: l10n.confirmCodeTitle,
          subtitle: l10n.confirmCodeSubtitle,
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
            style: IconButton.styleFrom(foregroundColor: colorScheme.onSurface),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _correoController,
                  label: l10n.email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (value) => Validators.email(value, l10n),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _codigoController,
                  label: l10n.verificationCode,
                  textInputAction: TextInputAction.done,
                  validator: (value) => Validators.verificationCode(value, l10n),
                ),
                const SizedBox(height: 22),
                AppPrimaryButton(
                  label: l10n.confirmAndContinue,
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) {
                      return;
                    }
                    final correo = _correoController.text.trim();
                    final message = await auth.confirmEmailVerification(
                      correo: correo,
                      codigo: _codigoController.text.trim(),
                    );
                    if (!context.mounted) {
                      return;
                    }
                    if (message != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text(message),
                        ),
                      );
                      final encoded = Uri.encodeQueryComponent(correo);
                      context.go('${AppRoutes.register}?correo=$encoded');
                    } else {
                      _showError(auth.errorMessage);
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

  void _showError(String? message) {
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(message ?? l10n.verifyEmailInvalidCode),
      ),
    );
  }
}
