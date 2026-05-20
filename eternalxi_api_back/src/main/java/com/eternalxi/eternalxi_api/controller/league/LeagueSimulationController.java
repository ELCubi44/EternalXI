package com.eternalxi.eternalxi_api.controller.league;

import com.eternalxi.eternalxi_api.dto.auth.ApiMessageResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueSimulationMatchResultResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueSimulationRepairResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueSimulationRunResponse;
import com.eternalxi.eternalxi_api.services.LeagueSimulationService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.sql.SQLException;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/leagues")
public class LeagueSimulationController {

    private final LeagueSimulationService leagueSimulationService;

    public LeagueSimulationController(LeagueSimulationService leagueSimulationService) {
        this.leagueSimulationService = leagueSimulationService;
    }

    @PostMapping("/simulations/prepare-due-lineups")
    public ResponseEntity<?> prepareDueLineups() throws SQLException {
        int prepared = leagueSimulationService.prepareDueLineups();
        return ResponseEntity.ok(Map.of("partidosPreparados", prepared));
    }

    @PostMapping("/simulations/finalize-due")
    public ResponseEntity<?> finalizeDueMatches() throws SQLException {
        int finalized = leagueSimulationService.finalizeDueMatchesNow();
        return ResponseEntity.ok(Map.of("partidosFinalizados", finalized));
    }

    @PostMapping("/{idLiga}/matches/{idPartido}/finalize")
    public ResponseEntity<?> finalizeMatchNow(
            @PathVariable Long idLiga,
            @PathVariable Long idPartido
    ) throws SQLException {
        leagueSimulationService.finalizeMatchNow(idLiga, idPartido);
        return ResponseEntity.ok(new ApiMessageResponse("Partido finalizado correctamente"));
    }

    @PostMapping("/{idLiga}/recalculate-points")
    public ResponseEntity<?> recalculateLeaguePoints(
            @PathVariable Long idLiga
    ) throws SQLException {
        leagueSimulationService.recalculateLeaguePointsNow(idLiga);
        return ResponseEntity.ok(new ApiMessageResponse("Puntos recalculados correctamente"));
    }

    @PostMapping("/{idLiga}/matches/{idPartido}/prepare-lineup")
    public ResponseEntity<?> prepareMatchLineupNow(
            @PathVariable Long idLiga,
            @PathVariable Long idPartido
    ) throws SQLException {
        leagueSimulationService.prepareMatchLineupNow(idLiga, idPartido);
        return ResponseEntity.ok(new ApiMessageResponse("Alineación preparada correctamente"));
    }

    @PostMapping("/{idLiga}/jornadas/{idJornada}/payout-round-rewards")
    public ResponseEntity<?> payoutFinalizedRoundRewards(
            @PathVariable Long idLiga,
            @PathVariable Long idJornada
    ) {
        leagueSimulationService.payoutFinalizedRoundRewardsIfDue(idLiga, idJornada);
        return ResponseEntity.ok(new ApiMessageResponse("Premios de jornada procesados (idempotente)"));
    }

    @PostMapping("/simulations/repair-stuck-finalized")
    public ResponseEntity<?> repairStuckMatchesSimulatedWithFinalEvent() throws SQLException {
        LeagueSimulationRepairResponse response =
                leagueSimulationService.repairStuckMatchesSimulatedWithFinalEvent();
        return ResponseEntity.ok(response);
    }

    @PostMapping("/simulations/run-due")
    public ResponseEntity<?> runDueSimulations() throws SQLException {
        LeagueSimulationRunResponse response = leagueSimulationService.runDueSimulations();
        return ResponseEntity.ok(response);
    }

    @PostMapping("/{idLiga}/matches/{idPartido}/simulate")
    public ResponseEntity<?> simulateMatchNow(
            @PathVariable Long idLiga,
            @PathVariable Long idPartido
    ) throws SQLException {
        LeagueSimulationMatchResultResponse response =
                leagueSimulationService.simulateMatchNow(idLiga, idPartido);
        return ResponseEntity.ok(response);
    }
}
