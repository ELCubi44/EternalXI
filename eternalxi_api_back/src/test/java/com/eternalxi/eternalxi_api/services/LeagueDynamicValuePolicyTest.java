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
    assertTrue(cheapPct > expensivePct * 1.2, "subida % mayor en barato");
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
    double parCheap = LeagueDynamicValuePolicy.fantasyParMeanPointsFromMarket(900_000L, "MED");
    double parMid = LeagueDynamicValuePolicy.fantasyParMeanPointsFromMarket(8_000_000L, "MED");
    assertTrue(parCheap < parMid);
    assertEquals(3.05, parCheap, 0.35);
  }

  @Test
  void delAndMedShareSimilarParAtSamePrice() {
    long value = 25_000_000L;
    double delPar = LeagueDynamicValuePolicy.fantasyParMeanPointsFromMarket(value, "DEL");
    double medPar = LeagueDynamicValuePolicy.fantasyParMeanPointsFromMarket(value, "MED");
    assertTrue(Math.abs(delPar - medPar) < 0.35, "DEL y MED deben tener par cercano");
  }

  @Test
  void delAndMedShareSimilarInitialPriceAtSameOvr() {
    long delValue = pricing.calculateValueFromDynamicRating(84.0, "DEL");
    long medValue = pricing.calculateValueFromDynamicRating(84.0, "MED");
    assertEquals(delValue, medValue, "misma OVR → mismo precio DEL/MED");
  }

  @Test
  void fatigueReducesPerformanceModifier() {
    assertEquals(1.0, LeagueDynamicValuePolicy.fatiguePerformanceModifier(0), 0.001);
    assertTrue(LeagueDynamicValuePolicy.fatiguePerformanceModifier(80) < 0.92);
    assertTrue(LeagueDynamicValuePolicy.fatiguePerformanceModifier(100) < 0.88);
  }

  @Test
  void porteroParMuchHigherThanMedAtSamePrice() {
    long value = 12_000_000L;
    double porPar = LeagueDynamicValuePolicy.fantasyParMeanPointsFromMarket(value, "POR");
    double medPar = LeagueDynamicValuePolicy.fantasyParMeanPointsFromMarket(value, "MED");
    assertTrue(porPar > medPar * 1.45, "portero debe exigir más puntos para subir");
  }

  @Test
  void porteroCannotExceedRatingCap() {
    assertEquals(95.0, LeagueDynamicValuePolicy.maxFantasyRatingCap("POR"), 0.001);
    assertEquals(99.0, LeagueDynamicValuePolicy.maxFantasyRatingCap("MED"), 0.001);
  }

  @Test
  void estimateRatingRespectsPositionCap() {
    long porValueAt99 = pricing.calculateValueFromDynamicRating(99.0, "POR");
    double porRating = pricing.estimateRatingFromMarketValue(porValueAt99, "POR");
    assertTrue(porRating <= 95.0, "POR no debe mostrar OVR > 95 aunque el precio sea de estrella");

    long defValueAt99 = pricing.calculateValueFromDynamicRating(99.0, "DEF");
    double defRating = pricing.estimateRatingFromMarketValue(defValueAt99, "DEF");
    assertTrue(defRating <= 97.0, "DEF no debe mostrar OVR > 97");
  }

  @Test
  void defParNotMuchHigherThanMedAtSamePrice() {
    long value = 12_000_000L;
    double defPar = LeagueDynamicValuePolicy.fantasyParMeanPointsFromMarket(value, "DEF");
    double medPar = LeagueDynamicValuePolicy.fantasyParMeanPointsFromMarket(value, "MED");
    assertTrue(defPar < medPar * 1.12, "DEF no debe exigir par desproporcionado frente a MED");
  }

  @Test
  void porteroRisesSlowerThanMedWithSameStrongPerformance() {
    long value = 8_000_000L;
    double ovr = 86.0;
    double strongIndex = 13.0;

    double porDelta =
        LeagueDynamicValuePolicy.boostPositiveDeltaRating(
            (strongIndex - 10.0)
                * LeagueDynamicValuePolicy.sensitivityByMarketProfile(value, ovr, "POR"),
            LeagueDynamicValuePolicy.maxPositiveDeltaRatingByOvr(ovr, value, "POR"),
            value);
    double medDelta =
        LeagueDynamicValuePolicy.boostPositiveDeltaRating(
            (strongIndex - 10.0)
                * LeagueDynamicValuePolicy.sensitivityByMarketProfile(value, ovr, "MED"),
            LeagueDynamicValuePolicy.maxPositiveDeltaRatingByOvr(ovr, value, "MED"),
            value);

    assertTrue(porDelta < medDelta, "portero debe subir menos OVR con mismo rendimiento");
  }
}
