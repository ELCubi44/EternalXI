import 'package:eternal_xi/app/localization/league_l10n.dart';
import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/core/utils/league_asset_urls.dart';
import 'package:eternal_xi/core/utils/league_money_format.dart';
import 'package:eternal_xi/core/network/api_exception.dart';
import 'package:eternal_xi/data/models/league_offer_item.dart';
import 'package:eternal_xi/data/models/league_player_detail.dart';
import 'package:eternal_xi/data/models/league_unavailable_player.dart';
import 'package:eternal_xi/data/models/league_squad_player.dart';
import 'package:eternal_xi/data/services/leagues_api_service.dart';
import 'package:eternal_xi/features/leagues/navigation/league_inner_navigation.dart';
import 'package:eternal_xi/features/leagues/shell/league_shell_data.dart';
import 'package:eternal_xi/features/leagues/utils/league_display_strings.dart';
import 'package:eternal_xi/features/leagues/utils/league_player_availability_icons.dart';
import 'package:eternal_xi/features/leagues/utils/league_player_estado_titularidad.dart';
import 'package:eternal_xi/features/leagues/utils/league_player_visible_estado.dart';
import 'package:eternal_xi/features/leagues/utils/league_starter_probability_ui.dart';
import 'package:eternal_xi/features/leagues/widgets/league_player_avatar.dart';
import 'package:eternal_xi/features/leagues/widgets/league_player_offer_sheet.dart';
import 'package:eternal_xi/features/leagues/widgets/league_player_profile_rounds_section.dart';
import 'package:eternal_xi/features/leagues/widgets/league_team_logo.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Perfil de jugador en contexto de liga, cargando detalle real desde backend.
class LeaguePlayerProfileScreen extends StatefulWidget {
  const LeaguePlayerProfileScreen({
    super.key,
    required this.player,
    this.leagueId,
    this.idLigaJugador,
    this.idUsuario,
    this.idJornada,
    this.isOwnPlayerHint,
    this.isMarketPlayerHint,
    this.isNightMarketPlayerHint,
  });

  final LeagueSquadPlayer player;
  final int? leagueId;
  final int? idLigaJugador;
  final int? idUsuario;

  /// Jornada para la que el backend calcula titularidad/probabilidad (opcional).
  final int? idJornada;
  final bool? isOwnPlayerHint;
  final bool? isMarketPlayerHint;
  final bool? isNightMarketPlayerHint;

  @override
  State<LeaguePlayerProfileScreen> createState() =>
      _LeaguePlayerProfileScreenState();
}

class _LeaguePlayerProfileScreenState extends State<LeaguePlayerProfileScreen> {
  LeaguePlayerDetail? _detail;
  bool _loading = false;
  String? _error;
  bool _loadStarted = false;
  Object? _lastShellDetailRef;
  List<LeagueOfferItem> _receivedOffersForPlayer = const [];
  LeagueUnavailablePlayer? _unavailableInfo;

  /// Último `idJornada` enviado en GET `/players/{id}` (null = sin query param).
  /// Solo [widget.idJornada] (ruta); los chips de historial no disparan refetch.
  int? _ultimaPeticionDetalleIdJornada;

  int? _resolvedLeagueId() {
    final local = widget.leagueId;
    if (local != null && local > 0) {
      return local;
    }
    return LeagueShellData.maybeOf(context)?.leagueId;
  }

  int? _resolvedUsuarioId() {
    final local = widget.idUsuario;
    if (local != null && local > 0) {
      return local;
    }
    return LeagueShellData.maybeOf(context)?.idUsuario;
  }

  int _resolvedIdLigaJugador() {
    final local = widget.idLigaJugador;
    if (local != null && local > 0) {
      return local;
    }
    return widget.player.idLigaJugador;
  }

  /// `idJornada` en query del detalle: solo la de navegación (probabilidadTitular / motivo…).
  int? _idJornadaQueryProbTitular() {
    final w = widget.idJornada;
    if (w != null && w > 0) {
      return w;
    }
    return null;
  }

  int? _probTitularParaBloqueUi() {
    final d = _detail;
    if (d?.probabilidadTitular != null) {
      return d!.probabilidadTitular;
    }
    return widget.player.probabilidadTitular;
  }

  String? _motivoTitularParaBloqueUi() {
    final d = _detail;
    if (d?.motivoTitularidad != null && d!.motivoTitularidad!.trim().isNotEmpty) {
      return d.motivoTitularidad!.trim();
    }
    return widget.player.motivoTitularidad?.trim();
  }

  ({
    int ownerId,
    bool isOwn,
    bool isMarket,
    bool isInNightMarketToday,
    bool ownershipResolved,
  })
  _resolveOwnershipContext({LeaguePlayerDetail? detail, int? idUsuario}) {
    if (detail == null) {
      return (
        ownerId: 0,
        isOwn: false,
        isMarket: false,
        isInNightMarketToday: false,
        ownershipResolved: false,
      );
    }
    final ownerId = detail.idUsuarioDueno;
    final isOwn =
        idUsuario != null &&
        idUsuario > 0 &&
        ownerId > 0 &&
        ownerId == idUsuario;
    final isMarket = detail.esMercado || detail.enPoolMercado;
    final isInNightMarketToday = detail.enMercadoHoy;
    final ownershipResolved = ownerId > 0 || isMarket;
    if (kDebugMode) {
      debugPrint(
        '[player-detail][resolve] idLigaJugador=${_resolvedIdLigaJugador()} detailReady=true owner=$ownerId esMercado=${detail.esMercado} enPoolMercado=${detail.enPoolMercado} ownershipResolved=$ownershipResolved isOwn=$isOwn isMarket=$isMarket',
      );
    }

    return (
      ownerId: ownerId,
      isOwn: isOwn,
      isMarket: isMarket,
      isInNightMarketToday: isInNightMarketToday,
      ownershipResolved: ownershipResolved,
    );
  }

  void _openCatalogTeamSquadFromProfile({
    required int idEquipo,
    required String nombreEquipo,
    required String? fotoEquipoUrl,
  }) {
    if (idEquipo <= 0 || !mounted) {
      return;
    }
    LeagueInnerNavigation.openCatalogTeamSquad(
      context: context,
      idEquipo: idEquipo,
      nombreEquipo: nombreEquipo.trim().isEmpty ? null : nombreEquipo.trim(),
      fotoEquipo: fotoEquipoUrl,
      idLiga: _resolvedLeagueId(),
      idUsuario: _resolvedUsuarioId(),
    );
  }

  Future<void> _loadDetail() async {
    final leagueId = _resolvedLeagueId();
    final idUsuario = _resolvedUsuarioId();
    final idLigaJugador = _resolvedIdLigaJugador();
    final idJornadaApi = _idJornadaQueryProbTitular();

    if (leagueId == null ||
        leagueId <= 0 ||
        idUsuario == null ||
        idUsuario <= 0 ||
        idLigaJugador <= 0) {
      setState(() {
        _error =
            'No se pudo resolver liga, usuario o jugador para cargar el detalle.';
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = context.read<LeaguesApiService>();
      final detail = await api.getLeaguePlayerDetail(
        idLiga: leagueId,
        idLigaJugador: idLigaJugador,
        idUsuario: idUsuario,
        idJornada: idJornadaApi,
      );
      if (!mounted) {
        return;
      }
      if (kDebugMode) {
        debugPrint('[starter-prob][player-detail-parsed]');
        debugPrint('detail.probabilidadTitular=${detail.probabilidadTitular}');
        debugPrint(
          'detail.motivoTitularidad="${detail.motivoTitularidad ?? ''}"',
        );
      }
      final resolvedUserId = _resolvedUsuarioId();
      final ownership = _resolveOwnershipContext(
        detail: detail,
        idUsuario: resolvedUserId,
      );
      if (kDebugMode) {
        debugPrint(
          '[player-detail][detail-load] idLigaJugador=$idLigaJugador owner=${detail.idUsuarioDueno} esMercado=${detail.esMercado} enPoolMercado=${detail.enPoolMercado}',
        );
      }
      List<LeagueOfferItem> playerOffers = const [];
      LeagueUnavailablePlayer? unavailableInfo;
      if (ownership.isOwn && resolvedUserId != null && resolvedUserId > 0) {
        final received = await api.getReceivedOffers(
          idLiga: leagueId,
          idUsuario: resolvedUserId,
        );
        final idLigaJugador = _resolvedIdLigaJugador();
        playerOffers = received
            .where((o) => o.idLigaJugador == idLigaJugador && o.pendiente)
            .toList();
      }
      try {
        final unavailable = await api.fetchUnavailablePlayers(
          leagueId: leagueId,
          userId: idUsuario,
        );
        final playerId = _resolvedIdLigaJugador();
        unavailableInfo = unavailable.firstWhere(
          (u) => u.idLigaJugador == playerId,
          orElse: () => const LeagueUnavailablePlayer(
            idLigaJugador: 0,
            idJugador: 0,
            nombre: '',
            pila: null,
            fotoJugador: null,
            posicion: '',
            idEquipo: 0,
            nombreEquipo: '',
            estado: '',
            lesionadoHasta: null,
            sancionadoHasta: null,
            disponibleDesde: null,
            idJornadaDisponible: null,
            numeroJornadaDisponible: null,
            textoDisponibilidad: '',
          ),
        );
        if (unavailableInfo.idLigaJugador <= 0) {
          unavailableInfo = null;
        }
      } catch (_) {
        // El detalle del jugador no debe fallar si esta consulta adicional falla.
      }
      setState(() {
        _detail = detail;
        _receivedOffersForPlayer = playerOffers;
        _unavailableInfo = unavailableInfo;
        _loading = false;
        _ultimaPeticionDetalleIdJornada =
            idJornadaApi != null && idJornadaApi > 0 ? idJornadaApi : null;
      });
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.message;
        _receivedOffersForPlayer = const [];
        _unavailableInfo = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _receivedOffersForPlayer = const [];
        _unavailableInfo = null;
        _loading = false;
      });
    }
  }

  String _formatDateShort(DateTime? d) {
    if (d == null) {
      return 'Sin fecha disponible';
    }
    final local = d.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  String _availabilityText(LeagueL10n ll) {
    final info = _unavailableInfo;
    if (info != null) {
      final txt = info.textoDisponibilidad.trim();
      if (txt.isNotEmpty) {
        return txt;
      }
      if (info.numeroJornadaDisponible != null &&
          info.numeroJornadaDisponible! > 0) {
        return ll.availableForMatchday(info.numeroJornadaDisponible!);
      }
      if (info.disponibleDesde != null) {
        return ll.availableOn(_formatDateShort(info.disponibleDesde));
      }
      return info.isSuspended
          ? ll.noMatchdayAvailable
          : ll.noReturnDate;
    }
    final norm = leaguePlayerEstadoNormalized(_effectiveEstado(_detail));
    if (norm == 'SANCIONADO') {
      return ll.noMatchdayAvailable;
    }
    if (norm == 'LESIONADO') {
      return ll.noReturnDate;
    }
    return '';
  }

  bool get _isInjuredState =>
      (_unavailableInfo?.isInjured ?? false) ||
      leaguePlayerEstadoIsLesionado(_effectiveEstado(_detail));

  bool get _isSuspendedState =>
      (_unavailableInfo?.isSuspended ?? false) ||
      leaguePlayerEstadoIsSancionado(_effectiveEstado(_detail));

  Future<void> _openManageOffersSheet() async {
    if (_receivedOffersForPlayer.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.leagueL10n.noOffersPendingSnack)),
        );
      }
      return;
    }
    final leagueId = _resolvedLeagueId();
    final idUsuario = _resolvedUsuarioId();
    if (leagueId == null || idUsuario == null || idUsuario <= 0) {
      return;
    }
    final reloadShell = LeagueShellData.maybeOf(context)?.reload;
    String? actionMessage;
    final accepted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => _PlayerOffersManagementSheet(
        offers: _receivedOffersForPlayer,
        onAccept: (idOferta) async {
          final api = context.read<LeaguesApiService>();
          final r = await api.acceptOffer(
            idLiga: leagueId,
            idOferta: idOferta,
            idUsuario: idUsuario,
          );
          await Future.wait([
            _loadDetail(),
            reloadShell?.call() ?? Future.value(),
          ]);
          actionMessage = r.message;
        },
        onReject: (idOferta) async {
          final api = context.read<LeaguesApiService>();
          final r = await api.rejectOffer(
            idLiga: leagueId,
            idOferta: idOferta,
            idUsuario: idUsuario,
          );
          await Future.wait([
            _loadDetail(),
            reloadShell?.call() ?? Future.value(),
          ]);
          actionMessage = r.message;
        },
      ),
    );
    if (!mounted) {
      return;
    }
    if (accepted == null) {
      return;
    }
    if (accepted) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      final shell = LeagueShellData.maybeOf(context);
      shell?.selectTab(2);
      Navigator.of(context).maybePop();
      messenger?.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: Theme.of(context).colorScheme.onInverseSurface,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  actionMessage?.trim().isNotEmpty == true
                      ? actionMessage!
                      : context.leagueL10n.offerAccepted,
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          actionMessage?.trim().isNotEmpty == true
              ? actionMessage!
              : context.leagueL10n.offerRejected,
        ),
      ),
    );
  }

  Future<void> _openOfferSheet() async {
    final leagueId = _resolvedLeagueId();
    final idUsuario = _resolvedUsuarioId();
    if (leagueId == null ||
        leagueId <= 0 ||
        idUsuario == null ||
        idUsuario <= 0) {
      return;
    }
    final ownership = _resolveOwnershipContext(
      detail: _detail,
      idUsuario: idUsuario,
    );
    if (_detail == null || !ownership.ownershipResolved) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.leagueL10n.resolvingPlayerStatus)),
        );
      }
      return;
    }
    final isOwnPlayer = ownership.isOwn;
    if (isOwnPlayer) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.leagueL10n.cannotOfferOwnPlayer)),
        );
      }
      return;
    }
    await LeaguePlayerOfferSheet.show(
      context: context,
      idLiga: leagueId,
      idUsuario: idUsuario,
      player: _detail?.toSquadPlayer(fallback: widget.player) ?? widget.player,
      miDinero: LeagueShellData.maybeOf(context)?.detail?.miDinero.floor(),
      onAfterSuccess: () async {
        final shell = LeagueShellData.maybeOf(context);
        await Future.wait([_loadDetail(), shell?.reload() ?? Future.value()]);
      },
    );
  }

  Future<void> _sellPlayer(double valorActual) async {
    final leagueId = _resolvedLeagueId();
    final idUsuario = _resolvedUsuarioId();
    if (leagueId == null ||
        leagueId <= 0 ||
        idUsuario == null ||
        idUsuario <= 0) {
      return;
    }
    final expected = (valorActual * 0.9).round();
    final ll = context.leagueL10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(ll.sellPlayer),
        content: Text(
          ll.sellInstantBody(LeagueMoneyFormat.euros(expected.toDouble())),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(c.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(ll.sell),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }
    setState(() => _loading = true);
    try {
      final api = context.read<LeaguesApiService>();
      final shell = LeagueShellData.maybeOf(context);
      final result = await api.sellLeaguePlayer(
        idLiga: leagueId,
        idLigaJugador: _resolvedIdLigaJugador(),
        idUsuario: idUsuario,
      );
      await Future.wait([_loadDetail(), shell?.reload() ?? Future.value()]);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.leagueL10n.saleCompleted(
              LeagueMoneyFormat.euros(result.cantidadVenta.toDouble()),
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
      setState(() => _loading = false);
    }
  }

  Future<void> _buyPlayerNow(double valorActual) async {
    final leagueId = _resolvedLeagueId();
    final idUsuario = _resolvedUsuarioId();
    final idLigaJugador = _resolvedIdLigaJugador();
    if (leagueId == null ||
        leagueId <= 0 ||
        idUsuario == null ||
        idUsuario <= 0 ||
        idLigaJugador <= 0) {
      return;
    }
    final expected = (valorActual * 2).round();
    final ll = context.leagueL10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(ll.buyPlayer),
        content: Text(
          ll.buyDirectBody(LeagueMoneyFormat.euros(expected.toDouble())),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(c.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(ll.buy),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }
    setState(() => _loading = true);
    try {
      final api = context.read<LeaguesApiService>();
      final shell = LeagueShellData.maybeOf(context);
      final result = await api.buyLeaguePlayerNow(
        idLiga: leagueId,
        idLigaJugador: idLigaJugador,
        idUsuario: idUsuario,
      );
      await Future.wait([_loadDetail(), shell?.reload() ?? Future.value()]);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.leagueL10n.purchaseCompleted(
              LeagueMoneyFormat.euros(result.cantidadCompra.toDouble()),
              LeagueMoneyFormat.euros(result.nuevoSaldo.toDouble()),
            ),
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
      setState(() => _loading = false);
    }
  }

  static String _rating(double v) {
    if (v.isNaN || v.isInfinite) {
      return '—';
    }
    if (v == v.roundToDouble()) {
      return v.toInt().toString();
    }
    return v.toStringAsFixed(1).replaceAll('.', ',');
  }

  static Widget _valueTrendIcon(
    double current,
    double previous, {
    double size = 26,
  }) {
    const eps = 1e-6;
    if (current.isNaN ||
        previous.isNaN ||
        current.isInfinite ||
        previous.isInfinite) {
      return Icon(
        Icons.remove_rounded,
        size: size,
        color: Colors.grey.shade500,
      );
    }
    if (current > previous + eps) {
      return Icon(
        Icons.arrow_upward_rounded,
        size: size + 2,
        color: Colors.green.shade600,
      );
    }
    if (current < previous - eps) {
      return Icon(
        Icons.arrow_downward_rounded,
        size: size + 2,
        color: Colors.red.shade600,
      );
    }
    return Icon(
      Icons.horizontal_rule_rounded,
      size: size,
      color: Colors.grey.shade600,
    );
  }

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        final idLj = widget.idLigaJugador != null && widget.idLigaJugador! > 0
            ? widget.idLigaJugador
            : widget.player.idLigaJugador;
        debugPrint('[starter-prob][profile-route]');
        debugPrint('idLigaJugador=$idLj');
        debugPrint('idJornadaRecibida=${widget.idJornada}');
        debugPrint(
          'widget.player.probabilidadTitular=${widget.player.probabilidadTitular}',
        );
        debugPrint(
          'widget.player.motivoTitularidad="${widget.player.motivoTitularidad ?? ''}"',
        );
      });
    }
  }

  @override
  void didUpdateWidget(covariant LeaguePlayerProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.idJornada != oldWidget.idJornada) {
      if (_loadStarted) {
        _loadDetail();
      }
    }
  }

  static double _resolvedTotalPoints({
    required LeaguePlayerDetail? detail,
    required LeagueSquadPlayer player,
  }) {
    if (detail != null) {
      final backend = detail.displayFantasyTotalPoints;
      if (backend > 0) {
        return backend;
      }
      final rounds = detail.estadisticasJornadas;
      if (rounds.isNotEmpty) {
        final sum = rounds.fold<double>(0, (s, r) => s + r.puntos);
        if (sum > 0) {
          return sum;
        }
      }
      return backend;
    }
    return player.puntosTotales;
  }

  String _effectiveEstado(LeaguePlayerDetail? detail) {
    return leaguePlayerEffectiveEstado(
      estado: detail?.estado ?? widget.player.estado,
      estadoVisible: detail?.estadoVisible ?? widget.player.estadoVisible,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shellDetail = LeagueShellData.maybeOf(context)?.detail;
    if (_loadStarted) {
      if (!identical(_lastShellDetailRef, shellDetail)) {
        _lastShellDetailRef = shellDetail;
        _loadDetail();
      }
      return;
    }
    _lastShellDetailRef = shellDetail;
    _loadStarted = true;
    _loadDetail();
  }

  @override
  Widget build(BuildContext context) {
    final ll = context.leagueL10n;
    final detail = _detail;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final name = (detail?.nombre ?? widget.player.nombre).trim().isEmpty
        ? LeagueDisplayStrings.playerShortName(
            pila: detail?.pila ?? widget.player.pila,
            nombre: detail?.nombre ?? widget.player.nombre,
            ll: ll,
          )
        : (detail?.nombre ?? widget.player.nombre).trim();
    final pos = (detail?.posicion ?? widget.player.posicion).trim().isEmpty
        ? '—'
        : (detail?.posicion ?? widget.player.posicion).trim();
    final valor = detail?.valor ?? widget.player.valor;
    final valorAnterior = detail?.valorAnterior ?? widget.player.valorAnterior;
    final valoracion = detail?.valoracion ?? widget.player.valoracion;
    final cansancio = detail?.cansancio ?? widget.player.cansancio;
    final idEquipo = detail?.idEquipo ?? widget.player.idEquipo;
    final nombreEquipo = (detail?.nombreEquipo ?? widget.player.nombreEquipo)
        .trim();
    final fotoEquipoUrl = widget.player.resolvedFotoEquipoUrl();
    final estadoTitularRaw = _effectiveEstado(detail).trim();
    final ocultaProbTitularPorEstado =
        leaguePlayerEstadoOcultaProbabilidadTitular(estadoTitularRaw);
    final probTitular = _probTitularParaBloqueUi();
    final motivoTitular = _motivoTitularParaBloqueUi();
    if (kDebugMode) {
      debugPrint('[starter-prob][player-detail-ui]');
      debugPrint('idJornadaApiUsada=${_idJornadaQueryProbTitular()}');
      debugPrint(
        'ultimaPeticionDetalleIdJornada=$_ultimaPeticionDetalleIdJornada',
      );
      debugPrint('probBloqueUi=$probTitular');
      debugPrint('motivoBloqueUi="${motivoTitular ?? ''}"');
      debugPrint(
        '[detail.prob=${detail?.probabilidadTitular} '
        'widget.player.prob=${widget.player.probabilidadTitular}]',
      );
      debugPrint(
        'idPartidoProbabilidad_detail=${detail?.idPartidoProbabilidad} '
        'idPartidoProbabilidad_widget=${widget.player.idPartidoProbabilidad}',
      );
      debugPrint(
        'calculadoEnProbabilidad_detail=${detail?.calculadoEnProbabilidad} '
        'calculadoEnProbabilidad_widget=${widget.player.calculadoEnProbabilidad}',
      );
    }
    final puntosTotales = _resolvedTotalPoints(
      detail: detail,
      player: widget.player,
    );
    final isInjured = _isInjuredState;
    final isSuspended = _isSuspendedState;
    final isProtected = detail?.jugadorProtegido ?? widget.player.jugadorProtegido;
    final protFinTemp = detail?.proteccionHastaFinTemporada ?? widget.player.proteccionHastaFinTemporada;
    final protJornadaFin = detail?.proteccionJornadaFin ?? widget.player.proteccionJornadaFin;
    final unavailableLine = (isInjured || isSuspended)
        ? _availabilityText(ll)
        : '';
    final idUsuario = _resolvedUsuarioId();
    final ownership = _resolveOwnershipContext(
      detail: detail,
      idUsuario: idUsuario,
    );
    final ownershipResolved = ownership.ownershipResolved;
    final isOwn = ownership.isOwn;
    final isMarket = ownership.isMarket;
    final isInNightMarketToday = ownership.isInNightMarketToday;
    final canSell = detail != null && ownershipResolved && isOwn;
    final canOffer = detail != null && ownershipResolved && !isOwn && !isMarket;
    final canBuyNow =
        detail != null &&
        ownershipResolved &&
        isMarket &&
        !isInNightMarketToday;
    if (kDebugMode) {
      debugPrint(
        '[player-detail][actions] idLigaJugador=${_resolvedIdLigaJugador()} ownershipResolved=$ownershipResolved isOwn=$isOwn isMarket=$isMarket isInNightMarketToday=$isInNightMarketToday canSell=$canSell canOffer=$canOffer canBuyNow=$canBuyNow',
      );
    }
    final ownerLabel = (detail?.nombreDuenoVisible ?? '').trim().isNotEmpty
        ? detail!.nombreDuenoVisible.trim()
        : ((detail?.propietarioNick ?? '').trim().isNotEmpty
              ? detail!.propietarioNick.trim()
              : (widget.player.nombreDuenoVisible.trim().isNotEmpty
                    ? widget.player.nombreDuenoVisible.trim()
                    : (widget.player.propietarioNick.trim().isNotEmpty
                          ? widget.player.propietarioNick.trim()
                          : '')));

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(ll.playerTitle),
        scrolledUnderElevation: 0,
        actions: [
          if (canOffer)
            IconButton(
              tooltip: ll.makeOffer,
              onPressed: _loading ? null : _openOfferSheet,
              icon: const Icon(Icons.local_offer_outlined),
            ),
          if (canBuyNow)
            TextButton(
              onPressed: _loading ? null : () => _buyPlayerNow(valor),
              child: Text(ll.buyX2),
            ),
          if (canSell)
            TextButton(
              onPressed: _loading ? null : _openManageOffersSheet,
              child: Text(ll.offersCount(_receivedOffersForPlayer.length)),
            ),
          if (canSell)
            TextButton(
              onPressed: _loading ? null : () => _sellPlayer(valor),
              child: Text(ll.sellToLeague),
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primaryContainer.withValues(alpha: 0.35),
                    colorScheme.surfaceContainerHigh.withValues(alpha: 0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        LeaguePlayerAvatar(
                          player: widget.player,
                          size: 96,
                          circular: true,
                        ),
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: idEquipo > 0
                              ? Semantics(
                                  button: true,
                                  label: nombreEquipo.isEmpty
                                      ? ll.seeTeam
                                      : ll.seeTeamColon(nombreEquipo),
                                  child: Tooltip(
                                    message: nombreEquipo.isEmpty
                                        ? ll.seeTeam
                                        : ll.seeTeamNamed(nombreEquipo),
                                    child: Material(
                                      color: Colors.transparent,
                                      shape: const CircleBorder(),
                                      clipBehavior: Clip.antiAlias,
                                      child: InkWell(
                                        customBorder: const CircleBorder(),
                                        onTap: () =>
                                            _openCatalogTeamSquadFromProfile(
                                              idEquipo: idEquipo,
                                              nombreEquipo: nombreEquipo,
                                              fotoEquipoUrl: fotoEquipoUrl,
                                            ),
                                        child: SizedBox(
                                          width: 46,
                                          height: 46,
                                          child: Center(
                                            child: LeagueTeamLogo(
                                              idEquipo: idEquipo,
                                              size: 34,
                                              networkImageUrl: fotoEquipoUrl,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : LeagueTeamLogo(
                                  idEquipo: idEquipo,
                                  size: 34,
                                  networkImageUrl: fotoEquipoUrl,
                                ),
                        ),
                        if (isInjured)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: colorScheme.errorContainer,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colorScheme.error,
                                  width: 1.4,
                                ),
                              ),
                              child: Icon(
                                LeaguePlayerAvailabilityIcons.injured,
                                size: 16,
                                color: colorScheme.error,
                              ),
                            ),
                          ),
                        if (isSuspended)
                          Positioned(
                            left: -2,
                            top: -2,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: colorScheme.tertiaryContainer,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colorScheme.tertiary,
                                  width: 1.4,
                                ),
                              ),
                              child: Icon(
                                LeaguePlayerAvailabilityIcons.sanctioned,
                                size: 14,
                                color: colorScheme.tertiary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Text(
                                      name,
                                      maxLines: 1,
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        height: 1.05,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Text(
                                  LeagueMoneyFormat.points(puntosTotales),
                                  maxLines: 1,
                                  overflow: TextOverflow.fade,
                                  softWrap: false,
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFFFF6D00),
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          _PlayerPointsTrendBadge(
                            pointsLabel: LeagueMoneyFormat.points(
                              puntosTotales,
                            ),
                            currentValue: valor,
                            previousValue: valorAnterior,
                            showBottomPoints: false,
                          ),
                          if (!ocultaProbTitularPorEstado &&
                              probTitular != null) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: starterTitularidadScaleBackgroundSolid(
                                    probTitular,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$probTitular%',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: starterTitularidadScaleOnBackground(
                                      probTitular,
                                    ),
                                    height: 1,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (isInjured || isSuspended) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(
                                  isSuspended
                                      ? LeaguePlayerAvailabilityIcons.sanctioned
                                      : LeaguePlayerAvailabilityIcons.injured,
                                  size: 16,
                                  color: isSuspended
                                      ? colorScheme.tertiary
                                      : colorScheme.error,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isSuspended ? ll.suspended : ll.injured,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: isSuspended
                                        ? colorScheme.tertiary
                                        : colorScheme.error,
                                  ),
                                ),
                              ],
                            ),
                            if (unavailableLine.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                unavailableLine,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                          if (isProtected) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF64B5F6).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: const Color(0xFF64B5F6).withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.shield_rounded, size: 16, color: Color(0xFF64B5F6)),
                                  const SizedBox(width: 6),
                                  Text(
                                    protFinTemp
                                        ? ll.protectedSeason
                                        : protJornadaFin != null
                                            ? ll.protectedUntilMatchday(protJornadaFin)
                                            : ll.protectedGeneric,
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: const Color(0xFF64B5F6),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (canOffer && ownerLabel.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer
                                    .withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                ll.ownerNamed(ownerLabel),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              ll.leagueDataTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.25,
              children: [
                _StatCell(
                  icon: Icons.sports_soccer_outlined,
                  label: ll.positionLabel,
                  value: pos,
                  colorScheme: colorScheme,
                  theme: theme,
                  showLabel: false,
                ),
                _StatCell(
                  icon: Icons.star_rounded,
                  label: ll.valuationLabel,
                  value: _rating(valoracion),
                  colorScheme: colorScheme,
                  theme: theme,
                  highlight: true,
                  showLabel: false,
                ),
                _StatCell(
                  icon: Icons.payments_outlined,
                  label: ll.currentValueLabel,
                  value: LeagueMoneyFormat.money(valor),
                  colorScheme: colorScheme,
                  theme: theme,
                  showLabel: false,
                ),
                _StatCell(
                  icon: Icons.battery_charging_full_rounded,
                  label: ll.fatigueLabel,
                  value: '$cansancio',
                  colorScheme: colorScheme,
                  theme: theme,
                  showLabel: false,
                ),
              ],
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.fromLTRB(0, 20, 0, 8),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _error!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.tonalIcon(
                    onPressed: _loadDetail,
                    icon: const Icon(Icons.refresh),
                    label: Text(context.l10n.retry),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          if (detail != null)
            LeaguePlayerProfileRoundsSection(
              roundStats: detail.estadisticasJornadas,
              playerPosition: detail.posicion,
              initialSelectedIdJornada: widget.idJornada,
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Text(
                ll.loadingHistoryFromServer,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlayerPointsTrendBadge extends StatelessWidget {
  const _PlayerPointsTrendBadge({
    required this.pointsLabel,
    required this.currentValue,
    required this.previousValue,
    this.showBottomPoints = true,
  });

  final String pointsLabel;
  final double currentValue;
  final double previousValue;

  /// Si es false, los puntos van en la cabecera (fila del nombre); solo se muestra la tendencia de valor.
  final bool showBottomPoints;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final delta = currentValue - previousValue;
    final deltaLabel = delta.abs() < 1e-6
        ? 'Sin cambio'
        : '${delta > 0 ? '+' : '-'}${LeagueMoneyFormat.money(delta.abs())}';
    final trendRow = Row(
      children: [
        _LeaguePlayerProfileScreenState._valueTrendIcon(
          currentValue,
          previousValue,
          size: 18,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            deltaLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
    if (!showBottomPoints) {
      return trendRow;
    }
    return SizedBox(
      height: 54,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LeaguePlayerProfileScreenState._valueTrendIcon(
                currentValue,
                previousValue,
                size: 18,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  deltaLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              pointsLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFFFF6D00),
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerOffersManagementSheet extends StatefulWidget {
  const _PlayerOffersManagementSheet({
    required this.offers,
    required this.onAccept,
    required this.onReject,
  });

  final List<LeagueOfferItem> offers;
  final Future<void> Function(int idOferta) onAccept;
  final Future<void> Function(int idOferta) onReject;

  @override
  State<_PlayerOffersManagementSheet> createState() =>
      _PlayerOffersManagementSheetState();
}

class _PlayerOffersManagementSheetState
    extends State<_PlayerOffersManagementSheet> {
  int? _busyId;

  @override
  Widget build(BuildContext context) {
    final ll = context.leagueL10n;
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                ll.receivedOffersTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: Text(context.l10n.close),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.offers.isEmpty)
          Text(ll.noPendingOffers, style: theme.textTheme.bodyMedium),
        for (final offer in widget.offers)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.22),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _OfferBuyerAvatar(offer: offer),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _buyerNickname(offer, ll),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          LeagueMoneyFormat.euros(offer.cantidad.toDouble()),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          onPressed: _busyId == offer.idOferta
                              ? null
                              : () async {
                                  final navigator = Navigator.of(context);
                                  setState(() => _busyId = offer.idOferta);
                                  await widget.onReject(offer.idOferta);
                                  if (!mounted) return;
                                  setState(() => _busyId = null);
                                  navigator.pop(false);
                                },
                          child: Text(ll.reject),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          onPressed: _busyId == offer.idOferta
                              ? null
                              : () async {
                                  final navigator = Navigator.of(context);
                                  setState(() => _busyId = offer.idOferta);
                                  await widget.onAccept(offer.idOferta);
                                  if (!mounted) return;
                                  setState(() => _busyId = null);
                                  navigator.pop(true);
                                },
                          child: Text(ll.accept),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

String _buyerNickname(LeagueOfferItem offer, LeagueL10n ll) {
  final nick = offer.nicknameComprador.trim();
  if (nick.isNotEmpty) {
    return nick;
  }
  return ll.genericUser;
}

class _OfferBuyerAvatar extends StatelessWidget {
  const _OfferBuyerAvatar({required this.offer});

  final LeagueOfferItem offer;

  String? _resolveUrl() {
    return LeagueAssetUrls.buildBackendImageUrl(offer.fotoUsuarioComprador);
  }

  @override
  Widget build(BuildContext context) {
    final ll = context.leagueL10n;
    final url = _resolveUrl();
    final fallbackText = _buyerNickname(offer, ll);
    if (url == null) {
      return _OfferAvatarFallback(text: fallbackText);
    }
    return ClipOval(
      child: Image.network(
        url,
        width: 36,
        height: 36,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _OfferAvatarFallback(text: fallbackText),
      ),
    );
  }
}

class _OfferAvatarFallback extends StatelessWidget {
  const _OfferAvatarFallback({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final first = text.trim().isEmpty ? '?' : text.trim().substring(0, 1);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.primaryContainer.withValues(alpha: 0.7),
      ),
      alignment: Alignment.center,
      child: Text(
        first.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
    required this.theme,
    this.highlight = false,
    this.showLabel = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final bool highlight;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: highlight
            ? colorScheme.primaryContainer.withValues(alpha: 0.45)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 16, color: colorScheme.primary),
            if (showLabel) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
