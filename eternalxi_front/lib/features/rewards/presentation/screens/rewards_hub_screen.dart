import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/data/services/leagues_api_service.dart';
import 'package:eternal_xi/features/auth/controller/auth_controller.dart';
import 'package:eternal_xi/features/rewards/presentation/screens/league_rewards_screen.dart';
import 'package:eternal_xi/features/rewards/presentation/screens/rewards_entry_screen.dart';
import 'package:eternal_xi/features/rewards/presentation/theme/rewards_premium_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Punto de entrada global: con `idLiga` abre recompensas de esa liga; si no, selector.
class RewardsHubScreen extends StatefulWidget {
  const RewardsHubScreen({super.key, this.initialLeagueId});

  final int? initialLeagueId;

  @override
  State<RewardsHubScreen> createState() => _RewardsHubScreenState();
}

class _RewardsHubScreenState extends State<RewardsHubScreen> {
  String? _leagueName;
  bool _loadingName = false;

  @override
  void initState() {
    super.initState();
    final id = widget.initialLeagueId;
    if (id != null && id > 0) {
      _loadingName = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchLeagueName(id);
      });
    }
  }

  Future<void> _fetchLeagueName(int idLiga) async {
    final user = context.read<AuthController>().currentUser;
    if (user == null || user.id <= 0) {
      if (mounted) {
        setState(() => _loadingName = false);
      }
      return;
    }
    try {
      final api = context.read<LeaguesApiService>();
      final d = await api.getLeagueDetail(idLiga: idLiga, idUsuario: user.id);
      if (mounted) {
        setState(() {
          _leagueName = d.nombre;
          _loadingName = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _leagueName = 'Liga $idLiga';
          _loadingName = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RewardsPremiumTheme.scope(child: _buildBody(context));
  }

  Widget _buildBody(BuildContext context) {
    final id = widget.initialLeagueId;
    final user = context.watch<AuthController>().currentUser;
    if (id != null && id > 0) {
      if (user == null || user.id <= 0) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(context.l10n.rewards),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          ),
          body: const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No se pudo identificar el usuario actual.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, height: 1.35),
              ),
            ),
          ),
        );
      }
      if (_loadingName || _leagueName == null) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(context.l10n.leagueRewards),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          ),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      return LeagueRewardsScreen(
        idLiga: id,
        idUsuario: user.id,
        leagueName: _leagueName!,
      );
    }
    return const RewardsEntryScreen();
  }
}
