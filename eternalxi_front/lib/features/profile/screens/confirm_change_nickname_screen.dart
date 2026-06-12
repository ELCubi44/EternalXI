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

class ConfirmChangeNicknameScreen extends StatefulWidget {
  const ConfirmChangeNicknameScreen({super.key, this.prefilledNickname});

  final String? prefilledNickname;

  @override
  State<ConfirmChangeNicknameScreen> createState() =>
      _ConfirmChangeNicknameScreenState();
}

class _ConfirmChangeNicknameScreenState
    extends State<ConfirmChangeNicknameScreen> {
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
    final nuevoNickname = widget.prefilledNickname?.trim() ?? '';
    final correo = (auth.currentUser?.correo ?? '').trim();

    return AppLoadingOverlay(
      isLoading: auth.isLoading,
      child: Scaffold(
        backgroundColor: context.xiBackground,
        body: AccountFormShell(
          title: l10n.confirmNicknameChange,
          hint: l10n.verificationCodeSentToEmail,
          currentValueLabel: l10n.newNickname,
          currentValue: nuevoNickname.isEmpty ? null : nuevoNickname,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (correo.isNotEmpty) ...[
                  Text(
                    l10n.email,
                    style: TextStyle(
                      fontFamily: 'Lumiare',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
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
                      correo,
                      style: TextStyle(
                        fontFamily: 'Lumiare',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.xiTextPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
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
                    if (userId == null || userId <= 0 || nuevoNickname.isEmpty) {
                      return;
                    }
                    final result = await auth.confirmNicknameChange(
                      idUsuario: userId,
                      nuevoNickname: nuevoNickname,
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
