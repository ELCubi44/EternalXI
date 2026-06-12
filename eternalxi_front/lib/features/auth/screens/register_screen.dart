import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/core/utils/validators.dart';
import 'package:eternal_xi/features/auth/controller/auth_controller.dart';
import 'package:eternal_xi/features/auth/widgets/auth_shell.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/shared/widgets/app_loading_overlay.dart';
import 'package:eternal_xi/shared/widgets/app_primary_button.dart';
import 'package:eternal_xi/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.prefilledCorreo});
  final String? prefilledCorreo;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _correoController;
  final _nicknameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

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
    _nicknameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
        backgroundColor: context.xiBackground,
        body: AuthShell(
          title: l10n.registerTitle,
          subtitle: l10n.registerSubtitle,
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
                  controller: _nicknameController,
                  label: l10n.nickname,
                  textInputAction: TextInputAction.next,
                  validator: (value) => Validators.nickname(value, l10n),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _passwordController,
                  label: l10n.password,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  validator: (value) => Validators.password(value, l10n),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _confirmPasswordController,
                  label: l10n.repeatPassword,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: (v) =>
                      Validators.confirmPassword(v, _passwordController.text, l10n),
                ),
                const SizedBox(height: 22),
                AppPrimaryButton(
                  label: l10n.register,
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) {
                      return;
                    }
                    final message = await auth.register(
                      correo: _correoController.text.trim(),
                      nickname: _nicknameController.text.trim(),
                      contrasena: _passwordController.text,
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
                      final correo = Uri.encodeQueryComponent(
                        _correoController.text.trim(),
                      );
                      context.go('${AppRoutes.login}?correo=$correo');
                    } else {
                      _showError(auth.errorMessage);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go(AppRoutes.login),
                  child: Text(l10n.alreadyHaveAccount),
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
        content: Text(message ?? l10n.apiUnexpectedError),
      ),
    );
  }
}
