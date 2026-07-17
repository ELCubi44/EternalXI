import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_rarity.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_type.dart';
import 'package:flutter/material.dart';

/// Rutas de assets epicos Clash (fondos, marcos, auras, iconos).
abstract final class ClashEpicAssets {
  static const _base = 'assets/images/clash/epic';

  static String detailBackground(ClashRarity rarity) => switch (rarity) {
    ClashRarity.n => '$_base/backgrounds/bg_detail_n.png',
    ClashRarity.r => '$_base/backgrounds/bg_detail_r.png',
    ClashRarity.sr => '$_base/backgrounds/bg_detail_sr.png',
    ClashRarity.lr => '$_base/backgrounds/bg_detail_lr.png',
    ClashRarity.xi => '$_base/backgrounds/bg_detail_xi.png',
  };

  static String detailBackgroundForTeam(String team, ClashRarity rarity) {
    if (team == 'Eternal XI' && rarity == ClashRarity.xi) {
      return '$_base/backgrounds/bg_detail_xi_eternal.png';
    }
    return detailBackground(rarity);
  }

  static String rarityBadgeFrame(ClashRarity rarity) => switch (rarity) {
    ClashRarity.n => '$_base/frames/badge_frame_n.png',
    ClashRarity.r => '$_base/frames/badge_frame_r.png',
    ClashRarity.sr => '$_base/frames/badge_frame_sr.png',
    ClashRarity.lr => '$_base/frames/badge_frame_lr.png',
    ClashRarity.xi => '$_base/frames/badge_frame_xi.png',
  };

  static String rarityIcon(ClashRarity rarity) => switch (rarity) {
    ClashRarity.n => '$_base/rarities/icon_rarity_n.png',
    ClashRarity.r => '$_base/rarities/icon_rarity_r.png',
    ClashRarity.sr => '$_base/rarities/icon_rarity_sr.png',
    ClashRarity.lr => '$_base/rarities/icon_rarity_lr.png',
    ClashRarity.xi => '$_base/rarities/icon_rarity_xi.png',
  };

  static String positionIcon(ClashPosition position) => switch (position) {
    ClashPosition.goalkeeper => '$_base/positions/icon_pos_gk.png',
    ClashPosition.centreBack => '$_base/positions/icon_pos_cb.png',
    ClashPosition.fullBack => '$_base/positions/icon_pos_fb.png',
    ClashPosition.defensiveMidfielder => '$_base/positions/icon_pos_dm.png',
    ClashPosition.attackingMidfielder => '$_base/positions/icon_pos_am.png',
    ClashPosition.winger => '$_base/positions/icon_pos_wg.png',
    ClashPosition.striker => '$_base/positions/icon_pos_st.png',
  };

  static String auraGlow(ClashRarity rarity) =>
      rarity == ClashRarity.xi || rarity == ClashRarity.lr
      ? '$_base/auras/aura_glow_xi.png'
      : '$_base/auras/aura_glow_default.png';

  static const statsPanel = '$_base/frames/frame_stats_panel.png';
  static const nameplate = '$_base/frames/frame_nameplate.png';
  static const pwrBadge = '$_base/frames/frame_pwr_badge.png';
  static const gachaBannerEternalXi =
      '$_base/banners/banner_gacha_eternal_xi.png';
  static const teamPersonajesIcon = '$_base/ui/icon_team_personajes.png';
  static const clashEnergyIcon = '$_base/ui/icon_clash_energy.png';
  /// Provisional hasta que elijas gemas (A Estela / B Orbe / C Prisma / D Sello).
  static const clashGachaGemIcon = '$_base/ui/icon_gacha_gem_a_estela.png';

  static const statPar = '$_base/stats/icon_stat_par.png';
  static const statDef = '$_base/stats/icon_stat_def.png';
  static const statPas = '$_base/stats/icon_stat_pas.png';
  static const statReg = '$_base/stats/icon_stat_reg.png';
  static const statTir = '$_base/stats/icon_stat_tir.png';
  static const statPt = '$_base/stats/icon_stat_pt.png';
  static const statRes = '$_base/stats/icon_stat_res.png';

  static String statIcon(ClashEpicStatKind kind) => switch (kind) {
    ClashEpicStatKind.par => statPar,
    ClashEpicStatKind.def => statDef,
    ClashEpicStatKind.pas => statPas,
    ClashEpicStatKind.reg => statReg,
    ClashEpicStatKind.tir => statTir,
    ClashEpicStatKind.pt => statPt,
    ClashEpicStatKind.res => statRes,
  };

  /// Iconos de tipo de supertecnica (mismos assets coloreados de stats).
  static String techniqueTypeIcon(ClashTechniqueType type) => switch (type) {
    ClashTechniqueType.save => statPar,
    ClashTechniqueType.defense => statDef,
    ClashTechniqueType.dribble => statReg,
    ClashTechniqueType.shot => statTir,
  };

  static Color techniqueTypeColor(ClashTechniqueType type) => switch (type) {
    ClashTechniqueType.save => const Color(0xFF41B978),
    ClashTechniqueType.defense => const Color(0xFF2457C5),
    ClashTechniqueType.dribble => const Color(0xFF9D6BFF),
    ClashTechniqueType.shot => const Color(0xFFF47A24),
  };

  static Color statColor(ClashEpicStatKind kind) => switch (kind) {
    ClashEpicStatKind.par => const Color(0xFF41B978),
    ClashEpicStatKind.def => const Color(0xFF2457C5),
    ClashEpicStatKind.pas => const Color(0xFF8FD9FF),
    ClashEpicStatKind.reg => const Color(0xFF9D6BFF),
    ClashEpicStatKind.tir => const Color(0xFFF47A24),
    ClashEpicStatKind.pt => const Color(0xFFD9A441),
    ClashEpicStatKind.res => const Color(0xFF59606D),
  };
}

enum ClashEpicStatKind { par, def, pas, reg, tir, pt, res }
