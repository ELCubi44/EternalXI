import 'package:eternal_xi/features/clash/cards/domain/clash_json_helpers.dart';
import 'package:eternal_xi/features/clash/news/domain/clash_news_type.dart';

/// Definición de noticia desde catálogo JSON local (Fase 31).
class ClashNewsItem {
  const ClashNewsItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.body,
    required this.type,
    required this.publishedAt,
    this.isPinned = false,
  });

  final String id;
  final String title;
  final String summary;
  final String body;
  final ClashNewsType type;
  final DateTime publishedAt;
  final bool isPinned;

  factory ClashNewsItem.fromJson(Map<String, dynamic> json) {
    final type = ClashNewsType.fromJson(json['type']);
    if (type == null) {
      throw FormatException('Tipo de noticia desconocido: ${json['type']}');
    }
    final publishedRaw = clashRequireString(json['publishedAt'], 'publishedAt');
    final publishedAt = DateTime.tryParse(publishedRaw);
    if (publishedAt == null) {
      throw FormatException('Fecha de publicación inválida: $publishedRaw');
    }
    return ClashNewsItem(
      id: clashRequireString(json['id'], 'id'),
      title: clashRequireString(json['title'], 'title'),
      summary: clashRequireString(json['summary'], 'summary'),
      body: clashRequireString(json['body'], 'body'),
      type: type,
      publishedAt: publishedAt,
      isPinned: json['isPinned'] == true,
    );
  }
}

/// Noticia con estado de lectura local.
class ClashNewsEntry {
  const ClashNewsEntry({required this.item, required this.isRead});

  final ClashNewsItem item;
  final bool isRead;

  ClashNewsEntry copyWith({ClashNewsItem? item, bool? isRead}) {
    return ClashNewsEntry(
      item: item ?? this.item,
      isRead: isRead ?? this.isRead,
    );
  }
}

/// Resumen para tarjeta de Inicio Clash.
class ClashNewsSummary {
  const ClashNewsSummary({required this.unreadCount, this.latestUnreadTitle});

  final int unreadCount;
  final String? latestUnreadTitle;

  bool get allCaughtUp => unreadCount == 0;
}
