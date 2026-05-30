import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/features/auth/controller/auth_controller.dart';
import 'package:eternal_xi/features/profile/controller/profile_controller.dart';
import 'package:eternal_xi/shared/widgets/app_loading_overlay.dart';
import 'package:eternal_xi/shared/widgets/app_primary_button.dart';
import 'package:eternal_xi/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ConfirmChangeEmailScreen extends StatefulWidget {
  const ConfirmChangeEmailScreen({super.key, this.prefilledCorreo});

  final String? prefilledCorreo;

  @override
  State<ConfirmChangeEmailScreen> createState() =>
      _ConfirmChangeEmailScreenState();
}

class _ConfirmChangeEmailScreenState extends State<ConfirmChangeEmailScreen> {
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
    final nuevoCorreo = widget.prefilledCorreo?.trim() ?? '';

    return AppLoadingOverlay(
      isLoading: auth.isLoading,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.confirmEmailChange)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.verificationCodeSentTo,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  nuevoCorreo.isEmpty ? '—' : nuevoCorreo,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _codigoController,
                  label: l10n.verificationCode,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.length < 6) {
                      return l10n.validatorCodeSixChars;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                AppPrimaryButton(
                  label: l10n.confirmChange,
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) {
                      return;
                    }
                    final userId = auth.currentUser?.id;
                    if (userId == null || userId <= 0 || nuevoCorreo.isEmpty) {
                      return;
                    }
                    final result = await auth.confirmEmailChange(
                      idUsuario: userId,
                      nuevoCorreo: nuevoCorreo,
                      codigo: _codigoController.text.trim().toUpperCase(),
                    );
                    if (!context.mounted) {
                      return;
                    }
                    if (result != null) {
                      await context.read<ProfileController>().loadProfile(userId);
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text(result.message),
                        ),
                      );
                      context.go(AppRoutes.profile);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: theme.colorScheme.error,
                          content: Text(
                            auth.errorMessage ?? 'No se pudo confirmar el cambio',
                          ),
                        ),
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
