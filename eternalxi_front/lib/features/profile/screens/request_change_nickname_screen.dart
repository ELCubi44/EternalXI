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

class RequestChangeNicknameScreen extends StatefulWidget {
  const RequestChangeNicknameScreen({super.key, this.nicknameActual});

  final String? nicknameActual;

  @override
  State<RequestChangeNicknameScreen> createState() =>
      _RequestChangeNicknameScreenState();
}

class _RequestChangeNicknameScreenState
    extends State<RequestChangeNicknameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nuevoNicknameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nuevoNicknameController.dispose();
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
          title: l10n.changeNickname,
          hint: l10n.changeNicknameHint,
          currentValueLabel: l10n.currentNickname,
          currentValue: widget.nicknameActual,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _nuevoNicknameController,
                  label: l10n.newNickname,
                  textInputAction: TextInputAction.next,
                  validator: (value) => Validators.nickname(value, l10n),
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
                  label: l10n.sendNicknameVerificationCode,
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) {
                      return;
                    }
                    final userId = auth.currentUser?.id;
                    if (userId == null || userId <= 0) {
                      return;
                    }
                    final nuevoNickname = _nuevoNicknameController.text.trim();
                    final message = await auth.requestNicknameChange(
                      idUsuario: userId,
                      contrasenaActual: _passwordController.text,
                      nuevoNickname: nuevoNickname,
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
                      final encoded = Uri.encodeQueryComponent(nuevoNickname);
                      context.push(
                        '${AppRoutes.changeNicknameConfirm}?nickname=$encoded',
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
