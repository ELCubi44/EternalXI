package com.eternalxi.eternalxi_api.services;

import com.eternalxi.eternalxi_api.config.LeagueAutomationProperties;
import org.junit.jupiter.api.Test;

import java.lang.reflect.Constructor;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;

class LeagueStarterLoanDeficitTest {

  @Test
  void computeLoansNeededWhenTenStartersMissingDef() throws Exception {
    List<Object> starters = List.of(
        player("POR", 10),
        player("DEF", 9),
        player("DEF", 8),
        player("DEF", 7),
        player("MED", 6),
        player("MED", 5),
        player("MED", 4),
        player("DEL", 3),
        player("DEL", 2),
        player("DEL", 1)
    );
    Object formation = formation(4, 3, 3);
    assertEquals(1, invokeComputeStarterLoansNeeded(starters, formation));
  }

  @Test
  void computeLoansNeededWhenElevenStartersWrongLineBalance() throws Exception {
    List<Object> starters = new ArrayList<>(List.of(
        player("POR", 10),
        player("DEF", 9),
        player("DEF", 8),
        player("DEF", 7),
        player("MED", 6),
        player("MED", 5),
        player("MED", 4),
        player("MED", 3),
        player("DEL", 2),
        player("DEL", 1),
        player("DEL", 0)
    ));
    Object formation = formation(4, 3, 3);
    assertEquals(1, invokeComputeStarterLoansNeeded(starters, formation));
  }

  @Test
  void countFormationDeficitsFor433WithThreeDefenders() throws Exception {
    List<Object> starters = List.of(
        player("POR", 10),
        player("DEF", 9),
        player("DEF", 8),
        player("DEF", 7),
        player("MED", 6),
        player("MED", 5),
        player("MED", 4),
        player("DEL", 3),
        player("DEL", 2),
        player("DEL", 1)
    );
    Object formation = formation(4, 3, 3);
    assertEquals(1, invokeCountFormationStarterDeficits(starters, formation));
  }

  private static Object player(String pos, double score) throws Exception {
    Class<?> dataClass = Class.forName(
        "com.eternalxi.eternalxi_api.services.LeagueSimulationService$TeamPlayerData"
    );
    Constructor<?> ctor = dataClass.getDeclaredConstructors()[0];
    ctor.setAccessible(true);
    Object[] args = new Object[ctor.getParameterCount()];
    args[0] = 1L;
    args[1] = 1L;
    args[2] = "A";
    args[3] = "a";
    args[4] = pos;
    args[5] = 5.0;
    args[6] = "DISPONIBLE";
    args[7] = 0;
    args[8] = 0L;
    args[9] = 0.0;
    args[10] = 0.0;
    args[11] = score;
    args[12] = false;
    args[13] = "LIGA_JUGADOR";
    args[14] = null;
    args[15] = null;
    args[16] = null;
    return ctor.newInstance(args);
  }

  private static Object formation(int def, int med, int del) throws Exception {
    Class<?> f = Class.forName(
        "com.eternalxi.eternalxi_api.services.LeagueSimulationService$TeamFormation"
    );
    Constructor<?> ctor = f.getDeclaredConstructor(int.class, int.class, int.class);
    ctor.setAccessible(true);
    return ctor.newInstance(def, med, del);
  }

  private int invokeComputeStarterLoansNeeded(List<Object> starters, Object formation) throws Exception {
    LeagueSimulationService svc = new LeagueSimulationService(null, null, null, new LeagueAutomationProperties());
    Method m = LeagueSimulationService.class.getDeclaredMethod(
        "computeStarterLoansNeeded",
        List.class,
        formation.getClass()
    );
    m.setAccessible(true);
    return (int) m.invoke(svc, starters, formation);
  }

  private int invokeCountFormationStarterDeficits(List<Object> starters, Object formation) throws Exception {
    LeagueSimulationService svc = new LeagueSimulationService(null, null, null, new LeagueAutomationProperties());
    Method m = LeagueSimulationService.class.getDeclaredMethod(
        "countFormationStarterDeficits",
        List.class,
        formation.getClass()
    );
    m.setAccessible(true);
    return (int) m.invoke(svc, starters, formation);
  }
}
