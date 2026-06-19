import 'package:eternal_xi/features/clash/cards/domain/clash_json_helpers.dart';

/// Categoría de un topic de la guía Clash.
enum ClashHelpCategory {
  gettingStarted('getting_started'),
  cards('cards'),
  match('match'),
  progress('progress'),
  rewards('rewards');

  const ClashHelpCategory(this.id);

  final String id;

  static ClashHelpCategory fromId(String? raw) {
    if (raw == null || raw.isEmpty) {
      return ClashHelpCategory.gettingStarted;
    }
    for (final value in ClashHelpCategory.values) {
      if (value.id == raw) {
        return value;
      }
    }
    return ClashHelpCategory.gettingStarted;
  }
}

/// Sección de contenido dentro de un topic.
class ClashHelpSection {
  const ClashHelpSection({
    required this.title,
    required this.body,
    this.bullets = const [],
  });

  final String title;
  final String body;
  final List<String> bullets;

  factory ClashHelpSection.fromJson(Map<String, dynamic> json) {
    final bulletsRaw = json['bullets'];
    return ClashHelpSection(
      title: clashRequireString(json['title'], 'title'),
      body: json['body']?.toString() ?? '',
      bullets: bulletsRaw is List
          ? bulletsRaw.map((item) => item.toString()).toList(growable: false)
          : const [],
    );
  }
}

/// Ruta relacionada opcional para saltar desde un topic.
class ClashHelpRelatedRoute {
  const ClashHelpRelatedRoute({required this.path, this.label});

  final String path;
  final String? label;

  factory ClashHelpRelatedRoute.fromJson(Map<String, dynamic> json) {
    return ClashHelpRelatedRoute(
      path: clashRequireString(json['path'], 'path'),
      label: clashOptionalString(json['label']),
    );
  }
}

/// Topic de ayuda local Clash (Fase 51).
class ClashHelpTopic {
  const ClashHelpTopic({
    required this.id,
    required this.title,
    required this.summary,
    required this.icon,
    required this.category,
    required this.sections,
    this.relatedRoutes = const [],
  });

  final String id;
  final String title;
  final String summary;
  final String icon;
  final ClashHelpCategory category;
  final List<ClashHelpSection> sections;
  final List<ClashHelpRelatedRoute> relatedRoutes;

  factory ClashHelpTopic.fromJson(Map<String, dynamic> json) {
    final sectionsRaw = json['sections'] as List? ?? const [];
    final routesRaw = json['relatedRoutes'] as List? ?? const [];
    return ClashHelpTopic(
      id: clashRequireString(json['id'], 'id'),
      title: clashRequireString(json['title'], 'title'),
      summary: clashRequireString(json['summary'], 'summary'),
      icon: json['icon']?.toString() ?? 'help_outline',
      category: ClashHelpCategory.fromId(json['category']?.toString()),
      sections: sectionsRaw
          .map(
            (item) => ClashHelpSection.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
      relatedRoutes: routesRaw
          .map(
            (item) => ClashHelpRelatedRoute.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
    );
  }

  bool matchesQuery(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }
    if (title.toLowerCase().contains(normalized) ||
        summary.toLowerCase().contains(normalized)) {
      return true;
    }
    for (final section in sections) {
      if (section.title.toLowerCase().contains(normalized) ||
          section.body.toLowerCase().contains(normalized)) {
        return true;
      }
      for (final bullet in section.bullets) {
        if (bullet.toLowerCase().contains(normalized)) {
          return true;
        }
      }
    }
    return false;
  }
}
