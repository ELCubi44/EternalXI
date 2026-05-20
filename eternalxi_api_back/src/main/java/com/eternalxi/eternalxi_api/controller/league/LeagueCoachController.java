package com.eternalxi.eternalxi_api.controller.league;

import com.eternalxi.eternalxi_api.dto.league.LeagueCoachActiveToggleRequest;
import com.eternalxi.eternalxi_api.dto.league.LeagueCoachAssignmentResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueCoachAssignmentUpsertRequest;
import com.eternalxi.eternalxi_api.dto.league.LeagueCoachInventoryResponse;
import com.eternalxi.eternalxi_api.services.LeagueCoachService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.sql.SQLException;
import java.util.Optional;

@RestController
@RequestMapping("/api/v1/leagues")
public class LeagueCoachController {

    private final LeagueCoachService leagueCoachService;

    public LeagueCoachController(LeagueCoachService leagueCoachService) {
        this.leagueCoachService = leagueCoachService;
    }

    @PutMapping("/{idLiga}/participants/{idLigaParticipante}/coach")
    public ResponseEntity<?> assignCoach(
            @PathVariable Long idLiga,
            @PathVariable Long idLigaParticipante,
            @RequestBody LeagueCoachAssignmentUpsertRequest request
    ) throws SQLException {
        LeagueCoachAssignmentResponse response =
                leagueCoachService.assignCoach(idLiga, idLigaParticipante, request);
        return ResponseEntity.ok(response);
    }

    @PatchMapping("/{idLiga}/participants/{idLigaParticipante}/coach/active")
    public ResponseEntity<?> toggleCoachActive(
            @PathVariable Long idLiga,
            @PathVariable Long idLigaParticipante,
            @RequestBody LeagueCoachActiveToggleRequest request
    ) throws SQLException {
        LeagueCoachAssignmentResponse response =
                leagueCoachService.toggleCoachActive(idLiga, idLigaParticipante, request);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{idLiga}/participants/{idLigaParticipante}/coach")
    public ResponseEntity<?> getEquippedCoach(
            @PathVariable Long idLiga,
            @PathVariable Long idLigaParticipante,
            @RequestParam Long idUsuarioSolicitante
    ) throws SQLException {
        Optional<LeagueCoachAssignmentResponse> equipped =
                leagueCoachService.getEquippedCoachAssignment(idLiga, idLigaParticipante, idUsuarioSolicitante);
        return equipped.<ResponseEntity<?>>map(ResponseEntity::ok)
                .orElse(ResponseEntity.noContent().build());
    }

    @GetMapping("/{idLiga}/participants/{idLigaParticipante}/coach/inventory")
    public ResponseEntity<?> listCoachInventory(
            @PathVariable Long idLiga,
            @PathVariable Long idLigaParticipante,
            @RequestParam Long idUsuarioSolicitante
    ) throws SQLException {
        LeagueCoachInventoryResponse response =
                leagueCoachService.listCoachInventory(idLiga, idLigaParticipante, idUsuarioSolicitante);
        return ResponseEntity.ok(response);
    }
}
