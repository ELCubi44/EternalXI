import 'package:eternal_xi/data/models/night_market_models.dart';
import 'package:eternal_xi/features/leagues/controller/league_night_market_controller.dart';
import 'package:eternal_xi/features/leagues/utils/league_night_market_format.dart';
import 'package:eternal_xi/features/leagues/utils/league_night_market_images.dart';
import 'package:eternal_xi/features/leagues/utils/league_player_photo.dart';
import 'package:eternal_xi/features/leagues/utils/league_thousands_input_formatter.dart';
import 'package:eternal_xi/features/leagues/widgets/league_team_logo.dart';
import 'package:flutter/material.dart';

class LeagueNightMarketBidSheet extends StatefulWidget {
  const LeagueNightMarketBidSheet({
    super.key,
    required this.item,
    required this.market,
    required this.controller,
    this.onAfterSuccess,
  });

  final NightMarketItem item;
  final NightMarketResponse market;
  final LeagueNightMarketController controller;
  final Future<void> Function()? onAfterSuccess;

  static Future<void> show({
    required BuildContext context,
    required NightMarketItem item,
    required NightMarketResponse market,
    required LeagueNightMarketController controller,
    Future<void> Function()? onAfterSuccess,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: LeagueNightMarketBidSheet(
          item: item,
          market: market,
          controller: controller,
          onAfterSuccess: onAfterSuccess,
        ),
      ),
    );
  }

  @override
  State<LeagueNightMarketBidSheet> createState() =>
      _LeagueNightMarketBidSheetState();
}

class _LeagueNightMarketBidSheetState extends State<LeagueNightMarketBidSheet> {
  static final _amountFormatter = LeagueThousandsInputFormatter();
  late final TextEditingController _amountController;
  String? _fieldError;
  bool _submitting = false;

  NightMarketItem get _item => widget.item;
  NightMarketResponse get _market => widget.market;

  int get _maxBidAllowed => _market.saldoDisponible + (_item.miPuja ?? 0);

  @override
  void initState() {
    super.initState();
    final initial = _item.miPuja != null && _item.miPuja! > 0
        ? LeagueThousandsInputFormatter.formatDigits(_item.miPuja!.toString())
        : '';
    _amountController = TextEditingController(text: initial);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  int? _parseAmount() {
    return LeagueThousandsInputFormatter.parseToInt(_amountController.text);
  }

  String? _validateAmount(int? value) {
    if (value == null) {
      return 'Indica un importe.';
    }
    if (value <= 0) {
      return 'El importe debe ser un entero positivo.';
    }
    if (value < _item.precioSalida) {
      return 'La puja no puede ser inferior al minimo permitido '
          '(${LeagueNightMarketFormat.moneyInt(_item.precioSalida)}).';
    }
    if (value > _maxBidAllowed) {
      return 'Según tu saldo y tu puja actual, el máximo que puedes pujar '
          'es ${LeagueNightMarketFormat.moneyInt(_maxBidAllowed)}.';
    }
    return null;
  }

  Future<void> _confirm() async {
    final v = _parseAmount();
    final err = _validateAmount(v);
    setState(() => _fieldError = err);
    if (err != null || v == null) {
      return;
    }

    setState(() => _submitting = true);
    try {
      final result = await widget.controller.submitBid(
        idMercadoDiario: _item.idMercadoDiario,
        cantidad: v,
      );

      if (!mounted) {
        return;
      }

      if (result.success) {
        Navigator.of(context).pop();
        await widget.onAfterSuccess?.call();
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.message)));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.message)));
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _deleteBid() async {
    if (_item.miPuja == null) {
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Eliminar puja'),
        content: const Text(
          'Se eliminará tu puja y el saldo retenido volverá a estar disponible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }
    setState(() => _submitting = true);
    try {
      final result = await widget.controller.deleteBid(
        idMercadoDiario: _item.idMercadoDiario,
      );
      if (!mounted) {
        return;
      }
      if (result.success) {
        Navigator.of(context).pop();
        await widget.onAfterSuccess?.call();
      }
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
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
    final photoUri = LeaguePlayerPhoto.resolveNightMarket(
      idJugador: _item.idJugador,
      fotoJugador: _item.fotoJugador,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _item.miPuja == null ? 'Pujar por jugador' : 'Actualizar puja',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: photoUri != null
                    ? Image.network(
                        photoUri.toString(),
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _photoFallback(colorScheme),
                      )
                    : _photoFallback(colorScheme),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _item.nombreVisible.trim().isEmpty
                          ? _item.nombre
                          : _item.nombreVisible,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        LeagueTeamLogo(
                          idEquipo: _item.idEquipo,
                          size: 22,
                          networkImageUrl:
                              LeagueNightMarketImages.teamBadgeNetworkUrl(
                                idEquipo: _item.idEquipo,
                                fotoEquipo: _item.fotoEquipo,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _item.nombreEquipo.trim().isEmpty
                                ? '—'
                                : _item.nombreEquipo,
                            style: theme.textTheme.bodyMedium?.copyWith(
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
          const SizedBox(height: 16),
          _InfoRow(
            label: 'Posición',
            value: LeagueNightMarketFormat.posicionLabel(_item.posicion),
          ),
          _InfoRow(label: 'Valoración', value: '${_item.valoracion}'),
          _InfoRow(
            label: 'Valor actual',
            value: LeagueNightMarketFormat.moneyInt(_item.valorActual),
          ),
          if (_item.miPuja != null)
            _InfoRow(
              label: 'Tu puja actual',
              value: LeagueNightMarketFormat.myBidOrNone(_item.miPuja),
            ),
          _InfoRow(
            label: 'Saldo disponible',
            value: LeagueNightMarketFormat.moneyInt(_market.saldoDisponible),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Si dos usuarios pujan lo mismo, gana la puja más antigua.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.35,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [_amountFormatter],
            decoration: InputDecoration(
              labelText: 'Importe de la puja',
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
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _submitting ? null : _confirm,
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Confirmar puja'),
                ),
              ),
            ],
          ),
          if (_item.miPuja != null) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _submitting ? null : _deleteBid,
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Eliminar puja'),
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
        size: 48,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
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
