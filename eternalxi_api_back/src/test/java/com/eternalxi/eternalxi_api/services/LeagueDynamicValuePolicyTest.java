package com.eternalxi.eternalxi_api.services;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class LeagueDynamicValuePolicyTest {

  private final LeaguePlayerPricingService pricing = new LeaguePlayerPricingService();

  @Test
  void bargainRisesFasterThanExpensiveForSameStrongPerformance() {
    long cheapValue = 1_200_000L;
    long expensiveValue = 120_000_000L;
    double ovr = 78.0;
    double strongIndex = 14.0;

    double cheapDelta =
        LeagueDynamicValuePolicy.boostPositiveDeltaRating(
            (strongIndex - 10.0) * LeagueDynamicValuePolicy.sensitivityByMarketProfile(cheapValue, ovr),
            LeagueDynamicValuePolicy.maxPositiveDeltaRatingByOvr(ovr, cheapValue),
            cheapValue);
    double expensiveDelta =
        LeagueDynamicValuePolicy.boostPositiveDeltaRating(
            (strongIndex - 10.0) * LeagueDynamicValuePolicy.sensitivityByMarketProfile(expensiveValue, 94.0),
            LeagueDynamicValuePolicy.maxPositiveDeltaRatingByOvr(94.0, expensiveValue),
            expensiveValue);

    assertTrue(cheapDelta > expensiveDelta, "barato debe subir más OVR por buen rendimiento");

    double cheapRating = ovr + cheapDelta;
    double expensiveRating = 94.0 + expensiveDelta;
    long cheapTarget =
        Math.round(
            pricing.calculateValueFromDynamicRating(cheapRating, "MED")
                * LeagueDynamicValuePolicy.formMultiplier(strongIndex, cheapValue));
    long expensiveTarget =
        Math.round(
            pricing.calculateValueFromDynamicRating(expensiveRating, "MED")
                * LeagueDynamicValuePolicy.formMultiplier(strongIndex, expensiveValue));

    long cheapAfter =
        LeagueDynamicValuePolicy.moveTowards(
            cheapValue,
            cheapTarget,
            LeagueDynamicValuePolicy.movementLimitPercentage(cheapValue, true));
    long expensiveAfter =
        LeagueDynamicValuePolicy.moveTowards(
            expensiveValue,
            expensiveTarget,
            LeagueDynamicValuePolicy.movementLimitPercentage(expensiveValue, true));

    double cheapPct = (cheapAfter - cheapValue) / (double) cheapValue;
    double expensivePct = (expensiveAfter - expensiveValue) / (double) expensiveValue;
    assertTrue(cheapPct > expensivePct * 1.5, "subida % mayor en barato");
  }

  @Test
  void riseLimitHigherThanFallForBargain() {
    long value = 800_000L;
    assertTrue(
        LeagueDynamicValuePolicy.movementLimitPercentage(value, true)
            > LeagueDynamicValuePolicy.movementLimitPercentage(value, false));
    assertTrue(
        LeagueDynamicValuePolicy.movementCapByValue(value, true)
            > LeagueDynamicValuePolicy.movementCapByValue(value, false));
  }

  @Test
  void lowerParForVeryCheapPlayers() {
    double parCheap = LeagueDynamicValuePolicy.fantasyParMeanPointsFromMarket(900_000L);
    double parMid = LeagueDynamicValuePolicy.fantasyParMeanPointsFromMarket(8_000_000L);
    assertTrue(parCheap < parMid);
    assertEquals(3.15, parCheap, 0.35);
  }
}
