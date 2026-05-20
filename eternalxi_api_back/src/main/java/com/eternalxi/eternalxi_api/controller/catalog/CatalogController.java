package com.eternalxi.eternalxi_api.controller.catalog;

import com.eternalxi.eternalxi_api.dto.catalog.CatalogTeamPlayerResponse;
import com.eternalxi.eternalxi_api.dto.catalog.CatalogTeamSquadResponse;
import com.eternalxi.eternalxi_api.dto.catalog.CatalogTeamResponse;
import com.eternalxi.eternalxi_api.dto.catalog.SeasonResponse;
import com.eternalxi.eternalxi_api.services.CatalogService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.sql.SQLException;
import java.util.List;

@RestController
@RequestMapping("/api/v1/catalog")
public class CatalogController {

    private final CatalogService catalogService;

    public CatalogController(CatalogService catalogService) {
        this.catalogService = catalogService;
    }

    @GetMapping("/seasons")
    public ResponseEntity<?> listSeasons() throws SQLException {
        List<SeasonResponse> response = catalogService.listSeasons();
        return ResponseEntity.ok(response);
    }

    @GetMapping("/teams")
    public ResponseEntity<?> listTeamsBySeason(@RequestParam Long seasonId) throws SQLException {
        List<CatalogTeamResponse> response = catalogService.listTeamsBySeason(seasonId);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/teams/{idEquipo}/players")
    public ResponseEntity<?> listPlayersByTeam(
            @PathVariable Long idEquipo,
            @RequestParam(required = false) Long seasonId
    ) throws SQLException {
        List<CatalogTeamPlayerResponse> response = catalogService.listPlayersByTeam(idEquipo, seasonId);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/teams/{idEquipo}/squad")
    public ResponseEntity<?> getTeamSquad(
            @PathVariable Long idEquipo,
            @RequestParam(required = false) Long seasonId,
            @RequestParam(required = false) Long idLiga
    ) throws SQLException {
        CatalogTeamSquadResponse response = catalogService.getTeamSquad(idEquipo, seasonId, idLiga);
        return ResponseEntity.ok(response);
    }
}
