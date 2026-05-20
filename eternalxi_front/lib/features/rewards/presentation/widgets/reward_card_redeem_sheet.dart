import 'dart:convert';

import 'package:eternal_xi/features/rewards/data/models/reward_card_model.dart';
import 'package:eternal_xi/features/rewards/data/models/reward_card_target_model.dart';
import 'package:eternal_xi/features/rewards/data/models/reward_redeem_result_model.dart';
import 'package:eternal_xi/features/rewards/data/services/rewards_api_service.dart';
import 'package:eternal_xi/features/rewards/presentation/controllers/rewards_controller.dart';
import 'package:eternal_xi/features/rewards/utils/reward_formatters.dart';
import 'package:eternal_xi/core/network/api_client.dart';
import 'package:eternal_xi/core/utils/league_asset_urls.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> openRewardCardRedeemSheet({
  required BuildContext context,
  required RewardsController rewards,
  required RewardCardModel card,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: const Color(0xFF0E121C),
    builder: (ctx) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<RewardsController>.value(value: rewards),
          ChangeNotifierProvider<_RedeemSheetController>(
            create: (c) => _RedeemSheetController(
              api: c.read<RewardsApiService>(),
              apiClient: c.read<ApiClient>(),
              idLiga: rewards.idLiga,
              idUsuario: rewards.idUsuario,
              card: card,
            )..load(),
          ),
        ],
        child: const _RedeemSheetBody(),
      );
    },
  );
}

class _RedeemSheetController extends ChangeNotifier {
  _RedeemSheetController({
    required this.api,
    required this.apiClient,
    required this.idLiga,
    required this.idUsuario,
    required this.card,
  });

  final RewardsApiService api;
  final ApiClient apiClient;
  final int idLiga;
  final int idUsuario;
  final RewardCardModel card;

  RewardValidTargetsResponse? targets;
  bool loading = true;
  String? error;
  bool redeeming = false;

  void setRedeeming(bool value) {
    redeeming = value;
    notifyListeners();
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final tipo = card.tipoEfecto.trim().toUpperCase();
      if (tipo == 'ADD_LEAGUE_POINTS') {
        targets = await api.getValidTargets(
          idLiga: idLiga,
          idCarta: card.idCarta,
          idUsuario: idUsuario,
        );
      } else {
        targets = await api.getValidTargets(
          idLiga: idLiga,
          idCarta: card.idCarta,
          idUsuario: idUsuario,
        );
      }
    } catch (e) {
      error = apiClient.extractErrorMessage(e);
      targets = null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}

class _RedeemSheetBody extends StatelessWidget {
  const _RedeemSheetBody();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<_RedeemSheetController>();
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.94,
        builder: (_, scroll) {
          if (c.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (c.error != null) {
            return ListView(
              controller: scroll,
              children: [
                Text(c.error!, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ],
            );
          }
          final tipo = c.card.tipoEfecto.trim().toUpperCase();
          return ListView(
            controller: scroll,
            children: [
              Text(
                c.card.nombre,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                c.card.descripcion,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              if (tipo == 'ADD_LEAGUE_POINTS')
                _AddPointsConfirm(controller: c)
              else if (tipo == 'SELL_PLAYER_BONUS')
                _SellTargets(controller: c)
              else if (tipo == 'DIRECT_CLAUSE')
                _ClauseTargets(controller: c)
              else if (tipo == 'PROTECT_PLAYER')
                _ProtectTargets(controller: c)
              else if (tipo == 'TEMPORARY_VALUE_RECOVERY')
                _RecoveryTargets(controller: c)
              else
                Text(
                  'Tipo de carta no soportado en la app: $tipo',
                  style: const TextStyle(color: Colors.orangeAccent),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Helpers (hoja de canje: importes completos, sin abreviaturas) ───

String _moneyFull(int? v) => v != null ? formatRewardMoneyFull(v) : '—';

String? _valoracionLinea(double? v) =>
    v == null ? null : 'Valoración: ${v.round()}';

String _humanizeBlockedMotivo(String? raw) {
  final t = raw?.trim();
  if (t == null || t.isEmpty) {
    return '';
  }
  final u = t.toUpperCase().replaceAll(' ', '_');
  switch (u) {
    case 'SUPERA_VALOR_MAXIMO_CARTA':
      return 'Supera el valor máximo de esta carta';
    case 'JUGADOR_PROTEGIDO':
    case 'PLAYER_PROTECTED':
      return 'Jugador protegido';
    case 'PROTECCION_ACTIVA':
      return 'Protección activa';
    case 'PROTECCION_IGUAL_O_SUPERIOR':
      return 'Protección igual o superior activa';
    default:
      return '';
  }
}

String _blockedPlayerMessage(RewardCardTargetPlayer p) {
  final m = _humanizeBlockedMotivo(p.motivoBloqueo);
  if (m.isNotEmpty) {
    return m;
  }
  if (p.protegido == true) {
    return 'Jugador protegido';
  }
  return '';
}

String? _proteccionTitularLinea(RewardCardTargetPlayer p) {
  if (p.protegido != true) {
    return null;
  }
  if (p.proteccionHastaFinTemporada == true) {
    return 'Protegido toda la temporada';
  }
  final n = p.numeroJornadaFinProteccion;
  if (n != null) {
    return 'Protegido hasta la jornada $n';
  }
  return null;
}

String? _recoveryBajandoLinea(RewardCardTargetPlayer p) {
  final d = p.diferenciaValorPreview;
  if (d != null) {
    final negativo = d > 0 ? -d : d;
    return 'Bajando: ${formatRewardMoneyFull(negativo)}';
  }
  final a = p.valorAnterior;
  final b = p.valorActual;
  if (a == null || b == null || a <= b) {
    return null;
  }
  final drop = a - b;
  return 'Bajando: ${formatRewardMoneyFull(-drop)}';
}

String? _recoverySubeLinea(RewardCardTargetPlayer p) {
  final inc = p.incrementoValorDiarioPreview;
  if (inc == null || inc <= 0) {
    return null;
  }
  return 'Subirá: +${formatRewardMoneyFull(inc)}/día';
}

Future<void> _confirmAndRedeem({
  required BuildContext sheetContext,
  required _RedeemSheetController c,
  required int? idLigaJugadorObjetivo,
  required String confirmTitle,
  required String confirmBody,
}) async {
  final ok = await showDialog<bool>(
    context: sheetContext,
    builder: (ctx) => AlertDialog(
      title: Text(confirmTitle),
      content: Text(confirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Confirmar'),
        ),
      ],
    ),
  );
  if (ok != true || !sheetContext.mounted) return;
  c.setRedeeming(true);
  final rewards = sheetContext.read<RewardsController>();
  final result = await rewards.redeemCard(
    idCarta: c.card.idCarta,
    idLigaJugadorObjetivo: idLigaJugadorObjetivo,
  );
  if (!sheetContext.mounted) return;
  c.setRedeeming(false);
  if (result != null) {
    Navigator.pop(sheetContext);
    _showRedeemSuccess(sheetContext, result);
  } else {
    final msg = rewards.errorMessage ?? 'No se pudo completar la acción. Inténtalo de nuevo.';
    ScaffoldMessenger.of(sheetContext).showSnackBar(SnackBar(content: Text(msg)));
  }
}

void _showRedeemSuccess(BuildContext context, RewardRedeemResultModel r) {
  final tipo = r.tipoEfecto.toUpperCase();
  String title = 'Listo';
  final lines = <String>[];

  switch (tipo) {
    case 'SELL_PLAYER_BONUS':
      title = 'Venta completada';
      if (r.nombreJugador != null) lines.add('Jugador: ${r.nombreJugador}');
      if (r.cantidadRecibida != null) {
        lines.add('Has recibido ${formatRewardMoneyFull(r.cantidadRecibida!)}');
      }
      if (r.nuevoDineroLiga != null) {
        lines.add('Nuevo presupuesto: ${formatRewardMoneyFull(r.nuevoDineroLiga!)}');
      }
    case 'DIRECT_CLAUSE':
      title = 'Cláusula ejecutada';
      if (r.nombreJugador != null) {
        lines.add('${r.nombreJugador} ahora está en tu plantilla.');
      } else {
        lines.add('Jugador añadido a tu plantilla.');
      }
      if (r.pagadoPorAtacante != null) {
        lines.add('Pagado: ${formatRewardMoneyFull(r.pagadoPorAtacante!)}');
      }
      if (r.nuevoDineroAtacante != null) {
        lines.add('Tu presupuesto: ${formatRewardMoneyFull(r.nuevoDineroAtacante!)}');
      }
    case 'PROTECT_PLAYER':
      title = 'Jugador protegido';
      if (r.nombreJugador != null) lines.add(r.nombreJugador!);
      if (r.proteccionHastaFinTemporada == true) {
        lines.add('Protegido toda la temporada');
      } else if (r.numeroJornadaFinProteccion != null) {
        lines.add('Protegido hasta la jornada ${r.numeroJornadaFinProteccion}');
      }
    case 'ADD_LEAGUE_POINTS':
      title = 'Puntos añadidos';
      if (r.puntosAnadidos != null) lines.add('+${r.puntosAnadidos} puntos');
      if (r.puntosTotalesEfectivos != null) lines.add('Nuevo total: ${r.puntosTotalesEfectivos}');
    case 'TEMPORARY_VALUE_RECOVERY':
      title = 'Valor temporal aplicado';
      if (r.nombreJugador != null) lines.add(r.nombreJugador!);
      if (r.valorTemporal != null) {
        lines.add('Nuevo valor temporal: ${formatRewardMoneyFull(r.valorTemporal!)}');
      }
      if (r.numeroJornadaExpiracion != null) {
        lines.add('Expira en la jornada ${r.numeroJornadaExpiracion}');
      }
    default:
      title = 'Operación completada';
  }

  if (lines.isEmpty) lines.add('Operación completada.');

  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(lines.join('\n')),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

Widget _emptyTargets(String message) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Column(
      children: [
        const Icon(Icons.search_off_rounded, size: 48, color: Colors.white38),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54, height: 1.35),
        ),
      ],
    ),
  );
}

Widget _playerAvatar(RewardCardTargetPlayer p) {
  final url = LeagueAssetUrls.buildBackendImageUrl(p.fotoJugador);
  if (url != null) {
    return CircleAvatar(
      radius: 20,
      backgroundImage: NetworkImage(url),
      backgroundColor: const Color(0xFF1A2233),
      onBackgroundImageError: (_, _) {},
    );
  }
  return const CircleAvatar(
    radius: 20,
    backgroundColor: Color(0xFF1A2233),
    child: Icon(Icons.person, color: Colors.white38, size: 20),
  );
}

Widget _teamBadge(RewardCardTargetPlayer p) {
  final url = LeagueAssetUrls.resolveTeamBadgeUrl(
    idEquipo: p.idEquipo ?? 0,
    rawFoto: p.fotoEquipo,
  );
  if (url != null) {
    return Image.network(
      url,
      width: 16,
      height: 16,
      errorBuilder: (_, _, _) => const Icon(Icons.shield_outlined, size: 16, color: Colors.white24),
    );
  }
  return const SizedBox.shrink();
}

Widget _positionChip(String? pos) {
  if (pos == null || pos.isEmpty) return const SizedBox.shrink();
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(4),
      color: Colors.white.withValues(alpha: 0.08),
    ),
    child: Text(pos, style: const TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.w700)),
  );
}

/// Botón de acción pequeño (Vender / Clausular / Proteger / Aplicar).
class _CompactActionButton extends StatelessWidget {
  const _CompactActionButton({
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 96, minHeight: 36, maxHeight: 40),
      child: FilledButton(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: onPressed,
        child: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
      ),
    );
  }
}

// ─── ADD_LEAGUE_POINTS ───

class _AddPointsConfirm extends StatelessWidget {
  const _AddPointsConfirm({required this.controller});
  final _RedeemSheetController controller;

  @override
  Widget build(BuildContext context) {
    final preview = controller.targets?.puntosAnadidosPreview;
    final text = preview != null
        ? 'Esta carta sumará +$preview puntos a tu clasificación de liga.'
        : 'Sumará puntos a tu clasificación de esta liga.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(text, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: _CompactActionButton(
            label: 'Usar carta',
            busy: controller.redeeming,
            onPressed: controller.redeeming
                ? null
                : () => _confirmAndRedeem(
                      sheetContext: context,
                      c: controller,
                      idLigaJugadorObjetivo: null,
                      confirmTitle: 'Usar carta',
                      confirmBody: text,
                    ),
          ),
        ),
      ],
    );
  }
}

// ─── SELL_PLAYER_BONUS ───

class _SellTargets extends StatelessWidget {
  const _SellTargets({required this.controller});
  final _RedeemSheetController controller;

  @override
  Widget build(BuildContext context) {
    final list = controller.targets?.objetivos ?? const [];
    if (list.isEmpty) {
      return _emptyTargets('No tienes jugadores disponibles para usar esta carta de venta.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Elige jugador para vender',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        ...list.map((p) => _SellPlayerCard(player: p, controller: controller)),
      ],
    );
  }
}

class _SellPlayerCard extends StatelessWidget {
  const _SellPlayerCard({required this.player, required this.controller});
  final RewardCardTargetPlayer player;
  final _RedeemSheetController controller;

  @override
  Widget build(BuildContext context) {
    final p = player;
    final hasEscudo = LeagueAssetUrls.buildBackendImageUrl(p.fotoEquipo) != null;
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      color: const Color(0xFF1A2233),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _playerAvatar(p),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          p.nombreJugador,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            height: 1.15,
                          ),
                        ),
                      ),
                      if (hasEscudo) ...[
                        const SizedBox(width: 4),
                        _teamBadge(p),
                      ],
                      const SizedBox(width: 4),
                      _positionChip(p.posicion),
                    ],
                  ),
                  if (_valoracionLinea(p.valoracionActual) != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        _valoracionLinea(p.valoracionActual)!,
                        style: const TextStyle(color: Colors.white54, fontSize: 10, height: 1.2),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Valor: ${_moneyFull(p.valorActual)}',
                      style: const TextStyle(color: Colors.white54, fontSize: 10, height: 1.2),
                    ),
                  ),
                  if (p.cantidadRecibidaPreview != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Recibirás: ${_moneyFull(p.cantidadRecibidaPreview)}',
                        style: const TextStyle(
                          color: Color(0xFF81C784),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ),
                  const SizedBox(height: 2),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _CompactActionButton(
                      label: 'Vender',
                      busy: controller.redeeming,
                      onPressed: controller.redeeming
                          ? null
                          : () => _confirmAndRedeem(
                                sheetContext: context,
                                c: controller,
                                idLigaJugadorObjetivo: p.idLigaJugador,
                                confirmTitle: 'Vender jugador',
                                confirmBody: 'Vas a vender a ${p.nombreJugador}.\n'
                                    'Recibirás ${_moneyFull(p.cantidadRecibidaPreview)}.\n'
                                    'Esta acción no se puede deshacer.',
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── DIRECT_CLAUSE ───

class _ClauseTargets extends StatefulWidget {
  const _ClauseTargets({required this.controller});
  final _RedeemSheetController controller;

  @override
  State<_ClauseTargets> createState() => _ClauseTargetsState();
}

class _ClauseTargetsState extends State<_ClauseTargets> {
  RewardParticipantTarget? _selected;

  @override
  Widget build(BuildContext context) {
    final parts = widget.controller.targets?.participantesObjetivo ?? const [];

    if (parts.isEmpty) {
      return _emptyTargets('No hay jugadores disponibles para esta cláusula.');
    }

    if (_selected != null) {
      return _ClauseParticipantSquad(
        participant: _selected!,
        controller: widget.controller,
        onBack: () => setState(() => _selected = null),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Elige participante rival',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ...parts.map((pt) => Card(
              color: const Color(0xFF1A2233),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: ListTile(
                onTap: () => setState(() => _selected = pt),
                title: Text(pt.nickname, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                subtitle: Text(
                  '${pt.jugadoresDisponibles} disponibles · ${pt.jugadoresBloqueados} bloqueados',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
              ),
            )),
      ],
    );
  }
}

class _ClauseParticipantSquad extends StatelessWidget {
  const _ClauseParticipantSquad({
    required this.participant,
    required this.controller,
    required this.onBack,
  });
  final RewardParticipantTarget participant;
  final _RedeemSheetController controller;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final ok = participant.objetivos;
    final blocked = participant.objetivosBloqueados;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Plantilla de ${participant.nickname}',
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ]),
        const SizedBox(height: 12),

        if (ok.isEmpty && blocked.isEmpty)
          _emptyTargets('Este participante no tiene jugadores disponibles.'),

        if (ok.isNotEmpty) ...[
          Text('Disponibles', style: theme.textTheme.labelLarge?.copyWith(color: const Color(0xFFFFD54F), fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ...ok.map((p) => _ClausePlayerCard(player: p, controller: controller)),
        ],

        if (blocked.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Bloqueados', style: theme.textTheme.labelLarge?.copyWith(color: Colors.white54, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ...blocked.map((p) => _ClauseBlockedCard(player: p)),
        ],
      ],
    );
  }
}

class _ClausePlayerCard extends StatelessWidget {
  const _ClausePlayerCard({required this.player, required this.controller});
  final RewardCardTargetPlayer player;
  final _RedeemSheetController controller;

  @override
  Widget build(BuildContext context) {
    final p = player;
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      color: const Color(0xFF1A2233),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _playerAvatar(p),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          p.nombreJugador,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            height: 1.15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      _positionChip(p.posicion),
                    ],
                  ),
                  if (p.nombreEquipo != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          _teamBadge(p),
                          if (p.fotoEquipo != null) const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              p.nombreEquipo!,
                              style: const TextStyle(color: Colors.white38, fontSize: 10),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_valoracionLinea(p.valoracionActual) != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        _valoracionLinea(p.valoracionActual)!,
                        style: const TextStyle(color: Colors.white54, fontSize: 10, height: 1.2),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Valor: ${_moneyFull(p.valorActual)}',
                      style: const TextStyle(color: Colors.white54, fontSize: 10, height: 1.2),
                    ),
                  ),
                  if (p.costeClausulaAtacante != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Pagarás: ${_moneyFull(p.costeClausulaAtacante)}',
                        style: const TextStyle(
                          color: Color(0xFFFFAB91),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ),
                  const SizedBox(height: 2),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _CompactActionButton(
                      label: 'Clausular',
                      busy: controller.redeeming,
                      onPressed: controller.redeeming
                          ? null
                          : () => _confirmAndRedeem(
                                sheetContext: context,
                                c: controller,
                                idLigaJugadorObjetivo: p.idLigaJugador,
                                confirmTitle: 'Ejecutar cláusula',
                                confirmBody: 'Vas a clausular a ${p.nombreJugador}.\n'
                                    'Pagarás ${_moneyFull(p.costeClausulaAtacante)}.\n'
                                    'Esta acción no se puede deshacer.',
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClauseBlockedCard extends StatelessWidget {
  const _ClauseBlockedCard({required this.player});
  final RewardCardTargetPlayer player;

  @override
  Widget build(BuildContext context) {
    final p = player;
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      color: const Color(0xFF151A28),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _playerAvatar(p),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          p.nombreJugador,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            height: 1.15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      _positionChip(p.posicion),
                    ],
                  ),
                  if (_blockedPlayerMessage(p).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        _blockedPlayerMessage(p),
                        style: const TextStyle(color: Color(0xFFFFAB91), fontSize: 10, height: 1.2),
                      ),
                    ),
                  if (p.costeClausulaAtacante != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Coste: ${_moneyFull(p.costeClausulaAtacante)}',
                        style: const TextStyle(color: Colors.white30, fontSize: 10),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── PROTECT_PLAYER ───

class _ProtectTargets extends StatelessWidget {
  const _ProtectTargets({required this.controller});
  final _RedeemSheetController controller;

  @override
  Widget build(BuildContext context) {
    final list = controller.targets?.objetivos ?? const [];
    if (list.isEmpty) {
      return _emptyTargets('No tienes jugadores disponibles para proteger.');
    }

    final card = controller.card;
    String? protLabel;
    try {
      final raw = card.parametrosJson;
      if (raw != null && raw.isNotEmpty) {
        final decoded = _jsonDecode(raw);
        if (decoded is Map) {
          final params = Map<String, dynamic>.from(decoded);
          if (params['seasonLong'] == true || params['temporadaCompleta'] == true) {
            protLabel = 'Esta carta protege hasta final de temporada';
          } else {
            final rounds = params['rounds'] ?? params['jornadas'];
            if (rounds != null) protLabel = 'Esta carta protege durante $rounds jornadas';
          }
        }
      }
    } catch (_) {}

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Elige jugador a proteger',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        if (protLabel != null) ...[
          const SizedBox(height: 2),
          Text(protLabel, style: const TextStyle(color: Color(0xFF81D4FA), fontSize: 11, height: 1.25)),
        ],
        const SizedBox(height: 6),
        ...list.map((p) => _ProtectPlayerCard(player: p, controller: controller)),
      ],
    );
  }
}

dynamic _jsonDecode(String s) {
  try {
    return json.decode(s);
  } catch (_) {
    return {};
  }
}

class _ProtectPlayerCard extends StatelessWidget {
  const _ProtectPlayerCard({required this.player, required this.controller});
  final RewardCardTargetPlayer player;
  final _RedeemSheetController controller;

  @override
  Widget build(BuildContext context) {
    final p = player;
    final rawMotivo = p.motivoBloqueo?.trim() ?? '';
    final bloqueo = _humanizeBlockedMotivo(p.motivoBloqueo);
    final bloqueoVisual =
        rawMotivo.isNotEmpty && bloqueo.isEmpty ? 'No disponible para proteger.' : bloqueo;
    final estadoProt = _proteccionTitularLinea(p);
    final puedeAccion = rawMotivo.isEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      color: const Color(0xFF1A2233),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: p.protegido == true
              ? const Color(0xFF81D4FA).withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _playerAvatar(p),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          p.nombreJugador,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            height: 1.15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      _positionChip(p.posicion),
                    ],
                  ),
                  if (p.nombreEquipo != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          _teamBadge(p),
                          if (p.fotoEquipo != null) const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              p.nombreEquipo!,
                              style: const TextStyle(color: Colors.white38, fontSize: 10),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_valoracionLinea(p.valoracionActual) != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        _valoracionLinea(p.valoracionActual)!,
                        style: const TextStyle(color: Colors.white54, fontSize: 10, height: 1.2),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Valor: ${_moneyFull(p.valorActual)}',
                      style: const TextStyle(color: Colors.white54, fontSize: 10, height: 1.2),
                    ),
                  ),
                  if (estadoProt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        estadoProt,
                        style: const TextStyle(color: Color(0xFF81D4FA), fontSize: 10, height: 1.2),
                      ),
                    ),
                  if (bloqueoVisual.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        bloqueoVisual,
                        style: const TextStyle(color: Color(0xFFFFAB91), fontSize: 10, height: 1.2),
                      ),
                    ),
                  const SizedBox(height: 2),
                  Align(
                    alignment: Alignment.centerRight,
                    child: puedeAccion
                        ? _CompactActionButton(
                            label: 'Proteger',
                            busy: controller.redeeming,
                            onPressed: controller.redeeming
                                ? null
                                : () => _confirmAndRedeem(
                                      sheetContext: context,
                                      c: controller,
                                      idLigaJugadorObjetivo: p.idLigaJugador,
                                      confirmTitle: 'Aplicar protección',
                                      confirmBody: 'Se aplicará protección sobre ${p.nombreJugador}.\n'
                                          'Esta acción no se puede deshacer.',
                                    ),
                          )
                        : Text(
                            'No disponible',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white38),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── TEMPORARY_VALUE_RECOVERY ───

class _RecoveryTargets extends StatelessWidget {
  const _RecoveryTargets({required this.controller});
  final _RedeemSheetController controller;

  @override
  Widget build(BuildContext context) {
    final list = controller.targets?.objetivos ?? const [];
    if (list.isEmpty) {
      return _emptyTargets('No tienes jugadores bajando de valor para usar esta carta.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Elige jugador que esté bajando de valor',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        ...list.map((p) => _RecoveryPlayerCard(player: p, controller: controller)),
      ],
    );
  }
}

class _RecoveryPlayerCard extends StatelessWidget {
  const _RecoveryPlayerCard({required this.player, required this.controller});
  final RewardCardTargetPlayer player;
  final _RedeemSheetController controller;

  @override
  Widget build(BuildContext context) {
    final p = player;
    final nExp = p.numeroJornadaExpiracionPreview;
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      color: const Color(0xFF1A2233),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _playerAvatar(p),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          p.nombreJugador,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            height: 1.15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      _positionChip(p.posicion),
                    ],
                  ),
                  if (p.nombreEquipo != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          _teamBadge(p),
                          if (p.fotoEquipo != null) const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              p.nombreEquipo!,
                              style: const TextStyle(color: Colors.white38, fontSize: 10),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_valoracionLinea(p.valoracionActual) != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        _valoracionLinea(p.valoracionActual)!,
                        style: const TextStyle(color: Colors.white54, fontSize: 10, height: 1.2),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Valor actual: ${_moneyFull(p.valorActual)}',
                      style: const TextStyle(color: Colors.white54, fontSize: 10, height: 1.2),
                    ),
                  ),
                  if (_recoveryBajandoLinea(p) != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        _recoveryBajandoLinea(p)!,
                        style: const TextStyle(color: Colors.white54, fontSize: 10, height: 1.2),
                      ),
                    ),
                  if (_recoverySubeLinea(p) != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        _recoverySubeLinea(p)!,
                        style: const TextStyle(
                          color: Color(0xFF81C784),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ),
                  if (nExp != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Expira en la jornada $nExp',
                        style: const TextStyle(color: Colors.white54, fontSize: 10, height: 1.2),
                      ),
                    ),
                  const SizedBox(height: 2),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _CompactActionButton(
                      label: 'Aplicar',
                      busy: controller.redeeming,
                      onPressed: controller.redeeming
                          ? null
                          : () => _confirmAndRedeem(
                                sheetContext: context,
                                c: controller,
                                idLigaJugadorObjetivo: p.idLigaJugador,
                                confirmTitle: 'Aplicar recuperación',
                                confirmBody: 'Se aplicará recuperación temporal de valor a ${p.nombreJugador}.\n'
                                    'Esta acción no se puede deshacer.',
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

