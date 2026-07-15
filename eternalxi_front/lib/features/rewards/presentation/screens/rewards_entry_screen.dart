import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/localization/rewards_l10n.dart';
import 'package:eternal_xi/data/models/league_summary.dart';
import 'package:eternal_xi/features/auth/controller/auth_controller.dart';
import 'package:eternal_xi/features/leagues/controller/leagues_controller.dart';
import 'package:eternal_xi/features/rewards/presentation/screens/league_rewards_screen.dart';
import 'package:eternal_xi/shared/widgets/fantasy_atmosphere_background.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Selector de liga antes de abrir recompensas (puntos globales, acciones por liga).
class RewardsEntryScreen extends StatefulWidget {
  const RewardsEntryScreen({super.key});

  @override
  State<RewardsEntryScreen> createState() => _RewardsEntryScreenState();
}

class _RewardsEntryScreenState extends State<RewardsEntryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final user = context.read<AuthController>().currentUser;
    final id = user?.id;
    if (id == null || id <= 0) {
      return;
    }
    await context.read<LeaguesController>().loadMyLeagues(id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.rewardsL10n;
    final user = context.watch<AuthController>().currentUser;
    final leagues = context.watch<LeaguesController>();

    return WithFantasyAtmosphere(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(context.l10n.rewards),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(22),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 8),
                child: Text(
                  l10n.shopSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
        body: user == null || user.id <= 0
            ? _Message(
                icon: Icons.person_off_outlined,
                text: l10n.noUserSession,
              )
            : RefreshIndicator(
              color: colorScheme.primary,
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                children: [
                  _HeroIntro(colorScheme: colorScheme, theme: theme),
                  const SizedBox(height: 22),
                  Text(
                    l10n.yourLeagues,
                    style: theme.textTheme.titleMedium?.copyWith(
                      ),
                  ),
                  const SizedBox(height: 12),
                  if (leagues.isLoading && leagues.myLeagues.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (leagues.errorMessage != null &&
                      leagues.myLeagues.isEmpty)
                    Text(
                      leagues.errorMessage!,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    )
                  else if (leagues.myLeagues.isEmpty)
                    Text(
                      l10n.noLeaguesHint,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    )
                  else
                    ...leagues.myLeagues.map(
                      (l) => _LeaguePickCard(
                        league: l,
                        onEnter: () {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (_) => LeagueRewardsScreen(
                                idLiga: l.id,
                                idUsuario: user.id,
                                leagueName: l.nombre,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
      ),
    );
  }
}

class _HeroIntro extends StatelessWidget {
  const _HeroIntro({required this.colorScheme, required this.theme});

  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final l10n = context.rewardsL10n;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.55),
            colorScheme.secondaryContainer.withValues(alpha: 0.45),
            colorScheme.tertiaryContainer.withValues(alpha: 0.35),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: 34,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.selectLeagueTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.selectLeagueBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaguePickCard extends StatelessWidget {
  const _LeaguePickCard({required this.league, required this.onEnter});

  final LeagueSummary league;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.rewardsL10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onEnter,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.5),
                        colorScheme.tertiary.withValues(alpha: 0.4),
                      ],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.emoji_events_outlined,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        league.nombre,
                        style: theme.textTheme.titleMedium?.copyWith(
                          ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${l10n.participants(league.participantes)}'
                        '${league.soyAdmin ? ' · ${l10n.youAdmin}' : ''}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: onEnter,
                  child: Text(l10n.enter),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(icon, size: 48, color: colorScheme.outline),
        const SizedBox(height: 16),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
        ),
      ],
    );
  }
}
