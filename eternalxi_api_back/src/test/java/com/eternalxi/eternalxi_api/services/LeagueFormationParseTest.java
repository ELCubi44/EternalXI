package com.eternalxi.eternalxi_api.services;

import com.eternalxi.eternalxi_api.config.LeagueAutomationProperties;
import org.junit.jupiter.api.Test;

import java.lang.reflect.Method;

import static org.junit.jupiter.api.Assertions.assertEquals;

class LeagueFormationParseTest {

  @Test
  void parse433() throws Exception {
    assertFormation("4-3-3", 4, 3, 3);
  }

  @Test
  void parse4231() throws Exception {
    assertFormation("4-2-3-1", 4, 5, 1);
  }

  @Test
  void parse442() throws Exception {
    assertFormation("4-4-2", 4, 4, 2);
  }

  @Test
  void parse352() throws Exception {
    assertFormation("3-5-2", 3, 5, 2);
  }

  @Test
  void parse550() throws Exception {
    assertFormation("5-5-0", 5, 5, 0);
  }

  private void assertFormation(String raw, int def, int med, int del) throws Exception {
    LeagueSimulationService svc = new LeagueSimulationService(null, null, null, new LeagueAutomationProperties());
    Method m = LeagueSimulationService.class.getDeclaredMethod("parseTeamFormation", String.class);
    m.setAccessible(true);
    Object result = m.invoke(svc, raw);
    Method defM = result.getClass().getDeclaredMethod("def");
    Method medM = result.getClass().getDeclaredMethod("med");
    Method delM = result.getClass().getDeclaredMethod("del");
    assertEquals(def, defM.invoke(result));
    assertEquals(med, medM.invoke(result));
    assertEquals(del, delM.invoke(result));
  }
}
