import 'package:flutter/material.dart';

class RewardRarityStyle {
  const RewardRarityStyle({
    required this.label,
    required this.gradient,
    required this.border,
    required this.glow,
    required this.badgeBackground,
    required this.badgeForeground,
  });

  final String label;
  final List<Color> gradient;
  final Color border;
  final Color glow;
  final Color badgeBackground;
  final Color badgeForeground;
}

RewardRarityStyle styleForRarity(String? rarity) {
  final r = (rarity ?? '').trim().toUpperCase();
  switch (r) {
    case 'NORMAL':
      return RewardRarityStyle(
        label: 'Normal',
        gradient: const [
          Color(0xFF1E3A5F),
          Color(0xFF0D47A1),
          Color(0xFF1565C0),
        ],
        border: const Color(0xFF64B5F6),
        glow: const Color(0x662196F3),
        badgeBackground: const Color(0xFF1976D2),
        badgeForeground: Colors.white,
      );
    case 'SPECIAL':
      return RewardRarityStyle(
        label: 'Especial',
        gradient: const [
          Color(0xFF311B92),
          Color(0xFF4527A0),
          Color(0xFF6A1B9A),
        ],
        border: const Color(0xFFCE93D8),
        glow: const Color(0x66AB47BC),
        badgeBackground: const Color(0xFF8E24AA),
        badgeForeground: Colors.white,
      );
    case 'SUPER_RARE':
      return RewardRarityStyle(
        label: 'Superrara',
        gradient: const [
          Color(0xFF4E1609),
          Color(0xFFBF360C),
          Color(0xFFE65100),
        ],
        border: const Color(0xFFFFAB40),
        glow: const Color(0x88FF6D00),
        badgeBackground: const Color(0xFFFF6F00),
        badgeForeground: Colors.black,
      );
    case 'LEGENDARY':
      return RewardRarityStyle(
        label: 'Legendaria',
        gradient: const [
          Color(0xFF3E2723),
          Color(0xFF6D4C41),
          Color(0xFFFFB300),
        ],
        border: const Color(0xFFFFE082),
        glow: const Color(0x99FFC107),
        badgeBackground: const Color(0xFFFFC107),
        badgeForeground: const Color(0xFF3E2723),
      );
    case 'BASIC':
    default:
      return RewardRarityStyle(
        label: r == 'BASIC' ? 'Básica' : (r.isEmpty ? 'Carta' : r),
        gradient: const [
          Color(0xFF263238),
          Color(0xFF37474F),
          Color(0xFF546E7A),
        ],
        border: const Color(0xFFBCAAA4),
        glow: const Color(0x448D6E63),
        badgeBackground: const Color(0xFF5D4037),
        badgeForeground: const Color(0xFFFFE0B2),
      );
  }
}

double rarityGlowSigma(String? rarity) {
  final r = (rarity ?? '').trim().toUpperCase();
  if (r == 'LEGENDARY' || r == 'SUPER_RARE') {
    return 28;
  }
  if (r == 'SPECIAL') {
    return 22;
  }
  return 14;
}
