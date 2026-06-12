import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/core/utils/validators.dart';
import 'package:eternal_xi/features/auth/controller/auth_controller.dart';
import 'package:eternal_xi/features/auth/widgets/auth_shell.dart';
import 'package:eternal_xi/shared/widgets/app_loading_overlay.dart';
import 'package:eternal_xi/shared/widgets/app_primary_button.dart';
import 'package:eternal_xi/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class RequestChangeEmailScreen extends StatefulWidget {
  const RequestChangeEmailScreen({super.key, this.correoActual});

  final String? correoActual;

  @override
  State<RequestChangeEmailScreen> createState() =>
      _RequestChangeEmailScreenState();
}

class _RequestChangeEmailScreenState extends State<RequestChangeEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nuevoCorreoController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nuevoCorreoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = context.watch<AuthController>();
    final theme = Theme.of(context);

    return AppLoadingOverlay(
      isLoading: auth.isLoading,
      child: Scaffold(
        backgroundColor: context.xiBackground,
        body: AccountFormShell(
          title: l10n.changeEmail,
          hint: l10n.changeEmailHint,
          currentValueLabel: l10n.currentEmail,
          currentValue: widget.correoActual,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _nuevoCorreoController,
                  label: l10n.newEmail,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (value) => Validators.email(value, l10n),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _passwordController,
                  label: l10n.currentPassword,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return l10n.validatorCurrentPasswordRequired;
                    }
                    return null;
                  },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    style: TextButton.styleFrom(
                      foregroundColor: context.xiAccentText,
                    ),
                    child: Text(
                      _obscurePassword ? l10n.showPassword : l10n.hidePassword,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                AppPrimaryButton(
                  label: l10n.sendVerificationCodes,
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) {
                      return;
                    }
                    final userId = auth.currentUser?.id;
                    if (userId == null || userId <= 0) {
                      return;
                    }
                    final nuevoCorreo = _nuevoCorreoController.text.trim();
                    final message = await auth.requestEmailChange(
                      idUsuario: userId,
                      contrasenaActual: _passwordController.text,
                      nuevoCorreo: nuevoCorreo,
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
                      final encoded = Uri.encodeQueryComponent(nuevoCorreo);
                      context.push(
                        '${AppRoutes.changeEmailConfirm}?correo=$encoded',
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: theme.colorScheme.error,
                          content: Text(
                            auth.errorMessage ?? 'No se pudo solicitar el cambio',
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
