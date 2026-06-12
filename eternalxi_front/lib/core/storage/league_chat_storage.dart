import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StoredLeagueChatMessage {
  const StoredLeagueChatMessage({
    required this.author,
    required this.text,
    required this.isMine,
    required this.sentAtIso,
    this.photoUrl,
    this.avatarInitial,
  });

  final String author;
  final String text;
  final bool isMine;
  final String sentAtIso;
  final String? photoUrl;
  final String? avatarInitial;

  Map<String, dynamic> toJson() => {
        'author': author,
        'text': text,
        'isMine': isMine,
        'sentAtIso': sentAtIso,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (avatarInitial != null) 'avatarInitial': avatarInitial,
      };

  factory StoredLeagueChatMessage.fromJson(Map<String, dynamic> json) {
    return StoredLeagueChatMessage(
      author: json['author']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      isMine: json['isMine'] == true,
      sentAtIso: json['sentAtIso']?.toString() ?? '',
      photoUrl: json['photoUrl']?.toString(),
      avatarInitial: json['avatarInitial']?.toString(),
    );
  }
}

/// Mensajes de chat de liga en local hasta exista API compartida.
class LeagueChatStorage {
  LeagueChatStorage(this._prefs);

  final SharedPreferences _prefs;

  static Future<LeagueChatStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LeagueChatStorage(prefs);
  }

  static String _key(int leagueId) => 'league_chat_v1_$leagueId';

  List<StoredLeagueChatMessage> readMessages(int leagueId) {
    final raw = _prefs.getString(_key(leagueId));
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }
      return decoded
          .whereType<Map>()
          .map((e) => StoredLeagueChatMessage.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .where((m) => m.text.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> writeMessages(
    int leagueId,
    List<StoredLeagueChatMessage> messages,
  ) async {
    final payload = jsonEncode(messages.map((m) => m.toJson()).toList());
    await _prefs.setString(_key(leagueId), payload);
  }
}
