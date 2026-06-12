import 'package:eternal_xi/app/icons/xi_icons.dart';
import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/core/constants/api_constants.dart';
import 'package:eternal_xi/features/auth/controller/auth_controller.dart';
import 'package:eternal_xi/features/leagues/shell/league_shell_data.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class _ChatMessage {
  const _ChatMessage({
    required this.author,
    required this.text,
    required this.isMine,
    required this.sentAt,
    this.photoUrl,
    this.avatarInitial,
  });

  final String author;
  final String text;
  final bool isMine;
  final DateTime sentAt;
  final String? photoUrl;
  final String? avatarInitial;
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
  final List<_ChatMessage> _messages = [];
  bool _seeded = false;

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _seedIfNeeded(LeagueShellData shell) {
    if (_seeded) return;
    _seeded = true;
    final l10n = context.l10n;
    final leagueName =
        shell.detail?.nombre.trim() ?? l10n.chatLeagueFallback;
    _messages.addAll([
      _ChatMessage(
        author: l10n.chatSystemAuthor,
        text: l10n.chatWelcomeMessage(leagueName),
        isMine: false,
        sentAt: DateTime.now().subtract(const Duration(hours: 2)),
        avatarInitial: 'S',
      ),
      _ChatMessage(
        author: l10n.chatSeedRivalAuthor,
        text: l10n.chatSeedRivalMessage,
        isMine: false,
        sentAt: DateTime.now().subtract(const Duration(minutes: 48)),
        avatarInitial: 'R',
      ),
    ]);
  }

  String? _myPhotoUrl() {
    final user = context.read<AuthController>().currentUser;
    if (user == null || !user.hasProfilePhoto) return null;
    return ApiConstants.userProfilePhotoUrl(
      user.id,
      cacheBuster: user.foto.hashCode,
    );
  }

  String _myNickname() {
    final nick = context.read<AuthController>().currentUser?.nickname ?? '';
    return nick.trim().isEmpty ? context.l10n.chatYou : nick.trim();
  }

  Future<void> _onRefresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {});
  }

  void _send(LeagueShellData shell) {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    final nick = _myNickname();
    setState(() {
      _messages.add(
        _ChatMessage(
          author: nick,
          text: text,
          isMine: true,
          sentAt: DateTime.now(),
          photoUrl: _myPhotoUrl(),
          avatarInitial: nick.isNotEmpty ? nick[0].toUpperCase() : '?',
        ),
      );
      _inputCtrl.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
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
    _seedIfNeeded(shell);

    return ColoredBox(
      color: context.xiBackground,
      child: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              color: XiColors.royalBlue,
              backgroundColor: context.xiCardElevated,
              onRefresh: _onRefresh,
              child: _messages.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
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
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return _WhatsAppMessageRow(message: _messages[index]);
                      },
                    ),
            ),
          ),
          _ChatComposer(
            controller: _inputCtrl,
            hint: l10n.chatHint,
            onSend: () => _send(shell),
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
    required this.hint,
    required this.onSend,
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback onSend;

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
          Expanded(
            child: TextField(
              controller: controller,
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
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [XiColors.royalBlue, XiColors.navyBlue],
                ),
                boxShadow: [
                  BoxShadow(
                    color: XiColors.royalBlue.withValues(alpha: 0.25),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Center(
                child: XiIcon(
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
