import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/auth/controller/auth_controller.dart';
import 'package:eternal_xi/features/auth/widgets/auth_shell.dart';
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
  final _codigoNuevoController = TextEditingController();
  final _codigoActualController = TextEditingController();

  @override
  void dispose() {
    _codigoNuevoController.dispose();
    _codigoActualController.dispose();
    super.dispose();
  }

  String? _codeValidator(String? value, dynamic l10n) {
    final t = value?.trim() ?? '';
    if (t.length < 6) {
      return l10n.validatorCodeSixChars;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = context.watch<AuthController>();
    final theme = Theme.of(context);
    final nuevoCorreo = widget.prefilledCorreo?.trim() ?? '';
    final correoActual = (auth.currentUser?.correo ?? '').trim();

    return AppLoadingOverlay(
      isLoading: auth.isLoading,
      child: Scaffold(
        backgroundColor: context.xiBackground,
        body: AccountFormShell(
          title: l10n.confirmEmailChange,
          hint: l10n.confirmEmailChangeHint,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.currentEmail,
                  style: TextStyle(
                    fontFamily: 'Lumiare',
                    fontSize: 11,
                    color: context.xiAccentText,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: context.xiSurfaceInset.withValues(alpha: 0.55),
                    border: Border.all(color: context.xiBorderSubtle),
                  ),
                  child: Text(
                    correoActual.isEmpty ? '—' : correoActual,
                    style: TextStyle(
                      fontFamily: 'Lumiare',
                      fontSize: 14,
                      color: context.xiTextPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _codigoActualController,
                  label: l10n.verificationCodeCurrentEmail,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.next,
                  validator: (v) => _codeValidator(v, l10n),
                ),
                const SizedBox(height: 18),
                Text(
                  l10n.newEmail,
                  style: TextStyle(
                    fontFamily: 'Lumiare',
                    fontSize: 11,
                    color: context.xiAccentText,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: context.xiSurfaceInset.withValues(alpha: 0.55),
                    border: Border.all(color: context.xiBorderSubtle),
                  ),
                  child: Text(
                    nuevoCorreo.isEmpty ? '—' : nuevoCorreo,
                    style: TextStyle(
                      fontFamily: 'Lumiare',
                      fontSize: 14,
                      color: context.xiTextPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _codigoNuevoController,
                  label: l10n.verificationCodeNewEmail,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  validator: (v) => _codeValidator(v, l10n),
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
                      codigo: _codigoNuevoController.text.trim().toUpperCase(),
                      codigoCorreoActual:
                          _codigoActualController.text.trim().toUpperCase(),
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
