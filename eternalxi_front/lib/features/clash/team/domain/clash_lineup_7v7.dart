import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';

/// Alineación Clash 7vs7 con 7 posiciones fijas (una carta por slot).
class ClashLineup7v7 {
  const ClashLineup7v7({
    required this.id,
    required this.name,
    required this.isActive,
    required this.slots,
    required this.lastModifiedAt,
  });

  static const int maxLineups = 3;

  static const List<ClashPosition> slotOrder = ClashPosition.values;

  final String id;
  final String name;
  final bool isActive;

  /// Posición → id de carta asignada (null = vacío).
  final Map<ClashPosition, String?> slots;
  final DateTime lastModifiedAt;

  String? cardIdFor(ClashPosition position) => slots[position];

  bool get isComplete => missingPositions.isEmpty;

  List<ClashPosition> get missingPositions => slotOrder
      .where((position) => slots[position] == null || slots[position]!.isEmpty)
      .toList();

  List<String> get assignedCardIds => slotOrder
      .map((p) => slots[p])
      .whereType<String>()
      .where((id) => id.isNotEmpty)
      .toList(growable: false);

  ClashLineup7v7 copyWith({
    String? name,
    bool? isActive,
    Map<ClashPosition, String?>? slots,
    DateTime? lastModifiedAt,
  }) {
    return ClashLineup7v7(
      id: id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      slots: slots ?? this.slots,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isActive': isActive,
    'slots': {
      for (final entry in slots.entries) entry.key.toJson(): entry.value,
    },
    'lastModifiedAt': lastModifiedAt.toIso8601String(),
  };

  factory ClashLineup7v7.fromJson(Map<String, dynamic> json) {
    final slotsRaw = json['slots'] as Map<String, dynamic>? ?? const {};
    final slots = <ClashPosition, String?>{};
    for (final position in ClashPosition.values) {
      final raw = slotsRaw[position.toJson()];
      slots[position] = raw?.toString();
    }

    return ClashLineup7v7(
      id: json['id'] as String,
      name: json['name'] as String,
      isActive: json['isActive'] == true,
      slots: slots,
      lastModifiedAt:
          DateTime.tryParse(json['lastModifiedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  static Map<ClashPosition, String?> emptySlots() => {
    for (final position in ClashPosition.values) position: null,
  };

  static List<ClashLineup7v7> createDefaultSet({DateTime? now}) {
    final timestamp = now ?? DateTime.now();
    return List.generate(maxLineups, (index) {
      return ClashLineup7v7(
        id: 'lineup-${index + 1}',
        name: 'Alineación ${index + 1}',
        isActive: index == 0,
        slots: emptySlots(),
        lastModifiedAt: timestamp,
      );
    });
  }
}
