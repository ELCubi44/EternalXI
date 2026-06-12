import 'dart:async';

import 'package:eternal_xi/app/icons/xi_icons.dart';
import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/core/network/api_exception.dart';
import 'package:eternal_xi/data/models/league_chat_message.dart';
import 'package:eternal_xi/data/services/leagues_api_service.dart';
import 'package:eternal_xi/features/leagues/shell/league_shell_data.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class _ChatMessage {
  const _ChatMessage({
    required this.id,
    required this.author,
    required this.text,
    required this.isMine,
    required this.sentAt,
    this.photoUrl,
    this.avatarInitial,
  });

  final int id;
  final String author;
  final String text;
  final bool isMine;
  final DateTime sentAt;
  final String? photoUrl;
  final String? avatarInitial;

  factory _ChatMessage.fromApi(LeagueChatMessage msg, int myUserId) {
    final nick = msg.nickname.trim();
    return _ChatMessage(
      id: msg.id,
      author: nick.isEmpty ? '—' : nick,
      text: msg.texto,
      isMine: msg.idUsuario == myUserId,
      sentAt: msg.creadoEn ?? DateTime.now(),
      photoUrl: msg.resolvedPhotoUrl(),
      avatarInitial: nick.isNotEmpty ? nick[0].toUpperCase() : '?',
    );
  }
}

class LeagueTabChat extends StatefulWidget {
  const LeagueTabChat({super.key});

  @override
  State<LeagueTabChat> createState() => _LeagueTabChatState();
}

class _LeagueTabChatState extends State<LeagueTabChat>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _inputFocus = FocusNode();
  final List<_ChatMessage> _messages = [];
  Timer? _pollTimer;
  bool _loading = true;
  bool _sending = false;
  String? _error;
  int? _loadedLeagueId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  int _maxMessageId() {
    if (_messages.isEmpty) return 0;
    return _messages.map((m) => m.id).reduce((a, b) => a > b ? a : b);
  }

  void _startPolling(LeagueShellData shell) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      _fetchNewMessages(shell, scrollIfNearBottom: true);
    });
  }

  Future<void> _bootstrap() async {
    final shell = LeagueShellData.maybeOf(context);
    if (shell == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    await _loadRecent(shell, showSpinner: true);
    _startPolling(shell);
  }

  Future<void> _loadRecent(LeagueShellData shell, {required bool showSpinner}) async {
    if (showSpinner) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final api = context.read<LeaguesApiService>();
      final rows = await api.getLeagueChatMessages(
        idLiga: shell.leagueId,
        idUsuario: shell.idUsuario,
        recent: true,
        limit: 100,
      );
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(
            rows.map((m) => _ChatMessage.fromApi(m, shell.idUsuario)),
          );
        _loadedLeagueId = shell.leagueId;
        _loading = false;
        _error = null;
      });
      _scrollToBottom(animated: false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _fetchNewMessages(
    LeagueShellData shell, {
    required bool scrollIfNearBottom,
  }) async {
    if (_loading || _loadedLeagueId != shell.leagueId) return;
    final afterId = _maxMessageId();
    if (afterId <= 0) return;

    try {
      final api = context.read<LeaguesApiService>();
      final rows = await api.getLeagueChatMessages(
        idLiga: shell.leagueId,
        idUsuario: shell.idUsuario,
        afterId: afterId,
        limit: 50,
      );
      if (!mounted || rows.isEmpty) return;

      final shouldScroll = scrollIfNearBottom && _isNearBottom();
      setState(() {
        final existing = _messages.map((m) => m.id).toSet();
        for (final row in rows) {
          if (existing.contains(row.id)) continue;
          _messages.add(_ChatMessage.fromApi(row, shell.idUsuario));
        }
      });
      if (shouldScroll) {
        _scrollToBottom(animated: true);
      }
    } catch (_) {
      // Polling silencioso: no interrumpe la lectura.
    }
  }

  bool _isNearBottom() {
    if (!_scrollCtrl.hasClients) return true;
    final max = _scrollCtrl.position.maxScrollExtent;
    return max - _scrollCtrl.offset < 120;
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _onRefresh() async {
    final shell = LeagueShellData.maybeOf(context);
    if (shell == null) return;
    await _loadRecent(shell, showSpinner: false);
  }

  void _scrollToBottom({required bool animated}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      final target = _scrollCtrl.position.maxScrollExtent;
      if (animated) {
        _scrollCtrl.animateTo(
          target,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      } else {
        _scrollCtrl.jumpTo(target);
      }
    });
  }

  Future<void> _send(LeagueShellData shell) async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      final api = context.read<LeaguesApiService>();
      final posted = await api.postLeagueChatMessage(
        idLiga: shell.leagueId,
        idUsuario: shell.idUsuario,
        texto: text,
      );
      if (!mounted) return;
      setState(() {
        _inputCtrl.clear();
        _sending = false;
        if (!_messages.any((m) => m.id == posted.id)) {
          _messages.add(_ChatMessage.fromApi(posted, shell.idUsuario));
        }
        _error = null;
      });
      _scrollToBottom(animated: true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = e.message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = context.l10n;
    final shell = LeagueShellData.maybeOf(context);
    if (shell == null) {
      return Center(
        child: Text(
          l10n.leagueContextError,
          style: TextStyle(color: context.xiTextSecondary),
        ),
      );
    }

    if (_loadedLeagueId != shell.leagueId && !_loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _loadRecent(shell, showSpinner: true);
        _startPolling(shell);
      });
    }

    return ColoredBox(
      color: context.xiBackground,
      child: Column(
        children: [
          if (_error != null && !_loading)
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
                      onPressed: () => _loadRecent(shell, showSpinner: false),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: GestureDetector(
              onTap: _dismissKeyboard,
              behavior: HitTestBehavior.translucent,
              child: RefreshIndicator(
                color: XiColors.royalBlue,
                backgroundColor: context.xiCardElevated,
                onRefresh: _onRefresh,
                child: _loading
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 240),
                          Center(child: CircularProgressIndicator()),
                        ],
                      )
                    : _messages.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        children: [
                          SizedBox(
                            height: MediaQuery.sizeOf(context).height * 0.35,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Text(
                                  l10n.chatEmpty,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Lumiare',
                                    fontSize: 14,
                                    color: context.xiTextSecondary,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        physics: const AlwaysScrollableScrollPhysics(),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          return _WhatsAppMessageRow(
                            message: _messages[index],
                          );
                        },
                      ),
              ),
            ),
          ),
          _ChatComposer(
            controller: _inputCtrl,
            focusNode: _inputFocus,
            hint: l10n.chatHint,
            dismissLabel: l10n.chatDismissKeyboard,
            sending: _sending,
            onSend: () => _send(shell),
            onDismissKeyboard: _dismissKeyboard,
          ),
        ],
      ),
    );
  }
}

class _WhatsAppMessageRow extends StatelessWidget {
  const _WhatsAppMessageRow({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    final bubbleColor = isMine
        ? XiColors.royalBlue
        : context.xiChatIncomingBubble;
    final textColor = isMine ? XiColors.warmWhite : context.xiTextPrimary;
    final nickColor = isMine ? XiColors.royalBlue : XiColors.royalBlue;

    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(14),
          topRight: const Radius.circular(14),
          bottomLeft: Radius.circular(isMine ? 14 : 4),
          bottomRight: Radius.circular(isMine ? 4 : 14),
        ),
        color: bubbleColor,
        border: isMine
            ? null
            : Border.all(color: context.xiBorderSubtle),
        boxShadow: isMine ? null : context.xiCardShadow,
      ),
      child: Text(
        message.text,
        style: TextStyle(
          fontFamily: 'Lumiare',
          fontSize: 14,
          color: textColor,
          height: 1.35,
        ),
      ),
    );

    final avatar = _ChatAvatar(
      photoUrl: message.photoUrl,
      initial: message.avatarInitial ?? '?',
      isMine: isMine,
    );

    final nick = Padding(
      padding: EdgeInsets.only(
        left: isMine ? 0 : 4,
        right: isMine ? 4 : 0,
        bottom: 3,
      ),
      child: Text(
        message.author,
        style: TextStyle(
          fontFamily: 'Lumiare',
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: nickColor,
          letterSpacing: 0.3,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: isMine
            ? [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [nick, bubble],
                  ),
                ),
                const SizedBox(width: 8),
                avatar,
              ]
            : [
                avatar,
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [nick, bubble],
                  ),
                ),
              ],
      ),
    );
  }
}

class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({
    required this.photoUrl,
    required this.initial,
    required this.isMine,
  });

  final String? photoUrl;
  final String initial;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final ring = isMine ? XiColors.royalBlue : XiColors.classicGold;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ring.withValues(alpha: 0.55), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: ring.withValues(alpha: 0.2),
            blurRadius: 6,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: photoUrl != null
          ? Image.network(
              photoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _initialFallback(ring),
            )
          : _initialFallback(ring),
    );
  }

  Widget _initialFallback(Color ring) {
    return ColoredBox(
      color: ring.withValues(alpha: 0.15),
      child: Center(
        child: Text(
          initial.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Lumiare',
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: ring,
          ),
        ),
      ),
    );
  }
}

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({
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
            icon: Icon(
              Icons.keyboard_hide_rounded,
              color: context.xiTextSecondary,
            ),
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
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(
                    color: XiColors.royalBlue,
                    width: 1.5,
                  ),
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
                boxShadow: [
                  BoxShadow(
                    color: XiColors.royalBlue.withValues(alpha: 0.25),
                    blurRadius: 10,
                  ),
                ],
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
