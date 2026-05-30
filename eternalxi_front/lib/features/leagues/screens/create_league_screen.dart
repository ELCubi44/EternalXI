import 'package:eternal_xi/app/localization/league_l10n.dart';
import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/core/utils/league_asset_urls.dart';
import 'package:eternal_xi/core/utils/validators.dart';
import 'package:eternal_xi/data/models/create_league_request.dart';
import 'package:eternal_xi/data/models/season_summary.dart';
import 'package:eternal_xi/data/services/leagues_api_service.dart';
import 'package:eternal_xi/features/leagues/utils/league_config_labels.dart';
import 'package:eternal_xi/features/leagues/widgets/create_league_advanced_config_section.dart';
import 'package:eternal_xi/features/auth/controller/auth_controller.dart';
import 'package:eternal_xi/shared/widgets/app_loading_overlay.dart';
import 'package:eternal_xi/shared/widgets/app_primary_button.dart';
import 'package:eternal_xi/features/profile/controller/user_preferences_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class CreateLeagueScreen extends StatefulWidget {
  const CreateLeagueScreen({super.key});

  @override
  State<CreateLeagueScreen> createState() => _CreateLeagueScreenState();
}

class _CreateLeagueScreenState extends State<CreateLeagueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  List<SeasonSummary> _seasons = const [];
  bool _seasonsLoading = true;
  String? _seasonsError;
  int? _selectedSeasonId;
  bool _submitting = false;
  String? _error;
  String? _noAvailableSeasonsMessage;
  bool _advancedExpanded = true;

  int _maxParticipantes = LeagueConfigLabels.maxParticipantesDefault;
  bool _semanaPreviaFichajes = true;
  bool _permiteEntresemana = false;
  bool _idaYVuelta = false;
  int _recompensaBaseJornada = LeagueConfigLabels.recompensaDefault;
  int _dineroPorPuntoFantasy = LeagueConfigLabels.dineroPorPuntoDefault;
  String? _loadedSeasonsForLanguage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = context.watch<UserPreferencesController>().resolvedLanguageTag;
    if (_loadedSeasonsForLanguage == lang) {
      return;
    }
    _loadedSeasonsForLanguage = lang;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSeasons());
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _loadSeasons() async {
    setState(() {
      _seasonsLoading = true;
      _seasonsError = null;
      _noAvailableSeasonsMessage = null;
    });
    try {
      final api = context.read<LeaguesApiService>();
      final list = await api.fetchSeasonCatalog();
      final idUsuario = _userIdOrNull();
      final filtered = list
          .where((s) => s.id != 1 || idUsuario == 3)
          .toList(growable: false);
      if (!mounted) {
        return;
      }
      setState(() {
        _seasons = filtered;
        if (_selectedSeasonId != null &&
            !_seasons.any((s) => s.id == _selectedSeasonId)) {
          _selectedSeasonId = null;
        }
        if (_seasons.isNotEmpty) {
          _selectedSeasonId ??= _seasons.first.id;
        }
        _noAvailableSeasonsMessage = _seasons.isEmpty
            ? 'Ahora mismo no tienes temporadas disponibles para crear una liga'
            : null;
        _seasonsLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _seasons = const [];
        _selectedSeasonId = null;
        _seasonsError = e.toString().replaceFirst('Exception: ', '');
        _seasonsLoading = false;
      });
    }
  }

  int? _userIdOrNull() {
    final id = context.read<AuthController>().currentUser?.id;
    if (id == null || id <= 0) {
      return null;
    }
    return id;
  }

  /// Nombre mostrado sin prefijos tipo "Temporada:" del catálogo.
  String _prettySeasonTitle(SeasonSummary s) {
    var n = s.nombre.trim();
    final lower = n.toLowerCase();
    if (lower.startsWith('temporada:')) {
      n = n.substring('Temporada:'.length).trim();
    } else if (lower.startsWith('temporada :')) {
      n = n.substring('Temporada :'.length).trim();
    }
    return n;
  }

  /// Imagen de la temporada siempre vía asset HTTP (`GET .../assets/seasons/{id}`).
  String _seasonCoverUrl(SeasonSummary s) {
    return LeagueAssetUrls.seasonCover(s.id).toString();
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
    final sid = _selectedSeasonId;
    if (sid == null) {
      setState(() => _error = 'Elige una temporada.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final api = context.read<LeaguesApiService>();
      final response = await api.createLeague(
        CreateLeagueRequest(
          nombre: _nombreController.text.trim(),
          idTemporada: sid,
          idUsuario: idUsuario,
          maxParticipantes: _maxParticipantes,
          semanaPreviaFichajes: _semanaPreviaFichajes,
          permiteEntresemana: _permiteEntresemana,
          idaYVuelta: _idaYVuelta,
          recompensaBaseJornada: _recompensaBaseJornada,
          dineroPorPuntoFantasy: _dineroPorPuntoFantasy,
        ),
      );
      if (!mounted) {
        return;
      }
      context.pushReplacement(AppRoutes.leagueDetail(response.idLiga));
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
    final ll = context.leagueL10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppLoadingOverlay(
      isLoading: _submitting,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.createLeague),
          actions: [
            if (!_seasonsLoading && _seasons.isEmpty)
              IconButton(
                tooltip: l10n.retry,
                onPressed: _submitting ? null : _loadSeasons,
                icon: const Icon(Icons.refresh_rounded),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la liga',
                    counterText: '',
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) => Validators.leagueName(value, l10n),
                  maxLength: 50,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(50),
                  ],
                ),
                const SizedBox(height: 24),
                if (_seasonsLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_seasons.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 48,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _seasonsError != null
                              ? l10n.preferencesLoadError
                              : (_noAvailableSeasonsMessage ??
                                    l10n.seasonUnavailable),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ..._seasons.map((s) {
                    final selected = _selectedSeasonId == s.id;
                    final uri = _seasonCoverUrl(s);
                    final name = _prettySeasonTitle(s);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: selected
                            ? colorScheme.primaryContainer.withValues(
                                alpha: 0.55,
                              )
                            : colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(18),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: _submitting
                              ? null
                              : () => setState(() => _selectedSeasonId = s.id),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: SizedBox(
                                    width: 64,
                                    height: 64,
                                    child: Image.network(
                                      uri,
                                      fit: BoxFit.cover,
                                      alignment: Alignment.center,
                                      errorBuilder: (_, _, _) => ColoredBox(
                                        color:
                                            colorScheme.surfaceContainerHighest,
                                        child: Icon(
                                          Icons.image_not_supported_outlined,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                      loadingBuilder: (c, w, progress) {
                                        if (progress == null) {
                                          return w;
                                        }
                                        return ColoredBox(
                                          color: colorScheme
                                              .surfaceContainerHighest,
                                          child: Center(
                                            child: SizedBox(
                                              width: 26,
                                              height: 26,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: name.isEmpty
                                      ? const SizedBox.shrink()
                                      : Text(
                                          name,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                ),
                                if (selected)
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: colorScheme.primary,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                if (!_seasonsLoading && _seasons.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Material(
                    color: colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: ExpansionTile(
                      initiallyExpanded: _advancedExpanded,
                      onExpansionChanged: _submitting
                          ? null
                          : (v) => setState(() => _advancedExpanded = v),
                      title: Text(
                        l10n.advancedConfig,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        ll.createLeagueParticipantsSummary(
                          _maxParticipantes,
                          LeagueConfigLabels.calendarLabel(
                            _permiteEntresemana,
                            l10n: l10n,
                          ),
                          LeagueConfigLabels.formatLabel(_idaYVuelta, l10n: l10n),
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: CreateLeagueAdvancedConfigSection(
                            maxParticipantes: _maxParticipantes,
                            semanaPreviaFichajes: _semanaPreviaFichajes,
                            permiteEntresemana: _permiteEntresemana,
                            idaYVuelta: _idaYVuelta,
                            recompensaBaseJornada: _recompensaBaseJornada,
                            dineroPorPuntoFantasy: _dineroPorPuntoFantasy,
                            enabled: !_submitting,
                            onMaxParticipantesChanged: (v) =>
                                setState(() => _maxParticipantes = v),
                            onSemanaPreviaChanged: (v) =>
                                setState(() => _semanaPreviaFichajes = v),
                            onPermiteEntresemanaChanged: (v) =>
                                setState(() => _permiteEntresemana = v),
                            onIdaYVueltaChanged: (v) =>
                                setState(() => _idaYVuelta = v),
                            onRecompensaChanged: (v) =>
                                setState(() => _recompensaBaseJornada = v),
                            onDineroPorPuntoChanged: (v) =>
                                setState(() => _dineroPorPuntoFantasy = v),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                  label: l10n.createLeague,
                  isLoading: _submitting,
                  onPressed:
                      _submitting ||
                          _seasonsLoading ||
                          _selectedSeasonId == null ||
                          _seasons.isEmpty
                      ? null
                      : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
