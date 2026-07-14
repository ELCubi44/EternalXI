import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/core/utils/validators.dart';
import 'package:eternal_xi/features/auth/controller/auth_controller.dart';
import 'package:eternal_xi/features/auth/widgets/auth_shell.dart';
import 'package:eternal_xi/features/auth/widgets/oauth_social_button.dart';
import 'package:eternal_xi/shared/widgets/app_loading_overlay.dart';
import 'package:eternal_xi/shared/widgets/app_primary_button.dart';
import 'package:eternal_xi/shared/widgets/app_text_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.prefilledCorreo});
  final String? prefilledCorreo;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _correoController;
  final _passwordController = TextEditingController();

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
    _passwordController.dispose();
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
          title: l10n.loginTitle,
          subtitle: l10n.loginSubtitle,
          leading: context.canPop()
              ? IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  style: IconButton.styleFrom(
                    foregroundColor: colorScheme.onSurface,
                  ),
                )
              : null,
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
                  controller: _passwordController,
                  label: l10n.password,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: (value) => Validators.password(value, l10n),
                ),
                const SizedBox(height: 22),
                AppPrimaryButton(
                  label: l10n.login,
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) {
                      return;
                    }
                    final ok = await auth.login(
                      correo: _correoController.text.trim(),
                      contrasena: _passwordController.text,
                    );
                    if (!context.mounted) {
                      return;
                    }
                    if (ok) {
                      context.go(AppRoutes.mode);
                    } else {
                      _showError(auth.errorMessage);
                    }
                  },
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(child: Divider(color: colorScheme.outline)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        l10n.oauthDividerLabel,
                        style: TextStyle(color: colorScheme.outline),
                      ),
                    ),
                    Expanded(child: Divider(color: colorScheme.outline)),
                  ],
                ),
                const SizedBox(height: 18),
                OAuthLoginBubbles(
                  isLoading: auth.isLoading,
                  showApple:
                      Theme.of(context).platform == TargetPlatform.iOS ||
                      defaultTargetPlatform == TargetPlatform.android,
                  onGoogle: () async {
                    final ok = await auth.loginWithGoogle();
                    if (!context.mounted) return;
                    if (ok) {
                      context.go(AppRoutes.mode);
                    } else if (auth.errorMessage != null) {
                      _showError(auth.errorMessage);
                    }
                  },
                  onApple: () async {
                    final ok = await auth.loginWithApple();
                    if (!context.mounted) return;
                    if (ok) {
                      context.go(AppRoutes.mode);
                    } else if (auth.errorMessage != null) {
                      _showError(auth.errorMessage);
                    }
                  },
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.oauthSocialTermsNote,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: context.xiTextSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 380;
                    final createAccount = TextButton(
                      onPressed: () =>
                          context.push(AppRoutes.verifyEmailRequest),
                      style: TextButton.styleFrom(
                        foregroundColor: context.xiAccentText,
                      ),
                      child: Text(l10n.createAccount),
                    );
                    final forgotPassword = TextButton(
                      onPressed: () =>
                          context.push(AppRoutes.passwordResetRequest),
                      style: TextButton.styleFrom(
                        foregroundColor: context.xiAccentText,
                      ),
                      child: Text(l10n.forgotPassword),
                    );

                    if (isCompact) {
                      return Column(children: [createAccount, forgotPassword]);
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        createAccount,
                        Text('·', style: TextStyle(color: colorScheme.outline)),
                        forgotPassword,
                      ],
                    );
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
        content: Text(message ?? l10n.apiUnexpectedError),
      ),
    );
  }
}
