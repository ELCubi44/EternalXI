package com.eternalxi.eternalxi_api.controller.catalog;

import com.eternalxi.eternalxi_api.dto.catalog.CatalogTeamPlayerResponse;
import com.eternalxi.eternalxi_api.dto.catalog.CatalogTeamSquadResponse;
import com.eternalxi.eternalxi_api.dto.catalog.CatalogTeamResponse;
import com.eternalxi.eternalxi_api.dto.catalog.SeasonResponse;
import com.eternalxi.eternalxi_api.services.CatalogService;
import com.eternalxi.eternalxi_api.util.CatalogLocale;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestHeader;
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
    public ResponseEntity<?> listSeasons(
            @RequestParam(required = false) String lang,
            @RequestHeader(value = "Accept-Language", required = false) String acceptLanguage
    ) throws SQLException {
        CatalogLocale locale = CatalogLocale.from(lang, acceptLanguage);
        List<SeasonResponse> response = catalogService.listSeasons(locale.code());
        return ResponseEntity.ok(response);
    }

    @GetMapping("/teams")
    public ResponseEntity<?> listTeamsBySeason(
            @RequestParam Long seasonId,
            @RequestParam(required = false) String lang,
            @RequestHeader(value = "Accept-Language", required = false) String acceptLanguage
    ) throws SQLException {
        CatalogLocale locale = CatalogLocale.from(lang, acceptLanguage);
        List<CatalogTeamResponse> response = catalogService.listTeamsBySeason(seasonId, locale.code());
        return ResponseEntity.ok(response);
    }

    @GetMapping("/teams/{idEquipo}/players")
    public ResponseEntity<?> listPlayersByTeam(
            @PathVariable Long idEquipo,
            @RequestParam(required = false) Long seasonId,
            @RequestParam(required = false) String lang,
            @RequestHeader(value = "Accept-Language", required = false) String acceptLanguage
    ) throws SQLException {
        CatalogLocale locale = CatalogLocale.from(lang, acceptLanguage);
        List<CatalogTeamPlayerResponse> response = catalogService.listPlayersByTeam(
                idEquipo,
                seasonId,
                locale.code()
        );
        return ResponseEntity.ok(response);
    }

    @GetMapping("/teams/{idEquipo}/squad")
    public ResponseEntity<?> getTeamSquad(
            @PathVariable Long idEquipo,
            @RequestParam(required = false) Long seasonId,
            @RequestParam(required = false) Long idLiga,
            @RequestParam(required = false) String lang,
            @RequestHeader(value = "Accept-Language", required = false) String acceptLanguage
    ) throws SQLException {
        CatalogLocale locale = CatalogLocale.from(lang, acceptLanguage);
        CatalogTeamSquadResponse response = catalogService.getTeamSquad(
                idEquipo,
                seasonId,
                idLiga,
                locale.code()
        );
        return ResponseEntity.ok(response);
    }
}
