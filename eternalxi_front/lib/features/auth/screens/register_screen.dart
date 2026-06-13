import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/core/utils/validators.dart';
import 'package:eternal_xi/features/auth/controller/auth_controller.dart';
import 'package:eternal_xi/features/auth/widgets/auth_shell.dart';
import 'package:eternal_xi/features/legal/screens/legal_document_screen.dart';
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
  DateTime? _birthDate;
  bool _acceptTerms = false;
  bool _confirmMinAge = false;

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

  String? _birthDateError(AppLocalizations l10n) {
    if (_birthDate == null) {
      return l10n.validatorRequiredBirthDate;
    }
    return Validators.birthDate(_formatIsoDate(_birthDate!), l10n);
  }

  String _formatIsoDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      helpText: context.l10n.birthDateLabel,
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  void _openLegal(LegalDocumentType type) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LegalDocumentScreen(type: type),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = context.watch<AuthController>();
    final colorScheme = Theme.of(context).colorScheme;
    final birthLabel = _birthDate == null
        ? l10n.birthDateHint
        : MaterialLocalizations.of(context).formatMediumDate(_birthDate!);

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
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.birthDateLabel,
                    style: TextStyle(
                      fontFamily: 'Lumiare',
                      fontSize: 13,
                      color: context.xiTextSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _pickBirthDate,
                  child: Text(birthLabel),
                ),
                if (_birthDate != null)
                  Builder(
                    builder: (context) {
                      final err = _birthDateError(l10n);
                      if (err == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          err,
                          style: TextStyle(
                            color: colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
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
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _confirmMinAge,
                  onChanged: (v) => setState(() => _confirmMinAge = v ?? false),
                  title: Text(
                    l10n.confirmMinAgeLabel,
                    style: TextStyle(
                      fontFamily: 'Lumiare',
                      fontSize: 13,
                      color: context.xiTextPrimary,
                    ),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _acceptTerms,
                  onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                  title: Text(
                    l10n.acceptTermsLabel,
                    style: TextStyle(
                      fontFamily: 'Lumiare',
                      fontSize: 13,
                      color: context.xiTextPrimary,
                    ),
                  ),
                  subtitle: Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () => _openLegal(LegalDocumentType.terms),
                        child: Text(l10n.legalTermsLink),
                      ),
                      TextButton(
                        onPressed: () =>
                            _openLegal(LegalDocumentType.privacySummary),
                        child: Text(l10n.legalPrivacyLink),
                      ),
                    ],
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 16),
                AppPrimaryButton(
                  label: l10n.register,
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) {
                      return;
                    }
                    final birthErr = _birthDateError(l10n);
                    if (birthErr != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text(birthErr),
                        ),
                      );
                      return;
                    }
                    if (!_confirmMinAge) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text(l10n.validatorConfirmMinAgeRequired),
                        ),
                      );
                      return;
                    }
                    if (!_acceptTerms) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text(l10n.validatorAcceptTermsRequired),
                        ),
                      );
                      return;
                    }
                    final message = await auth.register(
                      correo: _correoController.text.trim(),
                      nickname: _nicknameController.text.trim(),
                      contrasena: _passwordController.text,
                      fechaNacimiento: _formatIsoDate(_birthDate!),
                      aceptaTerminos: _acceptTerms,
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
