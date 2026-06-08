import 'package:eternal_xi/app/localization/league_l10n.dart';
import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/core/utils/league_money_format.dart';
import 'package:eternal_xi/data/models/league_offer_item.dart';
import 'package:eternal_xi/data/models/league_squad_player.dart';
import 'package:eternal_xi/data/services/leagues_api_service.dart';
import 'package:eternal_xi/features/leagues/utils/league_shell_money_refresh.dart';
import 'package:eternal_xi/features/leagues/widgets/league_player_offer_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<LeagueOfferItem?> findPendingSentOfferForPlayer({
  required LeaguesApiService api,
  required int idLiga,
  required int idUsuario,
  required int idLigaJugador,
}) async {
  final sent = await api.getSentOffers(idLiga: idLiga, idUsuario: idUsuario);
  for (final offer in sent) {
    if (offer.pendiente && offer.idLigaJugador == idLigaJugador) {
      return offer;
    }
  }
  return null;
}

/// Abre la hoja de oferta. Si ya hay una pendiente, avisa y solo permite actualizar o anular.
Future<void> openLeaguePlayerOfferFlow({
  required BuildContext context,
  required int idLiga,
  required int idUsuario,
  required LeagueSquadPlayer player,
  int? miDinero,
  Future<void> Function()? onAfterSuccess,
}) async {
  if (player.idUsuarioDueno == idUsuario) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.leagueL10n.cannotOfferOwnSnack)),
    );
    return;
  }

  final api = context.read<LeaguesApiService>();
  final pending = await findPendingSentOfferForPlayer(
    api: api,
    idLiga: idLiga,
    idUsuario: idUsuario,
    idLigaJugador: player.idLigaJugador,
  );

  if (!context.mounted) {
    return;
  }

  final ll = context.leagueL10n;
  int? idOferta;
  int? cantidadActual;

  if (pending != null) {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(ll.activeOfferExistsTitle),
        content: Text(
          ll.activeOfferExistsBody(
            LeagueMoneyFormat.money(pending.cantidad.toDouble()),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(ll.updateOffer),
          ),
        ],
      ),
    );
    if (proceed != true || !context.mounted) {
      return;
    }
    idOferta = pending.idOferta;
    cantidadActual = pending.cantidad;
  }

  await LeaguePlayerOfferSheet.show(
    context: context,
    idLiga: idLiga,
    idUsuario: idUsuario,
    player: player,
    miDinero: miDinero,
    idOferta: idOferta,
    cantidadActual: cantidadActual,
    onAfterSuccess: () async {
      await reloadLeagueShellAfterMoney(context);
      await onAfterSuccess?.call();
    },
  );
}
