import 'dart:async';

import 'package:eternal_xi/app/icons/xi_icons.dart';
import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/core/network/api_exception.dart';
import 'package:eternal_xi/data/models/league_dm_message.dart';
import 'package:eternal_xi/data/models/league_dm_thread.dart';
import 'package:eternal_xi/data/models/league_participant.dart';
import 'package:eternal_xi/data/services/leagues_api_service.dart';
import 'package:eternal_xi/data/services/user_api_service.dart';
import 'package:eternal_xi/features/leagues/shell/league_shell_data.dart';
import 'package:eternal_xi/features/profile/navigation/user_profile_navigation.dart';
import 'package:eternal_xi/shared/widgets/user_profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class LeaguePrivateChatPanel extends StatefulWidget {
  const LeaguePrivateChatPanel({
    super.key,
    required this.shell,
  });

  final LeagueShellData shell;

  @override
  State<LeaguePrivateChatPanel> createState() => _LeaguePrivateChatPanelState();
}

class _LeaguePrivateChatPanelState extends State<LeaguePrivateChatPanel> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _inputFocus = FocusNode();

  List<LeagueDmThread> _threads = [];
  List<LeagueDmMessage> _messages = [];
  LeagueDmPeer? _activePeer;
  Timer? _pollTimer;
  bool _loadingInbox = true;
  bool _loadingMessages = false;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInbox();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) => _poll());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _poll() async {
    if (!mounted) return;
    if (_activePeer == null) {
      await _loadInbox(silent: true);
    } else {
      await _loadMessages(silent: true);
    }
  }

  Future<void> _loadInbox({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _loadingInbox = true;
        _error = null;
      });
    }
    try {
      final api = context.read<LeaguesApiService>();
      final rows = await api.getLeagueDmThreads(
        idLiga: widget.shell.leagueId,
        idUsuario: widget.shell.idUsuario,
      );
      if (!mounted) return;
      setState(() {
        _threads = rows;
        _loadingInbox = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingInbox = false;
        if (!silent) {
          _error = e is ApiException ? e.message : e.toString();
        }
      });
    }
  }

  Future<void> _openPeer(LeagueDmPeer peer) async {
    setState(() {
      _activePeer = peer;
      _messages = [];
      _loadingMessages = true;
      _error = null;
    });
    await _loadMessages();
  }

  void _closeConversation() {
    setState(() {
      _activePeer = null;
      _messages = [];
    });
    _loadInbox();
  }

  Future<void> _loadMessages({bool silent = false}) async {
    final peer = _activePeer;
    if (peer == null) return;
    if (!silent && mounted) {
      setState(() => _loadingMessages = true);
    }
    try {
      final api = context.read<LeaguesApiService>();
      final rows = await api.getLeagueDmMessages(
        idLiga: widget.shell.leagueId,
        idUsuario: widget.shell.idUsuario,
        idPeer: peer.id,
        recent: true,
      );
      if (!mounted) return;
      setState(() {
        _messages = rows;
        _loadingMessages = false;
      });
      _scrollToEnd();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingMessages = false;
        if (!silent) {
          _error = e is ApiException ? e.message : e.toString();
        }
      });
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final peer = _activePeer;
    if (peer == null || _sending) return;
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    try {
      final api = context.read<LeaguesApiService>();
      final msg = await api.postLeagueDmMessage(
        idLiga: widget.shell.leagueId,
        idUsuario: widget.shell.idUsuario,
        idPeer: peer.id,
        texto: text,
      );
      if (!mounted) return;
      _inputCtrl.clear();
      setState(() {
        _messages = [..._messages, msg];
        _sending = false;
      });
      _scrollToEnd();
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            e is ApiException ? e.message : context.l10n.chatDmSendError,
          ),
        ),
      );
    }
  }

  Future<void> _showNewMessagePicker() async {
    final l10n = context.l10n;
    try {
      final api = context.read<LeaguesApiService>();
      final participants = await api.getParticipants(
        idLiga: widget.shell.leagueId,
        idUsuario: widget.shell.idUsuario,
      );
      if (!mounted) return;
      final others = participants
          .where((p) => p.idUsuario != widget.shell.idUsuario)
          .toList();
      if (others.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(l10n.chatDmNoMembers),
          ),
        );
        return;
      }
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        backgroundColor: context.xiCardElevated,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text(
                  l10n.chatDmPickMember,
                  style: TextStyle(
                    fontFamily: 'Lumiare',
                    fontSize: 16,
                    color: context.xiTextPrimary,
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: others.length,
                  itemBuilder: (context, index) {
                    final p = others[index];
                    return _ParticipantPickTile(
                      participant: p,
                      onTap: () {
                        Navigator.pop(ctx);
                        _openPeer(LeagueDmPeer.fromParticipant(p));
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(e is ApiException ? e.message : l10n.retry),
        ),
      );
    }
  }

  Future<void> _addFriend(LeagueDmPeer peer) async {
    final l10n = context.l10n;
    try {
      await context.read<UserApiService>().sendFriendRequest(
        idUsuario: widget.shell.idUsuario,
        idAmigo: peer.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(l10n.friendsRequestSent),
        ),
      );
      setState(() {
        _activePeer = peer.copyWith(esAmigo: false, solicitudPendiente: true);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(e is ApiException ? e.message : l10n.friendsRequestError),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_activePeer != null) {
      return _buildConversation(context);
    }
    return _buildInbox(context);
  }

  Widget _buildInbox(BuildContext context) {
    final l10n = context.l10n;
    return Stack(
      children: [
        Column(
          children: [
            if (_error != null && !_loadingInbox)
              Material(
                color: XiColors.error.withValues(alpha: 0.12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            fontFamily: 'Lumiare',
                            fontSize: 12,
                            color: XiColors.error,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _loadInbox(),
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                color: XiColors.royalBlue,
                backgroundColor: context.xiCardElevated,
                onRefresh: () => _loadInbox(),
                child: _loadingInbox
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 200),
                          Center(child: CircularProgressIndicator()),
                        ],
                      )
                    : _threads.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(height: MediaQuery.sizeOf(context).height * 0.22),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 36),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.lock_outline_rounded,
                                  size: 48,
                                  color: XiColors.royalBlue.withValues(alpha: 0.7),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  l10n.chatDmEmptyTitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Lumiare',
                                    fontSize: 16,
                                    color: context.xiTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.chatDmEmptyBody,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Lumiare',
                                    fontSize: 13,
                                    color: context.xiTextSecondary,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
                        itemCount: _threads.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final t = _threads[index];
                          return _DmThreadTile(
                            thread: t,
                            onTap: () => _openPeer(LeagueDmPeer.fromThread(t)),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: _showNewMessagePicker,
            backgroundColor: XiColors.royalBlue,
            foregroundColor: XiColors.warmWhite,
            icon: const Icon(Icons.edit_rounded),
            label: Text(
              l10n.chatDmNew,
              style: const TextStyle(
                fontFamily: 'Lumiare',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConversation(BuildContext context) {
    final l10n = context.l10n;
    final peer = _activePeer!;

    return Column(
      children: [
        Material(
          color: context.xiCardElevated,
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  onPressed: _closeConversation,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                _PeerAvatar(
                  userId: peer.id,
                  photoPath: peer.photoPath,
                  nickname: peer.nickname,
                  size: 40,
                  onTap: () => UserProfileNavigation.openPublicProfile(
                    context,
                    userId: peer.id,
                    nicknameHint: peer.nickname,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        peer.nickname,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Lumiare',
                          fontSize: 15,
                          color: context.xiTextPrimary,
                        ),
                      ),
                      if (peer.esAmigo)
                        Text(
                          l10n.friendsBadge,
                          style: const TextStyle(
                            fontFamily: 'Lumiare',
                            fontSize: 11,
                            color: XiColors.classicGold,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!peer.esAmigo && !peer.solicitudPendiente)
                  TextButton.icon(
                    onPressed: () => _addFriend(peer),
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: Text(l10n.friendsAdd),
                  )
                else if (peer.solicitudPendiente)
                  Text(
                    l10n.friendsRequestSent,
                    style: TextStyle(
                      fontFamily: 'Lumiare',
                      fontSize: 12,
                      color: context.xiTextSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _loadingMessages
              ? const Center(child: CircularProgressIndicator())
              : _messages.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      l10n.chatDmConversationEmpty,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Lumiare',
                        fontSize: 14,
                        color: context.xiTextSecondary,
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final m = _messages[index];
                    final isMine = m.idEmisor == widget.shell.idUsuario;
                    return _DmBubble(message: m, isMine: isMine);
                  },
                ),
        ),
        _DmComposer(
          controller: _inputCtrl,
          focusNode: _inputFocus,
          hint: l10n.chatDmHint,
          dismissLabel: l10n.chatDismissKeyboard,
          sending: _sending,
          onSend: _send,
          onDismissKeyboard: () => FocusScope.of(context).unfocus(),
        ),
      ],
    );
  }
}

class LeagueDmPeer {
  const LeagueDmPeer({
    required this.id,
    required this.nickname,
    required this.photoPath,
    required this.initial,
    this.esAmigo = false,
    this.solicitudPendiente = false,
  });

  final int id;
  final String nickname;
  final String photoPath;
  final String initial;
  final bool esAmigo;
  final bool solicitudPendiente;

  factory LeagueDmPeer.fromThread(LeagueDmThread t) {
    final nick = t.nicknamePeer.trim();
    return LeagueDmPeer(
      id: t.idPeer,
      nickname: nick.isEmpty ? '—' : nick,
      photoPath: t.fotoPeer,
      initial: nick.isNotEmpty ? nick[0].toUpperCase() : '?',
      esAmigo: t.esAmigo,
    );
  }

  factory LeagueDmPeer.fromParticipant(LeagueParticipant p) {
    final nick = p.nickname.trim();
    return LeagueDmPeer(
      id: p.idUsuario,
      nickname: nick.isEmpty ? '—' : nick,
      photoPath: p.fotoUsuario,
      initial: nick.isNotEmpty ? nick[0].toUpperCase() : '?',
    );
  }

  LeagueDmPeer copyWith({
    bool? esAmigo,
    bool? solicitudPendiente,
  }) {
    return LeagueDmPeer(
      id: id,
      nickname: nickname,
      photoPath: photoPath,
      initial: initial,
      esAmigo: esAmigo ?? this.esAmigo,
      solicitudPendiente: solicitudPendiente ?? this.solicitudPendiente,
    );
  }
}

class _DmThreadTile extends StatelessWidget {
  const _DmThreadTile({required this.thread, required this.onTap});

  final LeagueDmThread thread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nick = thread.nicknamePeer.trim();
    final time = thread.ultimoEn != null
        ? DateFormat.Hm().format(thread.ultimoEn!)
        : '';

    return Material(
      color: context.xiCardSurface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: context.xiBorderSubtle),
            borderRadius: BorderRadius.circular(16),
            boxShadow: context.xiCardShadow,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              _PeerAvatar(
                userId: thread.idPeer,
                photoPath: thread.fotoPeer,
                nickname: nick.isEmpty ? null : nick,
                size: 48,
                onTap: () => UserProfileNavigation.openPublicProfile(
                  context,
                  userId: thread.idPeer,
                  nicknameHint: nick.isEmpty ? null : nick,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            nick.isEmpty ? '�' : nick,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Lumiare',
                              fontSize: 15,
                              color: context.xiTextPrimary,
                            ),
                          ),
                        ),
                        if (time.isNotEmpty)
                          Text(
                            time,
                            style: TextStyle(
                              fontFamily: 'Lumiare',
                              fontSize: 11,
                              color: context.xiTextSecondary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            thread.ultimoTexto,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Lumiare',
                              fontSize: 13,
                              color: context.xiTextSecondary,
                            ),
                          ),
                        ),
                        if (thread.esAmigo) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: XiColors.classicGold,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: context.xiTextSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParticipantPickTile extends StatelessWidget {
  const _ParticipantPickTile({required this.participant, required this.onTap});

  final LeagueParticipant participant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nick = participant.nickname.trim();
    return ListTile(
      leading: _PeerAvatar(
        userId: participant.idUsuario,
        photoPath: participant.fotoUsuario,
        nickname: nick.isEmpty ? null : nick,
        size: 40,
        onTap: () => UserProfileNavigation.openPublicProfile(
          context,
          userId: participant.idUsuario,
          nicknameHint: nick.isEmpty ? null : nick,
        ),
      ),
      title: Text(
        nick.isEmpty ? '�' : nick,
        style: const TextStyle(fontFamily: 'Lumiare'),
      ),
      trailing: const Icon(Icons.chat_bubble_outline_rounded),
      onTap: onTap,
    );
  }
}

class _PeerAvatar extends StatelessWidget {
  const _PeerAvatar({
    required this.userId,
    required this.photoPath,
    this.nickname,
    this.size = 36,
    this.onTap,
  });

  final int userId;
  final String photoPath;
  final String? nickname;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return UserProfileAvatar(
      userId: userId,
      photoPath: photoPath.isEmpty ? null : photoPath,
      nickname: nickname,
      size: size,
      onTap: onTap,
    );
  }
}

class _DmBubble extends StatelessWidget {
  const _DmBubble({required this.message, required this.isMine});

  final LeagueDmMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMine
        ? XiColors.royalBlue
        : context.xiChatIncomingBubble;
    final textColor = isMine ? XiColors.warmWhite : context.xiTextPrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isMine ? 14 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 14),
                ),
                border: isMine
                    ? null
                    : Border.all(color: context.xiBorderSubtle),
              ),
              child: Text(
                message.texto,
                style: TextStyle(
                  fontFamily: 'Lumiare',
                  fontSize: 14,
                  color: textColor,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DmComposer extends StatelessWidget {
  const _DmComposer({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.dismissLabel,
    required this.sending,
    required this.onSend,
    required this.onDismissKeyboard,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final String dismissLabel;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onDismissKeyboard;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.xiCardSurface,
      padding: EdgeInsets.fromLTRB(
        10,
        8,
        10,
        8 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            tooltip: dismissLabel,
            onPressed: onDismissKeyboard,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.keyboard_hide_rounded, color: context.xiTextSecondary),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: !sending,
              minLines: 1,
              maxLines: 4,
              style: TextStyle(
                fontFamily: 'Lumiare',
                fontSize: 14,
                color: context.xiTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  fontFamily: 'Lumiare',
                  color: context.xiTextSecondary,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: context.xiChatInputFill,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(color: context.xiDivider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(color: context.xiDivider),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(22)),
                  borderSide: BorderSide(color: XiColors.royalBlue, width: 1.5),
                ),
              ),
              textInputAction: TextInputAction.newline,
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: sending ? null : onSend,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: sending
                      ? [
                          XiColors.royalBlue.withValues(alpha: 0.45),
                          XiColors.navyBlue.withValues(alpha: 0.45),
                        ]
                      : const [XiColors.royalBlue, XiColors.navyBlue],
                ),
              ),
              child: Center(
                child: sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: XiColors.warmWhite,
                        ),
                      )
                    : const XiIcon(
                        XiIconType.chat,
                        size: 20,
                        color: XiColors.warmWhite,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
