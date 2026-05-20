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
    this.onAfterSuccess,
  });

  final int idLiga;
  final int idUsuario;
  final LeagueSquadPlayer player;
  final int? miDinero;
  final Future<void> Function()? onAfterSuccess;

  static Future<void> show({
    required BuildContext context,
    required int idLiga,
    required int idUsuario,
    required LeagueSquadPlayer player,
    int? miDinero,
    Future<void> Function()? onAfterSuccess,
  }) {
    if (player.idUsuarioDueno == idUsuario) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes enviar oferta por un jugador tuyo.'),
        ),
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

  int? _parseAmount() =>
      LeagueThousandsInputFormatter.parseToInt(_amountController.text);

  String? _validate(int? amount) {
    if (amount == null) {
      return 'Indica un importe.';
    }
    if (amount <= 0) {
      return 'El importe debe ser mayor que 0.';
    }
    if (amount < _minOffer) {
      return 'La oferta mínima por este jugador es ${LeagueMoneyFormat.money(_minOffer.toDouble())}.';
    }
    final budget = widget.miDinero;
    if (budget != null && amount > budget) {
      return 'No tienes suficiente dinero para hacer esta oferta.';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = _parseAmount();
    final err = _validate(amount);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Oferta enviada correctamente.')),
      );
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final p = widget.player;
    final photo = LeaguePlayerPhoto.resolve(p);
    final displayName = LeagueDisplayStrings.playerShortName(
      pila: p.pila,
      nombre: p.nombre,
    );
    final ownerName = p.nombreDuenoVisible.trim().isEmpty
        ? (p.propietarioNick.trim().isEmpty ? '—' : p.propietarioNick.trim())
        : p.nombreDuenoVisible.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Hacer oferta',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
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
                        fontWeight: FontWeight.w700,
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
          _InfoRow(label: 'Dueño actual', value: ownerName),
          _InfoRow(
            label: 'Valor actual',
            value: LeagueMoneyFormat.money(p.valor),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [_formatter],
            decoration: InputDecoration(
              labelText: 'Cantidad ofertada',
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
                  child: const Text('Cancelar'),
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
                      : const Text('Enviar oferta'),
                ),
              ),
            ],
          ),
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
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
