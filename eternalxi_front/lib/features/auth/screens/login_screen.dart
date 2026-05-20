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
    final auth = context.watch<AuthController>();
    final colorScheme = Theme.of(context).colorScheme;

    return AppLoadingOverlay(
      isLoading: auth.isLoading,
      child: Scaffold(
        body: AuthShell(
          title: 'Entrar',
          subtitle:
              'Accede a tu cuenta, gestiona ligas y plantilla con el mismo estilo en toda la app.',
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
                  label: 'Correo electrónico',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _passwordController,
                  label: 'Contraseña',
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: Validators.password,
                ),
                const SizedBox(height: 22),
                AppPrimaryButton(
                  label: 'Iniciar sesión',
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
                      context.go(AppRoutes.home);
                    } else {
                      _showError(auth.errorMessage);
                    }
                  },
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 380;
                    final createAccount = TextButton(
                      onPressed: () => context.push(AppRoutes.verifyEmailRequest),
                      child: const Text('Crear cuenta'),
                    );
                    final forgotPassword = TextButton(
                      onPressed: () => context.push(AppRoutes.passwordResetRequest),
                      child: const Text('He olvidado la contraseña'),
                    );

                    if (isCompact) {
                      return Column(
                        children: [
                          createAccount,
                          forgotPassword,
                        ],
                      );
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        createAccount,
                        Text(
                          '·',
                          style: TextStyle(color: colorScheme.outline),
                        ),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(message ?? 'No se pudo iniciar sesión'),
      ),
    );
  }
}
