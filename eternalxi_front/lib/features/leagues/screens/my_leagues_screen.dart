import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/data/models/league_summary.dart';
import 'package:eternal_xi/features/auth/controller/auth_controller.dart';
import 'package:eternal_xi/features/leagues/controller/leagues_controller.dart';
import 'package:eternal_xi/core/utils/league_asset_urls.dart';
import 'package:eternal_xi/shared/widgets/user_tokens_action.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class MyLeaguesScreen extends StatefulWidget {
  const MyLeaguesScreen({super.key});

  @override
  State<MyLeaguesScreen> createState() => _MyLeaguesScreenState();
}

class _MyLeaguesScreenState extends State<MyLeaguesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  int? _resolveUserId() {
    final user = context.read<AuthController>().currentUser;
    final id = user?.id;
    if (id == null || id <= 0) {
      return null;
    }
    return id;
  }

  Future<void> _refresh() async {
    final idUsuario = _resolveUserId();
    if (idUsuario == null) {
      return;
    }
    await context.read<LeaguesController>().loadMyLeagues(idUsuario);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final leagues = context.watch<LeaguesController>();
    final userId = _resolveUserId();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis ligas'),
        actions: userId == null
            ? null
            : [
                const UserTokensAction(),
                IconButton(
                  tooltip: 'Unirse a una liga',
                  icon: const Icon(Icons.group_add_outlined),
                  onPressed: () async {
                    await context.push(AppRoutes.leaguesJoin);
                    if (context.mounted) {
                      await _refresh();
                    }
                  },
                ),
                IconButton(
                  tooltip: 'Crear liga',
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () async {
                    await context.push(AppRoutes.leaguesCreate);
                    if (context.mounted) {
                      await _refresh();
                    }
                  },
                ),
                const SizedBox(width: 4),
              ],
      ),
      body: userId == null
          ? _NoSessionMessage(colorScheme: colorScheme, theme: theme)
          : RefreshIndicator(
              onRefresh: _refresh,
              child: _LeaguesBody(
                leagues: leagues,
                colorScheme: colorScheme,
                theme: theme,
                onRetry: _refresh,
              ),
            ),
    );
  }
}

class _NoSessionMessage extends StatelessWidget {
  const _NoSessionMessage({required this.colorScheme, required this.theme});

  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        Icon(Icons.person_off_outlined, size: 56, color: colorScheme.outline),
        const SizedBox(height: 16),
        Text(
          'No hay sesión de usuario',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Inicia sesión para ver tus ligas. Si ya iniciaste sesión, vuelve atrás e inténtalo de nuevo.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _LeaguesBody extends StatelessWidget {
  const _LeaguesBody({
    required this.leagues,
    required this.colorScheme,
    required this.theme,
    required this.onRetry,
  });

  final LeaguesController leagues;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    if (leagues.isLoading && leagues.myLeagues.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (leagues.errorMessage != null && leagues.myLeagues.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Icon(Icons.cloud_off_outlined, size: 48, color: colorScheme.error),
          const SizedBox(height: 16),
          Text(
            leagues.errorMessage!,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.tonalIcon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      );
    }

    if (leagues.myLeagues.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 56,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Aún no tienes ligas',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Crea una liga o únete con un código usando los iconos arriba a la derecha.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: leagues.myLeagues.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final league = leagues.myLeagues[index];
        return _LeagueCard(
          league: league,
          onTap: () => context.push(AppRoutes.leagueDetail(league.id)),
        );
      },
    );
  }
}

class _LeagueCard extends StatelessWidget {
  const _LeagueCard({required this.league, required this.onTap});

  final LeagueSummary league;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final seasonUri = league.idTemporada > 0
        ? LeagueAssetUrls.seasonCover(league.idTemporada).toString()
        : null;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (seasonUri != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        seasonUri,
                        width: 64,
                        height: 64,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => _SeasonFallback(
                          colorScheme: colorScheme,
                          theme: theme,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      league.nombre,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.groups_2_outlined,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${league.participantes} participantes',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (league.soyAdmin)
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.verified_user_outlined,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeasonFallback extends StatelessWidget {
  const _SeasonFallback({required this.colorScheme, required this.theme});

  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        size: 18,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
