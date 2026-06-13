import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/core/constants/legal_constants.dart';
import 'package:eternal_xi/core/utils/validators.dart';
import 'package:eternal_xi/features/auth/controller/auth_controller.dart';
import 'package:eternal_xi/shared/widgets/app_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> showAgeConfirmationDialog(BuildContext context) async {
  final auth = context.read<AuthController>();
  final user = auth.currentUser;
  if (user == null || !user.requiereConfirmacionEdad) {
    return;
  }

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _AgeConfirmationDialog(
      onConfirmed: () async {
        Navigator.of(dialogContext).pop();
      },
    ),
  );
}

class _AgeConfirmationDialog extends StatefulWidget {
  const _AgeConfirmationDialog({required this.onConfirmed});

  final VoidCallback onConfirmed;

  @override
  State<_AgeConfirmationDialog> createState() => _AgeConfirmationDialogState();
}

class _AgeConfirmationDialogState extends State<_AgeConfirmationDialog> {
  DateTime? _birthDate;
  bool _loading = false;
  String? _error;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      helpText: context.l10n.birthDateLabel,
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _error = null;
      });
    }
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (_birthDate == null) {
      setState(() => _error = l10n.validatorRequiredBirthDate);
      return;
    }
    final iso = _formatIsoDate(_birthDate!);
    final validationError = Validators.birthDate(iso, l10n);
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final ok = await context.read<AuthController>().confirmAge(iso);
    if (!mounted) return;

    if (ok) {
      widget.onConfirmed();
      return;
    }

    setState(() {
      _loading = false;
      _error = context.read<AuthController>().errorMessage ?? l10n.apiUnexpectedError;
    });
  }

  String _formatIsoDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final birthLabel = _birthDate == null
        ? l10n.birthDateHint
        : MaterialLocalizations.of(context).formatMediumDate(_birthDate!);

    return AlertDialog(
      title: Text(l10n.ageConfirmationTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.ageConfirmationBody(LegalConstants.minimumAgeYears)),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _loading ? null : _pickDate,
              child: Text(birthLabel),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        AppPrimaryButton(
          label: l10n.continueText,
          isLoading: _loading,
          onPressed: _loading ? null : _submit,
        ),
      ],
    );
  }
}
