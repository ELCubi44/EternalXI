import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:flutter/material.dart';

/// L�nea t�ctica de un desaf�o Cadena XI (mazo por posici�n).
enum ClashTrialLine {
  goalkeeper,
  defense,
  midfield,
  attack;

  List<ClashPosition> get positions => switch (this) {
    ClashTrialLine.goalkeeper => [ClashPosition.goalkeeper],
    ClashTrialLine.defense => [
      ClashPosition.centreBack,
      ClashPosition.fullBack,
    ],
    ClashTrialLine.midfield => [
      ClashPosition.defensiveMidfielder,
      ClashPosition.attackingMidfielder,
    ],
    ClashTrialLine.attack => [ClashPosition.winger, ClashPosition.striker],
  };

  IconData get icon => switch (this) {
    ClashTrialLine.goalkeeper => Icons.sports_handball_rounded,
    ClashTrialLine.defense => Icons.shield_rounded,
    ClashTrialLine.midfield => Icons.swap_horiz_rounded,
    ClashTrialLine.attack => Icons.bolt_rounded,
  };

  String get displayNameEs => switch (this) {
    ClashTrialLine.goalkeeper => 'Portero',
    ClashTrialLine.defense => 'Defensa',
    ClashTrialLine.midfield => 'Mediocampo',
    ClashTrialLine.attack => 'Ataque',
  };

  static ClashTrialLine fromJson(Object? value) {
    final raw = value?.toString().trim().toLowerCase();
    return switch (raw) {
      'goalkeeper' || 'portero' || 'gk' => ClashTrialLine.goalkeeper,
      'defense' || 'defensa' || 'def' => ClashTrialLine.defense,
      'midfield' || 'mediocampo' || 'mid' => ClashTrialLine.midfield,
      'attack' || 'ataque' || 'att' => ClashTrialLine.attack,
      _ => throw FormatException('L�nea de desaf�o desconocida: $value'),
    };
  }

  String toJson() => name;
}
