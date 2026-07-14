import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/data/models/friendship.dart';
import 'package:eternal_xi/data/services/leagues_api_service.dart';
import 'package:eternal_xi/data/services/user_api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InviteFriendsSheet extends StatefulWidget {
  const InviteFriendsSheet({
    super.key,
    required this.idLiga,
    required this.idUsuario,
  });

  final int idLiga;
  final int idUsuario;

  @override
  State<InviteFriendsSheet> createState() => _InviteFriendsSheetState();
}

class _InviteFriendsSheetState extends State<InviteFriendsSheet> {
  List<Friendship> _friends = [];
  bool _loading = true;
  String? _error;
  final Set<int> _invited = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await context.read<UserApiService>().listFriendships(
        idUsuario: widget.idUsuario,
      );
      if (!mounted) return;
      setState(() {
        _friends = rows.where((f) => f.isAccepted).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _invite(Friendship friend) async {
    try {
      await context.read<LeaguesApiService>().inviteFriendToLeague(
        idLiga: widget.idLiga,
        idUsuario: widget.idUsuario,
        idAmigo: friend.idUsuario,
      );
      if (!mounted) return;
      setState(() => _invited.add(friend.idUsuario));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(context.l10n.leagueInviteSent(friend.nickname)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: context.xiDivider,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.leagueInviteFriendsTitle,
              style: TextStyle(
                fontFamily: 'Lumiare',
                fontSize: 18,
                color: context.xiTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.leagueInviteFriendsBody,
              style: TextStyle(
                fontFamily: 'Lumiare',
                fontSize: 13,
                color: context.xiTextSecondary,
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: XiColors.error))
            else if (_friends.isEmpty)
              Text(
                l10n.leagueInviteFriendsEmpty,
                style: TextStyle(color: context.xiTextSecondary),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _friends.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final f = _friends[index];
                    final sent = _invited.contains(f.idUsuario);
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: context.xiBorderSubtle),
                      ),
                      title: Text(
                        f.nickname,
                        style: const TextStyle(
                          fontFamily: 'Lumiare',
                        ),
                      ),
                      trailing: sent
                          ? Text(
                              l10n.friendsPending,
                              style: TextStyle(color: context.xiTextSecondary),
                            )
                          : FilledButton.tonal(
                              onPressed: () => _invite(f),
                              child: Text(l10n.leagueInviteFriendAction),
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
