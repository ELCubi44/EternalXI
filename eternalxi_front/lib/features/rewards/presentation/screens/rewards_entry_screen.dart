import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/data/models/league_summary.dart';
import 'package:eternal_xi/features/auth/controller/auth_controller.dart';
import 'package:eternal_xi/features/leagues/controller/leagues_controller.dart';
import 'package:eternal_xi/features/rewards/presentation/screens/league_rewards_screen.dart';
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
    final user = context.watch<AuthController>().currentUser;
    final leagues = context.watch<LeaguesController>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.l10n.rewards),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(22),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Text(
                'Sobres, cartas y entrenador',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
      body: user == null || user.id <= 0
          ? _Message(
              icon: Icons.person_off_outlined,
              text: 'No se pudo identificar el usuario actual.',
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
                    'Tus ligas',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
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
                      style: const TextStyle(color: Colors.white70),
                    )
                  else if (leagues.myLeagues.isEmpty)
                    const Text(
                      'No participas en ninguna liga. Crea una o únete con código.',
                      style: TextStyle(color: Colors.white70, height: 1.35),
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
    );
  }
}

class _HeroIntro extends StatelessWidget {
  const _HeroIntro({required this.colorScheme, required this.theme});

  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.45),
            const Color(0xFF311B92).withValues(alpha: 0.35),
            const Color(0xFFFFB300).withValues(alpha: 0.12),
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
              'Selecciona una liga',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cada liga tiene sus propios puntos de recompensa, sobres, cartas y entrenador.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.82),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: const Color(0xFF12182A),
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
                        theme.colorScheme.primary.withValues(alpha: 0.5),
                        theme.colorScheme.tertiary.withValues(alpha: 0.4),
                      ],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.emoji_events_outlined, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        league.nombre,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${league.participantes} participantes'
                        '${league.soyAdmin ? ' · Administras' : ''}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: onEnter,
                  child: const Text('Entrar'),
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
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(icon, size: 48, color: Colors.white38),
        const SizedBox(height: 16),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white70,
                height: 1.35,
              ),
        ),
      ],
    );
  }
}
