import 'dart:convert';

import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/localization/rewards_l10n.dart';
import 'package:eternal_xi/features/rewards/data/models/reward_card_model.dart';
import 'package:eternal_xi/features/rewards/data/models/reward_card_target_model.dart';
import 'package:eternal_xi/features/rewards/data/models/reward_redeem_result_model.dart';
import 'package:eternal_xi/features/rewards/data/services/rewards_api_service.dart';
import 'package:eternal_xi/features/rewards/presentation/controllers/rewards_controller.dart';
import 'package:eternal_xi/features/rewards/presentation/theme/reward_sheet_style.dart';
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
  final sheetBackground = RewardSheetStyle.of(context).sheetBackground;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: sheetBackground,
    builder: (ctx) {
      return Theme(
        data: rewardSheetTheme(ctx),
        child: MultiProvider(
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
        ),
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
    final rl10n = context.rewardsL10n;
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
                Text(c.error!, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(rl10n.close),
                ),
              ],
            );
          }
          final tipo = c.card.tipoEfecto.trim().toUpperCase();
          return ListView(
            controller: scroll,
            children: [
              Text(
                rl10n.cardDisplayName(c.card),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                rl10n.cardDisplayDescription(c.card),
                style: Theme.of(context).textTheme.bodyMedium,
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
              else if (c.card.isValueBoost)
                _ValueBoostTargets(controller: c)
              else
                Text(
                  rl10n.unsupportedCardTypeWithCode(tipo),
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
          child: Text(ctx.l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(ctx.rewardsL10n.confirm),
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
    final rl10n = sheetContext.rewardsL10n;
    final msg = rewards.errorMessage ?? rl10n.actionFailed;
    ScaffoldMessenger.of(sheetContext).showSnackBar(SnackBar(content: Text(msg)));
  }
}

void _showRedeemSuccess(BuildContext context, RewardRedeemResultModel r) {
  final rl10n = context.rewardsL10n;
  final success = rl10n.redeemSuccessMessage(r);

  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(success.title),
      content: Text(success.lines.join('\n')),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(rl10n.ok),
        ),
      ],
    ),
  );
}

Widget _emptyTargets(BuildContext context, String message) {
  final style = RewardSheetStyle.of(context);
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Column(
      children: [
        Icon(Icons.search_off_rounded, size: 48, color: style.faint),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: style.muted, height: 1.35),
        ),
      ],
    ),
  );
}

Widget _playerAvatar(BuildContext context, RewardCardTargetPlayer p) {
  final style = RewardSheetStyle.of(context);
  final url = LeagueAssetUrls.buildBackendImageUrl(p.fotoJugador);
  if (url != null) {
    return CircleAvatar(
      radius: 20,
      backgroundImage: NetworkImage(url),
      backgroundColor: style.avatarBackground,
      onBackgroundImageError: (_, _) {},
    );
  }
  return CircleAvatar(
    radius: 20,
    backgroundColor: style.avatarBackground,
    child: Icon(Icons.person, color: style.faint, size: 20),
  );
}

Widget _teamBadge(BuildContext context, RewardCardTargetPlayer p) {
  final style = RewardSheetStyle.of(context);
  final url = LeagueAssetUrls.resolveTeamBadgeUrl(
    idEquipo: p.idEquipo ?? 0,
    rawFoto: p.fotoEquipo,
  );
  if (url != null) {
    return Image.network(
      url,
      width: 16,
      height: 16,
      errorBuilder: (_, _, _) =>
          Icon(Icons.shield_outlined, size: 16, color: style.badgeIcon),
    );
  }
  return const SizedBox.shrink();
}

Widget _positionChip(BuildContext context, String? pos) {
  if (pos == null || pos.isEmpty) return const SizedBox.shrink();
  final style = RewardSheetStyle.of(context);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(4),
      color: style.chipFill,
    ),
    child: Text(pos, style: style.chipTextStyle()),
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
    final rl10n = context.rewardsL10n;
    final preview = controller.targets?.puntosAnadidosPreview;
    final text = preview != null
        ? rl10n.addPointsPreview(preview)
        : rl10n.addPointsGeneric;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(text, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: _CompactActionButton(
            label: rl10n.useCard,
            busy: controller.redeeming,
            onPressed: controller.redeeming
                ? null
                : () => _confirmAndRedeem(
                      sheetContext: context,
                      c: controller,
                      idLigaJugadorObjetivo: null,
                      confirmTitle: rl10n.useCard,
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
    final rl10n = context.rewardsL10n;
    final list = controller.targets?.objetivos ?? const [];
    if (list.isEmpty) {
      return _emptyTargets(context, rl10n.noSellTargets);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          rl10n.choosePlayerToSell,
          style: Theme.of(context).textTheme.titleMedium,
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
    final rl10n = context.rewardsL10n;
    final p = player;
    final hasEscudo = LeagueAssetUrls.buildBackendImageUrl(p.fotoEquipo) != null;
    final style = RewardSheetStyle.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _playerAvatar(context, p),
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
                          style: style.playerNameStyle(),
                        ),
                      ),
                      if (hasEscudo) ...[
                        const SizedBox(width: 4),
                        _teamBadge(context, p),
                      ],
                      const SizedBox(width: 4),
                      _positionChip(context, p.posicion),
                    ],
                  ),
                  if (p.valoracionActual != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        rl10n.valuation(p.valoracionActual!.round()),
                        style: style.metaStyle(),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      rl10n.valueLabel(_moneyFull(p.valorActual)),
                      style: style.metaStyle(),
                    ),
                  ),
                  if (p.cantidadRecibidaPreview != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        rl10n.youWillReceive(_moneyFull(p.cantidadRecibidaPreview)),
                        style: TextStyle(
                          color: style.success,
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
                      label: rl10n.sell,
                      busy: controller.redeeming,
                      onPressed: controller.redeeming
                          ? null
                          : () => _confirmAndRedeem(
                                sheetContext: context,
                                c: controller,
                                idLigaJugadorObjetivo: p.idLigaJugador,
                                confirmTitle: rl10n.sellPlayerTitle,
                                confirmBody: rl10n.sellPlayerConfirm(
                                  p.nombreJugador,
                                  _moneyFull(p.cantidadRecibidaPreview),
                                ),
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
    final rl10n = context.rewardsL10n;
    final parts = widget.controller.targets?.participantesObjetivo ?? const [];

    if (parts.isEmpty) {
      return _emptyTargets(context, rl10n.noClauseTargets);
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
          rl10n.chooseRivalParticipant,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...parts.map((pt) => Card(
              child: ListTile(
                onTap: () => setState(() => _selected = pt),
                title: Text(
                  pt.nickname,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                subtitle: Text(
                  rl10n.participantsAvailableBlocked(
                    pt.jugadoresDisponibles,
                    pt.jugadoresBloqueados,
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: RewardSheetStyle.of(context).faint,
                ),
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
    final rl10n = context.rewardsL10n;
    final ok = participant.objetivos;
    final blocked = participant.objetivosBloqueados;
    final theme = Theme.of(context);
    final style = RewardSheetStyle.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(Icons.arrow_back_rounded, color: style.subtitle, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              rl10n.squadOf(participant.nickname),
              style: theme.textTheme.titleMedium,
            ),
          ),
        ]),
        const SizedBox(height: 12),

        if (ok.isEmpty && blocked.isEmpty)
          _emptyTargets(context, rl10n.noPlayersForParticipant),

        if (ok.isNotEmpty) ...[
          Text(
            rl10n.availablePlayers,
            style: theme.textTheme.labelLarge?.copyWith(
              color: style.accentLabel,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          ...ok.map((p) => _ClausePlayerCard(player: p, controller: controller)),
        ],

        if (blocked.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            rl10n.blockedPlayers,
            style: theme.textTheme.labelLarge?.copyWith(
              color: style.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
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
    final rl10n = context.rewardsL10n;
    final p = player;
    final style = RewardSheetStyle.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _playerAvatar(context, p),
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
                          style: style.playerNameStyle(),
                        ),
                      ),
                      const SizedBox(width: 4),
                      _positionChip(context, p.posicion),
                    ],
                  ),
                  if (p.nombreEquipo != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          _teamBadge(context, p),
                          if (p.fotoEquipo != null) const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              p.nombreEquipo!,
                              style: TextStyle(color: style.faint, fontSize: 10),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (p.valoracionActual != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        rl10n.valuation(p.valoracionActual!.round()),
                        style: style.metaStyle(),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      rl10n.valueLabel(_moneyFull(p.valorActual)),
                      style: style.metaStyle(),
                    ),
                  ),
                  if (p.costeClausulaAtacante != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        rl10n.youWillPay(_moneyFull(p.costeClausulaAtacante)),
                        style: TextStyle(
                          color: style.warning,
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
                      label: rl10n.clause,
                      busy: controller.redeeming,
                      onPressed: controller.redeeming
                          ? null
                          : () => _confirmAndRedeem(
                                sheetContext: context,
                                c: controller,
                                idLigaJugadorObjetivo: p.idLigaJugador,
                                confirmTitle: rl10n.executeClauseTitle,
                                confirmBody: rl10n.executeClauseConfirm(
                                  p.nombreJugador,
                                  _moneyFull(p.costeClausulaAtacante),
                                ),
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
    final rl10n = context.rewardsL10n;
    final p = player;
    final style = RewardSheetStyle.of(context);
    return Card(
      color: style.cardBlocked,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _playerAvatar(context, p),
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
                          style: TextStyle(
                            color: style.faint,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            height: 1.15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      _positionChip(context, p.posicion),
                    ],
                  ),
                  if (rl10n.blockedPlayerMessage(p).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        rl10n.blockedPlayerMessage(p),
                        style: TextStyle(color: style.warning, fontSize: 10, height: 1.2),
                      ),
                    ),
                  if (p.costeClausulaAtacante != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        rl10n.costLabel(_moneyFull(p.costeClausulaAtacante)),
                        style: TextStyle(color: style.veryFaint, fontSize: 10),
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
    final rl10n = context.rewardsL10n;
    final list = controller.targets?.objetivos ?? const [];
    if (list.isEmpty) {
      return _emptyTargets(context, rl10n.noProtectTargets);
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
            protLabel = rl10n.protectUntilSeasonEnd;
          } else {
            final rounds = params['rounds'] ?? params['jornadas'];
            if (rounds != null) {
              final n = rounds is int ? rounds : int.tryParse(rounds.toString());
              if (n != null) protLabel = rl10n.protectForRounds(n);
            }
          }
        }
      }
    } catch (_) {}

    final style = RewardSheetStyle.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          rl10n.choosePlayerToProtect,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (protLabel != null) ...[
          const SizedBox(height: 2),
          Text(
            protLabel,
            style: TextStyle(color: style.info, fontSize: 11, height: 1.25),
          ),
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
    final rl10n = context.rewardsL10n;
    final p = player;
    final rawMotivo = p.motivoBloqueo?.trim() ?? '';
    final bloqueo = rl10n.humanizeBlockedReason(p.motivoBloqueo);
    final bloqueoVisual =
        rawMotivo.isNotEmpty && bloqueo.isEmpty ? rl10n.notAvailableToProtect : bloqueo;
    final estadoProt = rl10n.protectionOwnerLine(p);
    final puedeAccion = rawMotivo.isEmpty;
    final style = RewardSheetStyle.of(context);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: p.protegido == true
              ? style.info.withValues(alpha: 0.35)
              : style.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _playerAvatar(context, p),
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
                          style: style.playerNameStyle(),
                        ),
                      ),
                      const SizedBox(width: 4),
                      _positionChip(context, p.posicion),
                    ],
                  ),
                  if (p.nombreEquipo != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          _teamBadge(context, p),
                          if (p.fotoEquipo != null) const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              p.nombreEquipo!,
                              style: TextStyle(color: style.faint, fontSize: 10),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (p.valoracionActual != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        rl10n.valuation(p.valoracionActual!.round()),
                        style: style.metaStyle(),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      rl10n.valueLabel(_moneyFull(p.valorActual)),
                      style: style.metaStyle(),
                    ),
                  ),
                  if (estadoProt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        estadoProt,
                        style: TextStyle(color: style.info, fontSize: 10, height: 1.2),
                      ),
                    ),
                  if (bloqueoVisual.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        bloqueoVisual,
                        style: TextStyle(color: style.warning, fontSize: 10, height: 1.2),
                      ),
                    ),
                  const SizedBox(height: 2),
                  Align(
                    alignment: Alignment.centerRight,
                    child: puedeAccion
                        ? _CompactActionButton(
                            label: rl10n.protect,
                            busy: controller.redeeming,
                            onPressed: controller.redeeming
                                ? null
                                : () => _confirmAndRedeem(
                                      sheetContext: context,
                                      c: controller,
                                      idLigaJugadorObjetivo: p.idLigaJugador,
                                      confirmTitle: rl10n.applyProtectionTitle,
                                      confirmBody: rl10n.applyProtectionConfirm(p.nombreJugador),
                                    ),
                          )
                        : Text(
                            rl10n.notAvailable,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: style.faint),
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

// ─── PLAYER_VALUE_BOOST (antes recuperación temporal) ───

class _ValueBoostTargets extends StatelessWidget {
  const _ValueBoostTargets({required this.controller});
  final _RedeemSheetController controller;

  @override
  Widget build(BuildContext context) {
    final rl10n = context.rewardsL10n;
    final list = controller.targets?.objetivos ?? const [];
    if (list.isEmpty) {
      return _emptyTargets(context, rl10n.noValueBoostTargets);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          rl10n.chooseValueBoostPlayer,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        ...list.map((p) => _ValueBoostPlayerCard(player: p, controller: controller)),
      ],
    );
  }
}

class _ValueBoostPlayerCard extends StatelessWidget {
  const _ValueBoostPlayerCard({required this.player, required this.controller});
  final RewardCardTargetPlayer player;
  final _RedeemSheetController controller;

  @override
  Widget build(BuildContext context) {
    final rl10n = context.rewardsL10n;
    final p = player;
    final pctLine = rl10n.valueBoostPercentLine(p);
    final newValueLine = rl10n.valueBoostNewValueLine(p);
    final style = RewardSheetStyle.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _playerAvatar(context, p),
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
                          style: style.playerNameStyle(),
                        ),
                      ),
                      const SizedBox(width: 4),
                      _positionChip(context, p.posicion),
                    ],
                  ),
                  if (p.nombreEquipo != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          _teamBadge(context, p),
                          if (p.fotoEquipo != null) const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              p.nombreEquipo!,
                              style: TextStyle(color: style.faint, fontSize: 10),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (p.valoracionActual != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        rl10n.valuation(p.valoracionActual!.round()),
                        style: style.metaStyle(),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      rl10n.currentValueLabel(_moneyFull(p.valorActual)),
                      style: style.metaStyle(),
                    ),
                  ),
                  if (pctLine != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        pctLine,
                        style: style.metaStyle(),
                      ),
                    ),
                  if (newValueLine != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        newValueLine,
                        style: TextStyle(
                          color: style.success,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ),
                  const SizedBox(height: 2),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _CompactActionButton(
                      label: rl10n.apply,
                      busy: controller.redeeming,
                      onPressed: controller.redeeming
                          ? null
                          : () => _confirmAndRedeem(
                                sheetContext: context,
                                c: controller,
                                idLigaJugadorObjetivo: p.idLigaJugador,
                                confirmTitle: rl10n.applyValueBoostTitle,
                                confirmBody: rl10n.applyValueBoostConfirm(p.nombreJugador),
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

