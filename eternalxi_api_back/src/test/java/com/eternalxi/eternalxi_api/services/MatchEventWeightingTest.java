package com.eternalxi.eternalxi_api.services;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertTrue;

class MatchEventWeightingTest {

  @Test
  void higherRatingGetsMoreWeightForAttackAndDefense() {
    double low = MatchEventWeighting.pickWeight(72, 72, "DEL", true);
    double high = MatchEventWeighting.pickWeight(88, 90, "DEL", true);
    assertTrue(high > low * 1.5);

    double lowRec = MatchEventWeighting.pickWeight(70, 71, "DEF", false);
    double highRec = MatchEventWeighting.pickWeight(85, 87, "DEF", false);
    assertTrue(highRec > lowRec * 1.25);
  }

  @Test
  void eliteGoalkeeperSlightlyMoreSaveEvents() {
    double base = MatchEventWeighting.saveEventChance(72, 0.90);
    double elite = MatchEventWeighting.saveEventChance(92, 0.90);
    assertTrue(elite > base);
  }
}
