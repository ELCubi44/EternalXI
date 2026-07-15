import 'dart:async';

import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/core/network/api_exception.dart';
import 'package:eternal_xi/data/models/friendship.dart';
import 'package:eternal_xi/data/models/user_search_result.dart';
import 'package:eternal_xi/data/services/user_api_service.dart';
import 'package:eternal_xi/core/utils/user_public_tag.dart';
import 'package:eternal_xi/features/auth/controller/auth_controller.dart';
import 'package:eternal_xi/features/profile/controller/friends_pending_controller.dart';
import 'package:eternal_xi/features/profile/navigation/user_profile_navigation.dart';
import 'package:eternal_xi/shared/widgets/fantasy_atmosphere_background.dart';
import 'package:eternal_xi/shared/widgets/user_profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _searchCtrl = TextEditingController();
  Timer? _searchDebounce;

  List<Friendship> _all = [];
  List<UserSearchResult> _searchResults = [];
  bool _loading = true;
  bool _searching = false;
  String? _loadError;
  String _lastQuery = '';

  bool get _showSearchBar => _tabs.index == 0;

  bool get _isSearching => _showSearchBar && _searchCtrl.text.trim().length >= 2;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      if (mounted) setState(() {});
    });
    _searchCtrl.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _tabs.dispose();
    super.dispose();
  }

  int? get _userId => context.read<AuthController>().currentUser?.id;

  List<Friendship> get _friends =>
      _all.where((f) => f.isAccepted).toList(growable: false);

  List<Friendship> get _incoming =>
      _all.where((f) => f.isPending && !f.soySolicitante).toList(growable: false);

  List<Friendship> get _outgoing =>
      _all.where((f) => f.isPending && f.soySolicitante).toList(growable: false);

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      final q = _searchCtrl.text.trim();
      if (q == _lastQuery) return;
      _lastQuery = q;
      if (q.length < 2) {
        if (mounted) setState(() => _searchResults = []);
        return;
      }
      _runSearch(q);
    });
  }

  Future<void> _load() async {
    final userId = _userId;
    if (userId == null) return;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final rows = await context.read<UserApiService>().listFriendships(
        idUsuario: userId,
      );
      if (!mounted) return;
      setState(() {
        _all = rows;
        _loading = false;
        _loadError = null;
      });
      if (mounted) {
        context.read<FriendsPendingController>().refresh(userId);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _all = [];
        _loading = false;
        _loadError = e is ApiException ? e.message : context.l10n.friendsLoadError;
      });
    }
  }

  Future<void> _runSearch(String q) async {
    final userId = _userId;
    if (userId == null) return;
    setState(() => _searching = true);
    try {
      final rows = await context.read<UserApiService>().searchUsers(
        idUsuario: userId,
        query: q,
      );
      if (!mounted) return;
      setState(() {
        _searchResults = rows;
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _searching = false);
    }
  }

  Future<void> _accept(Friendship f) async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await context.read<UserApiService>().acceptFriendRequest(
        idUsuario: userId,
        idAmistad: f.id,
      );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(context.l10n.friendsAccepted),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e);
    }
  }

  Future<void> _reject(Friendship f) async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await context.read<UserApiService>().rejectFriendRequest(
        idUsuario: userId,
        idAmistad: f.id,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      _showError(e);
    }
  }

  Future<void> _removeFriend(Friendship f) async {
    final userId = _userId;
    if (userId == null) return;
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.friendsRemoveTitle),
        content: Text(l10n.friendsRemoveBody(f.nickname)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await context.read<UserApiService>().removeFriend(
        idUsuario: userId,
        idAmigo: f.idUsuario,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      _showError(e);
    }
  }

  Future<void> _sendRequest(UserSearchResult user) async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await context.read<UserApiService>().sendFriendRequest(
        idUsuario: userId,
        idAmigo: user.id,
      );
      await _load();
      await _runSearch(_lastQuery);
      if (mounted) {
        context.read<FriendsPendingController>().refresh(userId);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(context.l10n.friendsRequestSent),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e);
    }
  }

  void _showError(Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.error,
        content: Text(e is ApiException ? e.message : e.toString()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return WithFantasyAtmosphere(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(l10n.friendsTitle),
          backgroundColor: context.xiBackground,
          foregroundColor: context.xiTextPrimary,
          bottom: TabBar(
            controller: _tabs,
            labelStyle: const TextStyle(
              fontFamily: 'Lumiare',
            ),
            tabs: [
              Tab(text: l10n.friendsTabFriends),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.friendsTabRequests),
                    if (_incoming.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      _BadgeCount(count: _incoming.length),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
          if (_showSearchBar)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              style: TextStyle(
                fontFamily: 'Lumiare',
                color: context.xiTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: l10n.friendsSearchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : (_searchCtrl.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchCtrl.clear();
                                _lastQuery = '';
                                setState(() => _searchResults = []);
                              },
                              icon: const Icon(Icons.close_rounded),
                            )
                          : null),
                filled: true,
                fillColor: context.xiCardSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: context.xiDivider),
                ),
              ),
            ),
          ),
          if (_loadError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Material(
                color: XiColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_off_rounded, size: 18, color: XiColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _loadError!,
                          style: const TextStyle(
                            fontFamily: 'Lumiare',
                            fontSize: 12,
                            color: XiColors.error,
                          ),
                        ),
                      ),
                      TextButton(onPressed: _load, child: Text(l10n.retry)),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: _isSearching
                ? _buildSearchResults(l10n)
                : _loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabs,
                    children: [
                      _FriendsList(
                        friends: _friends,
                        onRemove: _removeFriend,
                        onRefresh: _load,
                        emptyTitle: l10n.friendsEmptyTitle,
                        emptyBody: l10n.friendsEmptyBody,
                      ),
                      _RequestsList(
                        incoming: _incoming,
                        outgoing: _outgoing,
                        onAccept: _accept,
                        onReject: _reject,
                        emptyTitle: l10n.friendsRequestsEmpty,
                        emptyBody: l10n.friendsRequestsEmptyBody,
                      ),
                    ],
                  ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(AppLocalizations l10n) {
    if (_searching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_searchResults.isEmpty) {
      return _EmptyFriendsState(
        icon: Icons.person_search_rounded,
        title: l10n.friendsSearchEmpty,
        body: l10n.friendsSearchHint,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: _searchResults.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final u = _searchResults[index];
        return _FriendCard(
          userId: u.id,
          nickname: u.nickname,
          photoPath: u.foto,
          trailing: _searchAction(u, l10n),
          onTap: () => UserProfileNavigation.openPublicProfile(
            context,
            userId: u.id,
            nicknameHint: u.nickname,
          ),
        );
      },
    );
  }

  Widget _searchAction(UserSearchResult u, AppLocalizations l10n) {
    if (u.isFriend) {
      return const SizedBox.shrink();
    }
    if (u.isPending) {
      return Text(
        l10n.friendsRequestSent,
        style: TextStyle(
          fontFamily: 'Lumiare',
          color: context.xiTextSecondary,
        ),
      );
    }
    return FilledButton.tonal(
      onPressed: () => _sendRequest(u),
      child: Text(l10n.friendsAdd),
    );
  }
}

class _BadgeCount extends StatelessWidget {
  const _BadgeCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: XiColors.royalBlue,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          fontFamily: 'Lumiare',
          fontSize: 11,
          color: XiColors.warmWhite,
        ),
      ),
    );
  }
}

class _FriendsList extends StatelessWidget {
  const _FriendsList({
    required this.friends,
    required this.onRemove,
    required this.onRefresh,
    required this.emptyTitle,
    required this.emptyBody,
  });

  final List<Friendship> friends;
  final void Function(Friendship) onRemove;
  final Future<void> Function() onRefresh;
  final String emptyTitle;
  final String emptyBody;

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) {
      return _EmptyFriendsState(
        icon: Icons.people_outline_rounded,
        title: emptyTitle,
        body: emptyBody,
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: friends.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final f = friends[index];
          return _FriendCard(
            userId: f.idUsuario,
            nickname: f.nickname,
            photoPath: f.foto,
            onMore: () => onRemove(f),
            onTap: () => UserProfileNavigation.openPublicProfile(
              context,
              userId: f.idUsuario,
              nicknameHint: f.nickname,
            ),
          );
        },
      ),
    );
  }
}

class _RequestsList extends StatelessWidget {
  const _RequestsList({
    required this.incoming,
    required this.outgoing,
    required this.onAccept,
    required this.onReject,
    required this.emptyTitle,
    required this.emptyBody,
  });

  final List<Friendship> incoming;
  final List<Friendship> outgoing;
  final void Function(Friendship) onAccept;
  final void Function(Friendship) onReject;
  final String emptyTitle;
  final String emptyBody;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (incoming.isEmpty && outgoing.isEmpty) {
      return _EmptyFriendsState(
        icon: Icons.mark_email_unread_outlined,
        title: emptyTitle,
        body: emptyBody,
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (incoming.isNotEmpty) ...[
          Text(
            l10n.friendsIncoming,
            style: TextStyle(
              fontFamily: 'Lumiare',
              color: context.xiTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...incoming.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _FriendCard(
                userId: f.idUsuario,
                nickname: f.nickname,
                photoPath: f.foto,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => onReject(f),
                      icon: const Icon(Icons.close_rounded),
                    ),
                    FilledButton(
                      onPressed: () => onAccept(f),
                      child: Text(l10n.friendsAccept),
                    ),
                  ],
                ),
                onTap: () => UserProfileNavigation.openPublicProfile(
                  context,
                  userId: f.idUsuario,
                  nicknameHint: f.nickname,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (outgoing.isNotEmpty) ...[
          Text(
            l10n.friendsOutgoing,
            style: TextStyle(
              fontFamily: 'Lumiare',
              color: context.xiTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...outgoing.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _FriendCard(
                userId: f.idUsuario,
                nickname: f.nickname,
                photoPath: f.foto,
                trailing: Text(
                  l10n.friendsRequestSent,
                  style: TextStyle(
                    fontFamily: 'Lumiare',
                    color: context.xiTextSecondary,
                  ),
                ),
                onTap: () => UserProfileNavigation.openPublicProfile(
                  context,
                  userId: f.idUsuario,
                  nicknameHint: f.nickname,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _FriendCard extends StatelessWidget {
  const _FriendCard({
    required this.userId,
    required this.nickname,
    this.photoPath,
    this.trailing,
    this.onMore,
    this.onTap,
  });

  final int userId;
  final String nickname;
  final String? photoPath;
  final Widget? trailing;
  final VoidCallback? onMore;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.xiCardSurface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: context.xiBorderSubtle),
            borderRadius: BorderRadius.circular(16),
            boxShadow: context.xiCardShadow,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              UserProfileAvatar(
                userId: userId,
                photoPath: photoPath,
                nickname: nickname,
                size: 48,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nickname,
                      style: TextStyle(
                        fontFamily: 'Lumiare',
                        fontSize: 15,
                        color: context.xiTextPrimary,
                      ),
                    ),
                    Text(
                      UserPublicTag.format(userId),
                      style: TextStyle(
                        fontFamily: 'Lumiare',
                        fontSize: 11,
                        color: context.xiTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              if (onMore != null)
                IconButton(
                  onPressed: onMore,
                  icon: const Icon(Icons.more_horiz_rounded),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyFriendsState extends StatelessWidget {
  const _EmptyFriendsState({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 52,
              color: XiColors.royalBlue.withValues(alpha: 0.65),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Lumiare',
                fontSize: 16,
                color: context.xiTextPrimary,
              ),
            ),
            if (body.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Lumiare',
                  fontSize: 13,
                  color: context.xiTextSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
