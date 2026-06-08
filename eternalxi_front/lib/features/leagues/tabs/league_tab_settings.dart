import 'dart:math' as math;

import 'package:eternal_xi/app/localization/league_l10n.dart';
import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/data/models/league_detail.dart';
import 'package:eternal_xi/data/models/league_participant.dart';
import 'package:eternal_xi/data/services/leagues_api_service.dart';
import 'package:eternal_xi/features/leagues/controller/leagues_controller.dart';
import 'package:eternal_xi/features/leagues/navigation/league_inner_navigation.dart';
import 'package:eternal_xi/features/leagues/shell/league_shell_data.dart';
import 'package:eternal_xi/features/leagues/widgets/league_config_summary_card.dart';
import 'package:eternal_xi/features/leagues/widgets/league_fichajes_phase_banner.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class LeagueTabSettings extends StatefulWidget {
  const LeagueTabSettings({super.key});

  @override
  State<LeagueTabSettings> createState() => _LeagueTabSettingsState();
}

class _LeagueTabSettingsState extends State<LeagueTabSettings>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<LeagueParticipant>? _participants;
  bool _loadingParticipants = false;
  String? _participantsError;
  int? _handledRefreshGeneration;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final shell = LeagueShellData.maybeOf(context);
      if (shell?.detail?.soyAdmin == true) {
        _loadParticipants();
      }
    });
  }

  static String _shareMessage(String code) {
    return 'Eternal XI: $code';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shell = LeagueShellData.maybeOf(context);
    if (shell == null) {
      return;
    }
    final gen = shell.refreshGeneration;
    if (_handledRefreshGeneration == null) {
      _handledRefreshGeneration = gen;
      return;
    }
    if (gen != _handledRefreshGeneration) {
      _handledRefreshGeneration = gen;
      if (shell.detail?.soyAdmin == true) {
        _loadParticipants();
      }
    }
  }

  Future<void> _loadParticipants() async {
    final shell = LeagueShellData.maybeOf(context);
    if (shell == null || shell.detail?.soyAdmin != true) {
      return;
    }

    setState(() {
      _loadingParticipants = true;
      _participantsError = null;
    });

    try {
      final api = context.read<LeaguesApiService>();
      final list = await api.getParticipants(
        idLiga: shell.leagueId,
        idUsuario: shell.idUsuario,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _participants = list;
        _loadingParticipants = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _participantsError = e.toString().replaceFirst('Exception: ', '');
        _loadingParticipants = false;
      });
    }
  }

  Future<void> _refreshShellAndList() async {
    final shell = LeagueShellData.maybeOf(context);
    if (shell == null) {
      return;
    }
    await shell.reload();
    if (shell.detail?.soyAdmin == true && mounted) {
      await _loadParticipants();
    }
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.copy)),
    );
  }

  Future<void> _shareCode(String code) async {
    await SharePlus.instance.share(ShareParams(text: _shareMessage(code)));
  }

  Future<void> _goToMyLeagues() async {
    if (!mounted) {
      return;
    }
    final shell = LeagueShellData.maybeOf(context);
    final uid = shell?.idUsuario;
    if (uid != null) {
      await context.read<LeaguesController>().loadMyLeagues(uid);
    }
    if (mounted) {
      context.go(AppRoutes.leagues);
    }
  }

  Future<void> _leaveLeague({int? nuevoAdministradorId}) async {
    final shell = LeagueShellData.maybeOf(context);
    if (shell == null) {
      return;
    }
    final api = context.read<LeaguesApiService>();
    await api.leaveLeague(
      idLiga: shell.leagueId,
      idUsuario: shell.idUsuario,
      nuevoAdministradorId: nuevoAdministradorId,
    );
    if (mounted) {
      await _goToMyLeagues();
    }
  }

  Future<void> _transferLeagueAdmin({
    required int idAdminActual,
    required int idNuevoAdmin,
  }) async {
    final shell = LeagueShellData.maybeOf(context);
    if (shell == null) {
      return;
    }
    final api = context.read<LeaguesApiService>();
    final response = await api.transferLeagueAdmin(
      idLiga: shell.leagueId,
      idAdminActual: idAdminActual,
      idNuevoAdmin: idNuevoAdmin,
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(response.message)));
    await _refreshShellAndList();
  }

  Future<void> _closeLeague() async {
    final shell = LeagueShellData.maybeOf(context);
    if (shell == null) {
      return;
    }
    final api = context.read<LeaguesApiService>();
    await api.closeLeague(idLiga: shell.leagueId, idUsuario: shell.idUsuario);
    if (mounted) {
      await _goToMyLeagues();
    }
  }

  Future<void> _kick(int idUsuarioExpulsado) async {
    final shell = LeagueShellData.maybeOf(context);
    if (shell == null) {
      return;
    }
    final api = context.read<LeaguesApiService>();
    final payload = <String, dynamic>{
      'idAdminUsuario': shell.idUsuario,
      'idUsuarioExpulsado': idUsuarioExpulsado,
    };
    if (kDebugMode) {
      debugPrint(
        '[kick] POST /leagues/${shell.leagueId}/kick body=$payload',
      );
    }
    await api.kickParticipant(
      idLiga: shell.leagueId,
      idAdminUsuario: shell.idUsuario,
      idUsuarioExpulsado: idUsuarioExpulsado,
    );
    if (!mounted) {
      return;
    }
    await _refreshShellAndList();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.leagueL10n.participantExpelled)));
  }

  Future<int?> _showDelegatePicker(List<LeagueParticipant> others) async {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return _DelegatePickerSheet(others: others);
      },
    );
  }

  Future<void> _onLeavePressed(
    LeagueDetail detail,
    LeagueShellData shell,
  ) async {
    if (!detail.soyAdmin) {
      final ll = context.leagueL10n;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(ll.leaveLeagueConfirmTitle),
          content: Text(ll.leaveLeagueBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ctx.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(ll.leaveButton),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) {
        return;
      }
      try {
        await _leaveLeague(nuevoAdministradorId: null);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
            ),
          );
        }
      }
      return;
    }

    if (detail.participantes <= 1) {
      final ll = context.leagueL10n;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(ll.cannotLeaveLeagueTitle),
          content: Text(ll.cannotLeaveOnlyParticipantBody),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ll.understood),
            ),
          ],
        ),
      );
      return;
    }

    await _ensureParticipantsForAdmin();
    if (!mounted) {
      return;
    }
    final others =
        _participants?.where((p) => p.idUsuario != shell.idUsuario).toList() ??
        [];
    if (others.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.leagueL10n.noOtherParticipantsToDelegate)),
      );
      return;
    }

    final newAdminId = await _showDelegatePicker(others);
    if (newAdminId == null || !mounted) {
      return;
    }

    final nick = others.firstWhere((p) => p.idUsuario == newAdminId).nickname;

    final ll = context.leagueL10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ll.confirmLeaveTitle),
        content: Text(ll.leaveAfterDelegateBody(nick)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ll.cedeAndLeave),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) {
      return;
    }
    try {
      await _transferLeagueAdmin(
        idAdminActual: shell.idUsuario,
        idNuevoAdmin: newAdminId,
      );
      if (!mounted) {
        return;
      }
      await _leaveLeague();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _ensureParticipantsForAdmin() async {
    await _loadParticipants();
  }

  Future<void> _onCloseLeaguePressed() async {
    final ll = context.leagueL10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(ctx).colorScheme.error,
        ),
        title: Text(ll.closeLeague),
        content: Text(ll.closeLeagueBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.l10n.close),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }
    try {
      await _closeLeague();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _onTransferAdminPressed(
    LeagueDetail detail,
    LeagueShellData shell,
  ) async {
    await _ensureParticipantsForAdmin();
    if (!mounted) {
      return;
    }
    final others =
        _participants?.where((p) => p.idUsuario != shell.idUsuario).toList() ??
        [];
    if (others.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.leagueL10n.noParticipantsToDelegateAdmin)),
      );
      return;
    }

    final newAdminId = await _showDelegatePicker(others);
    if (newAdminId == null || !mounted) {
      return;
    }

    final nick = others.firstWhere((p) => p.idUsuario == newAdminId).nickname;
    final ll = context.leagueL10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ll.delegateAdmin),
        content: Text(ll.delegateAdminConfirm(nick)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ll.delegateAction),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) {
      return;
    }
    try {
      await _transferLeagueAdmin(
        idAdminActual: detail.idAdministrador > 0
            ? detail.idAdministrador
            : shell.idUsuario,
        idNuevoAdmin: newAdminId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _onKickPressed(LeagueParticipant p) async {
    final ll = context.leagueL10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ll.kickParticipantTitle),
        content: Text(ll.kickParticipantConfirm(p.nickname)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ll.kickAction),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }
    try {
      await _kick(p.idUsuario);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ll = context.leagueL10n;
    super.build(context);
    final shell = LeagueShellData.maybeOf(context);
    final detail = shell?.detail;

    if (shell == null || detail == null) {
      return Center(child: Text(l10n.settings));
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final code = detail.codigoInvitacion.trim();
    final isAdmin = detail.soyAdmin;
    final adminAlone = isAdmin && detail.participantes <= 1;

    final sectionWidgets = <Widget>[
      Text(
        l10n.settings,
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 20),
      if (detail.hasConfigSummary) ...[
        _SectionTitle(
          icon: Icons.tune_rounded,
          title: ll.configuration,
        ),
        LeagueConfigSummaryCard(detail: detail),
        if (detail.isFichajesPhaseActive) ...[
          const SizedBox(height: 12),
          LeagueFichajesPhaseBanner(detail: detail),
        ],
        const SizedBox(height: 24),
      ],
      _SectionTitle(
        icon: Icons.key_outlined,
        title: ll.invitationCodeTitle,
      ),
      Card(
        elevation: 0,
        color: colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SelectableText(
                code.isEmpty ? '—' : code,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontFamily: 'monospace',
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: code.isEmpty ? null : () => _copyCode(code),
                      icon: const Icon(Icons.copy_rounded),
                      label: Text(l10n.copy),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: code.isEmpty ? null : () => _shareCode(code),
                      icon: const Icon(Icons.share_rounded),
                      label: Text(l10n.share),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),
      if (isAdmin) ...[
        _SectionTitle(
          icon: Icons.groups_outlined,
          title: ll.participants,
        ),
        _ParticipantsBlock(
          loading: _loadingParticipants,
          error: _participantsError,
          participants: _participants,
          currentUserId: shell.idUsuario,
          leagueId: shell.leagueId,
          onRetry: _loadParticipants,
          onKick: _onKickPressed,
          theme: theme,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 24),
        _SectionTitle(
          icon: Icons.gavel_outlined,
          title: ll.administration,
        ),
        Card(
          elevation: 0,
          color: colorScheme.errorContainer.withValues(alpha: 0.25),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  ll.closeLeague,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  ll.closeLeagueHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: () => _onTransferAdminPressed(detail, shell),
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: Text(ll.delegateAdmin),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                  ),
                  onPressed: _onCloseLeaguePressed,
                  icon: const Icon(Icons.lock_outline),
                  label: Text(ll.closeLeague),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
      _SectionTitle(
        icon: Icons.logout_outlined,
        title: ll.yourParticipation,
      ),
      Card(
        elevation: 0,
        color: colorScheme.surfaceContainerHigh,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (adminAlone) ...[
                Text(
                  ll.adminAloneCannotLeaveHint,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: null,
                  child: Text(ll.leaveLeagueUnavailable),
                ),
              ] else ...[
                Text(
                  isAdmin
                      ? ll.adminLeaveParticipationHint
                      : ll.memberLeaveParticipationHint,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _onLeavePressed(detail, shell),
                  icon: const Icon(Icons.exit_to_app_rounded),
                  label: Text(ll.leaveLeague),
                ),
              ],
            ],
          ),
        ),
      ),
    ];

    return RefreshIndicator(
      onRefresh: () async {
        await shell.reload();
        if (isAdmin) {
          await _loadParticipants();
        }
      },
      child: CustomScrollView(
        key: const PageStorageKey<String>('league_tab_settings'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate(sectionWidgets),
            ),
          ),
        ],
      ),
    );
  }
}

class _DelegatePickerSheet extends StatefulWidget {
  const _DelegatePickerSheet({required this.others});

  final List<LeagueParticipant> others;

  @override
  State<_DelegatePickerSheet> createState() => _DelegatePickerSheetState();
}

class _DelegatePickerSheetState extends State<_DelegatePickerSheet> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ll = context.leagueL10n;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final maxH = math.min(400.0, MediaQuery.sizeOf(context).height * 0.5);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: 16 + bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            ll.newAdminTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ll.newAdminSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxH),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.others.length,
              itemBuilder: (context, i) {
                final p = widget.others[i];
                final selected = _selected == p.idUsuario;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: i == widget.others.length - 1 ? 0 : 8,
                  ),
                  child: Material(
                    color: selected
                        ? theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.45,
                          )
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: selected
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                          width: selected ? 1.5 : 0,
                        ),
                      ),
                      title: Text(p.nickname),
                      leading: _UserPhotoAvatar(
                        imageUrl: p.resolvedFotoUsuarioUrl(),
                        fallbackText: p.nickname,
                        radius: 14,
                      ),
                      subtitle: p.admin
                          ? Text(ll.currentAdmin)
                          : null,
                      trailing: selected
                          ? Icon(
                              Icons.check_circle,
                              color: theme.colorScheme.primary,
                            )
                          : Icon(
                              Icons.circle_outlined,
                              color: theme.colorScheme.outline,
                            ),
                      onTap: () => setState(() => _selected = p.idUsuario),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.l10n.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _selected == null
                      ? null
                      : () => Navigator.pop(context, _selected),
                  child: Text(context.l10n.continueText),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 22, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantsBlock extends StatelessWidget {
  const _ParticipantsBlock({
    required this.loading,
    required this.error,
    required this.participants,
    required this.currentUserId,
    required this.leagueId,
    required this.onRetry,
    required this.onKick,
    required this.theme,
    required this.colorScheme,
  });

  final bool loading;
  final String? error;
  final List<LeagueParticipant>? participants;
  final int currentUserId;
  final int leagueId;
  final VoidCallback onRetry;
  final void Function(LeagueParticipant) onKick;
  final ThemeData theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final ll = context.leagueL10n;
    if (loading && (participants == null || participants!.isEmpty)) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null && (participants == null || participants!.isEmpty)) {
      return Card(
        elevation: 0,
        color: colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(error!, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(context.l10n.retry),
              ),
            ],
          ),
        ),
      );
    }
    final list = participants ?? [];
    if (list.isEmpty) {
      return Card(
        elevation: 0,
        color: colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            ll.noParticipantsInResponse,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < list.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _ParticipantTile(
            participant: list[i],
            isSelf: list[i].idUsuario == currentUserId,
            leagueId: leagueId,
            idUsuarioViewer: currentUserId,
            onKick: () => onKick(list[i]),
            theme: theme,
            colorScheme: colorScheme,
          ),
        ],
      ],
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({
    required this.participant,
    required this.isSelf,
    required this.leagueId,
    required this.idUsuarioViewer,
    required this.onKick,
    required this.theme,
    required this.colorScheme,
  });

  final LeagueParticipant participant;
  final bool isSelf;
  final int leagueId;
  final int idUsuarioViewer;
  final VoidCallback onKick;
  final ThemeData theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final ll = context.leagueL10n;
    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        onTap: participant.idUsuario <= 0
            ? null
            : () => LeagueInnerNavigation.openParticipantSquad(
                context: context,
                leagueId: leagueId,
                idUsuarioViewer: idUsuarioViewer,
                idUsuarioTarget: participant.idUsuario,
                idLigaParticipante: participant.idLigaParticipante,
                nickname: participant.nickname,
              ),
        title: Text(
          participant.nickname,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: _UserPhotoAvatar(
          imageUrl: participant.resolvedFotoUsuarioUrl(),
          fallbackText: participant.nickname,
          radius: 18,
        ),
        subtitle: participant.admin
            ? Text(
                ll.administratorBadge,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                ),
              )
            : null,
        trailing: isSelf
            ? Chip(
                label: Text(ll.youLabel),
                visualDensity: VisualDensity.compact,
                backgroundColor: colorScheme.primaryContainer,
              )
            : IconButton(
                tooltip: ll.kickTooltip,
                icon: Icon(
                  Icons.person_remove_outlined,
                  color: colorScheme.error,
                ),
                onPressed: onKick,
              ),
      ),
    );
  }
}

class _UserPhotoAvatar extends StatelessWidget {
  const _UserPhotoAvatar({
    required this.imageUrl,
    required this.fallbackText,
    required this.radius,
  });

  final String? imageUrl;
  final String fallbackText;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final initial = fallbackText.trim().isEmpty
        ? '?'
        : fallbackText.trim().substring(0, 1).toUpperCase();
    final diameter = radius * 2;
    final fallback = ColoredBox(
      color: colorScheme.primaryContainer,
      child: Center(
        child: Text(
          initial,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
    return ClipOval(
      child: SizedBox(
        width: diameter,
        height: diameter,
        child: imageUrl == null
            ? fallback
            : Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
  }
}
