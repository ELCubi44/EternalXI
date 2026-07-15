import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/core/utils/validators.dart';
import 'package:eternal_xi/features/auth/controller/auth_controller.dart';
import 'package:eternal_xi/data/services/leagues_api_service.dart';
import 'package:eternal_xi/shared/widgets/app_loading_overlay.dart';
import 'package:eternal_xi/shared/widgets/app_primary_button.dart';
import 'package:eternal_xi/shared/widgets/app_text_field.dart';
import 'package:eternal_xi/shared/widgets/fantasy_atmosphere_background.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class JoinLeagueScreen extends StatefulWidget {
  const JoinLeagueScreen({super.key, this.prefilledCode});

  final String? prefilledCode;

  @override
  State<JoinLeagueScreen> createState() => _JoinLeagueScreenState();
}

class _JoinLeagueScreenState extends State<JoinLeagueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final code = widget.prefilledCode?.trim();
    if (code != null && code.isNotEmpty) {
      _codeController.text = code;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  int? _userIdOrNull() {
    final id = context.read<AuthController>().currentUser?.id;
    if (id == null || id <= 0) {
      return null;
    }
    return id;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final idUsuario = _userIdOrNull();
    if (idUsuario == null) {
      setState(() => _error = 'No hay usuario en sesión.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final api = context.read<LeaguesApiService>();
      final response = await api.joinLeague(
        codigoInvitacion: _codeController.text.trim(),
        idUsuario: idUsuario,
      );
      if (!mounted) {
        return;
      }
      if (kDebugMode) {
        debugPrint(
          '[join-league] idLiga=${response.idLiga} '
          'jugadoresAsignados=${response.jugadoresAsignados} '
          'plantillaIncompleta=${response.plantillaIncompleta} '
          'valorPlantillaInicial=${response.valorPlantillaInicial}',
        );
      }
      final notice = response.postJoinNotice;
      final messenger = ScaffoldMessenger.of(context);
      context.go(AppRoutes.leagueDetail(response.idLiga));
      if (notice != null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(notice),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return WithFantasyAtmosphere(
      child: AppLoadingOverlay(
        isLoading: _submitting,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: Text(l10n.joinLeague)),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.joinLeagueDescription,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppTextField(
                    controller: _codeController,
                    label: l10n.invitationCode,
                    hintText: l10n.invitationHint,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.done,
                    validator: (value) => Validators.invitationCode(value, l10n),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Material(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: colorScheme.onErrorContainer,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _error!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  AppPrimaryButton(
                    label: l10n.join,
                    isLoading: _submitting,
                    onPressed: _submitting ? null : _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
