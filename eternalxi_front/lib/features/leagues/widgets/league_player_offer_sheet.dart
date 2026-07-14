import 'package:eternal_xi/app/localization/league_l10n.dart';
import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/core/utils/league_money_format.dart';
import 'package:eternal_xi/data/models/league_squad_player.dart';
import 'package:eternal_xi/data/services/leagues_api_service.dart';
import 'package:eternal_xi/features/leagues/utils/league_display_strings.dart';
import 'package:eternal_xi/features/leagues/utils/league_player_photo.dart';
import 'package:eternal_xi/features/leagues/utils/league_thousands_input_formatter.dart';
import 'package:eternal_xi/features/leagues/widgets/league_team_logo.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LeaguePlayerOfferSheet extends StatefulWidget {
  const LeaguePlayerOfferSheet({
    super.key,
    required this.idLiga,
    required this.idUsuario,
    required this.player,
    this.miDinero,
    this.idOferta,
    this.cantidadActual,
    this.onAfterSuccess,
  });

  final int idLiga;
  final int idUsuario;
  final LeagueSquadPlayer player;
  final int? miDinero;

  /// Si se indica, el sheet opera en modo edición (actualizar/cancelar oferta).
  final int? idOferta;
  final int? cantidadActual;
  final Future<void> Function()? onAfterSuccess;

  bool get _isEditing => idOferta != null && cantidadActual != null;

  static Future<void> show({
    required BuildContext context,
    required int idLiga,
    required int idUsuario,
    required LeagueSquadPlayer player,
    int? miDinero,
    int? idOferta,
    int? cantidadActual,
    Future<void> Function()? onAfterSuccess,
  }) {
    if (player.idUsuarioDueno == idUsuario) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.leagueL10n.cannotOfferOwnSnack)),
      );
      return Future.value();
    }
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: LeaguePlayerOfferSheet(
          idLiga: idLiga,
          idUsuario: idUsuario,
          player: player,
          miDinero: miDinero,
          idOferta: idOferta,
          cantidadActual: cantidadActual,
          onAfterSuccess: onAfterSuccess,
        ),
      ),
    );
  }

  @override
  State<LeaguePlayerOfferSheet> createState() => _LeaguePlayerOfferSheetState();
}

class _LeaguePlayerOfferSheetState extends State<LeaguePlayerOfferSheet> {
  final _formatter = LeagueThousandsInputFormatter();
  late final TextEditingController _amountController;
  bool _submitting = false;
  String? _fieldError;

  int get _minOffer => widget.player.valor.ceil();

  int get _maxOfferAllowed =>
      (widget.miDinero ?? 0) + (widget.cantidadActual ?? 0);

  int? _parseAmount() =>
      LeagueThousandsInputFormatter.parseToInt(_amountController.text);

  String? _validate(int? amount, LeagueL10n ll) {
    if (amount == null) {
      return ll.indicateAmount;
    }
    if (amount <= 0) {
      return ll.amountMustBePositive;
    }
    if (amount < _minOffer) {
      return ll.minOfferError(LeagueMoneyFormat.money(_minOffer.toDouble()));
    }
    if (widget.miDinero != null && amount > _maxOfferAllowed) {
      return ll.maxOfferError(
        LeagueMoneyFormat.money(_maxOfferAllowed.toDouble()),
      );
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.cantidadActual != null && widget.cantidadActual! > 0
        ? LeagueThousandsInputFormatter.formatDigits(
            widget.cantidadActual!.toString(),
          )
        : '';
    _amountController = TextEditingController(text: initial);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = _parseAmount();
    final ll = context.leagueL10n;
    final err = _validate(amount, ll);
    setState(() => _fieldError = err);
    if (err != null || amount == null) {
      return;
    }
    setState(() {
      _submitting = true;
      _fieldError = null;
    });
    try {
      final api = context.read<LeaguesApiService>();
      await api.upsertOffer(
        idLiga: widget.idLiga,
        idLigaJugador: widget.player.idLigaJugador,
        idUsuario: widget.idUsuario,
        cantidad: amount,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      await widget.onAfterSuccess?.call();
      if (!mounted) {
        return;
      }
      if (widget._isEditing) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.leagueL10n.offerUpdated)),
        );
      } else {
        await showOfferSentConfirmation(context);
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _fieldError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _cancelOffer() async {
    final idOferta = widget.idOferta;
    if (idOferta == null) {
      return;
    }
    final ll = context.leagueL10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(c.l10n.cancelOffer),
        content: Text(ll.cancelOfferConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(ll.goBack),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(c.l10n.cancelOffer),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }
    setState(() {
      _submitting = true;
      _fieldError = null;
    });
    try {
      final api = context.read<LeaguesApiService>();
      final response = await api.cancelOffer(
        idLiga: widget.idLiga,
        idOferta: idOferta,
        idUsuario: widget.idUsuario,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      await widget.onAfterSuccess?.call();
      if (!mounted) {
        return;
      }
      final msg = response.message.trim().isEmpty
          ? context.leagueL10n.offerCancelledSuccess
          : response.message.trim();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _fieldError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ll = context.leagueL10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final p = widget.player;
    final photo = LeaguePlayerPhoto.resolve(p);
    final displayName = LeagueDisplayStrings.playerShortName(
      pila: p.pila,
      nombre: p.nombre,
      ll: ll,
    );
    final ownerName = _resolveOwnerName(p);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget._isEditing ? ll.updateOffer : ll.makeOffer,
            style: theme.textTheme.titleLarge?.copyWith(
              ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: photo != null
                    ? Image.network(
                        photo.toString(),
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _photoFallback(colorScheme),
                      )
                    : _photoFallback(colorScheme),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        LeagueTeamLogo(
                          idEquipo: p.idEquipo,
                          size: 20,
                          networkImageUrl: p.resolvedFotoEquipoUrl(),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            p.nombreEquipo.trim().isEmpty
                                ? '—'
                                : p.nombreEquipo,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _InfoRow(label: ll.currentOwner, value: ownerName),
          _InfoRow(
            label: ll.currentValueLabel,
            value: LeagueMoneyFormat.money(p.valor),
          ),
          if (widget.cantidadActual != null)
            _InfoRow(
              label: ll.yourCurrentOffer,
              value: LeagueMoneyFormat.money(widget.cantidadActual!.toDouble()),
            ),
          if (widget.miDinero != null)
            _InfoRow(
              label: ll.availableBalance,
              value: LeagueMoneyFormat.money(widget.miDinero!.toDouble()),
            ),
          const SizedBox(height: 14),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [_formatter],
            decoration: InputDecoration(
              labelText: ll.offerAmountLabel,
              suffixText: '€',
              errorText: _fieldError,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) {
              if (_fieldError != null) {
                setState(() => _fieldError = null);
              }
            },
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text(context.l10n.cancel),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget._isEditing ? ll.confirmOffer : ll.sendOfferButton),
                ),
              ),
            ],
          ),
          if (widget._isEditing) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _submitting ? null : _cancelOffer,
              icon: const Icon(Icons.delete_outline_rounded),
              label: Text(context.l10n.cancelOffer),
            ),
          ],
        ],
      ),
    );
  }

  Widget _photoFallback(ColorScheme colorScheme) {
    return Container(
      width: 72,
      height: 72,
      color: colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.person_outline_rounded,
        color: colorScheme.onSurfaceVariant,
        size: 42,
      ),
    );
  }
}

String _resolveOwnerName(LeagueSquadPlayer player) {
  final visible = player.nombreDuenoVisible.trim();
  if (visible.isNotEmpty) {
    return visible;
  }
  final nick = player.propietarioNick.trim();
  if (nick.isNotEmpty) {
    return nick;
  }
  if (player.idUsuarioDueno > 0 &&
      player.idUsuarioDueno != LeagueSquadPlayer.usuarioMercadoId) {
    return 'Usuario #${player.idUsuarioDueno}';
  }
  return '—';
}

Future<void> showOfferSentConfirmation(BuildContext context) {
  final ll = context.leagueL10n;
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: Icon(
        Icons.check_circle_outline_rounded,
        color: colorScheme.primary,
        size: 40,
      ),
      title: Text(ll.offerSentTitle),
      content: Text(ll.offerRegisteredBody),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(ll.understood),
        ),
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                ),
            ),
          ),
        ],
      ),
    );
  }
}
