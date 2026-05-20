package com.eternalxi.eternalxi_api.controller.league;

import com.eternalxi.eternalxi_api.dto.rewards.LeagueCardRedeemRequest;
import com.eternalxi.eternalxi_api.dto.rewards.LeagueCardRedeemResponse;
import com.eternalxi.eternalxi_api.dto.rewards.LeagueCardValidTargetsResponse;
import com.eternalxi.eternalxi_api.dto.rewards.LeagueCoachRouletteSpinResponse;
import com.eternalxi.eternalxi_api.dto.rewards.LeaguePackOpenResponse;
import com.eternalxi.eternalxi_api.dto.rewards.LeagueRewardEventResponse;
import com.eternalxi.eternalxi_api.dto.rewards.LeagueRewardsSummaryResponse;
import com.eternalxi.eternalxi_api.dto.rewards.LeagueUserCardResponse;
import com.eternalxi.eternalxi_api.dto.rewards.RewardPackType;
import com.eternalxi.eternalxi_api.services.LeagueRewardsService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.sql.SQLException;
import java.util.List;

/**
 * Recompensas y cartas por liga. Deuda técnica: {@code idUsuario} debe sustituirse por usuario autenticado.
 */
@RestController
@RequestMapping("/api/v1/leagues")
public class LeagueRewardsController {

    private final LeagueRewardsService leagueRewardsService;

    public LeagueRewardsController(LeagueRewardsService leagueRewardsService) {
        this.leagueRewardsService = leagueRewardsService;
    }

    @GetMapping("/{idLiga}/rewards/summary")
    public ResponseEntity<?> summary(@PathVariable Long idLiga, @RequestParam Long idUsuario) throws SQLException {
        LeagueRewardsSummaryResponse r = leagueRewardsService.getSummary(idLiga, idUsuario);
        return ResponseEntity.ok(r);
    }

    @PostMapping("/{idLiga}/rewards/packs/{packType}/open")
    public ResponseEntity<?> openPack(
            @PathVariable Long idLiga,
            @PathVariable String packType,
            @RequestParam Long idUsuario
    ) throws SQLException {
        RewardPackType pt = RewardPackType.fromPath(packType);
        LeaguePackOpenResponse r = leagueRewardsService.openPack(idLiga, pt, idUsuario);
        return ResponseEntity.ok(r);
    }

    @PostMapping("/{idLiga}/rewards/coach-roulette/spin")
    public ResponseEntity<?> spinCoach(@PathVariable Long idLiga, @RequestParam Long idUsuario) throws SQLException {
        LeagueCoachRouletteSpinResponse r = leagueRewardsService.spinCoachRoulette(idLiga, idUsuario);
        return ResponseEntity.ok(r);
    }

    @GetMapping("/{idLiga}/rewards/cards")
    public ResponseEntity<?> listCards(@PathVariable Long idLiga, @RequestParam Long idUsuario) throws SQLException {
        List<LeagueUserCardResponse> r = leagueRewardsService.listCards(idLiga, idUsuario);
        return ResponseEntity.ok(r);
    }

    @GetMapping("/{idLiga}/rewards/cards/{idCarta}/valid-targets")
    public ResponseEntity<?> validTargets(
            @PathVariable Long idLiga,
            @PathVariable Long idCarta,
            @RequestParam Long idUsuario
    ) throws SQLException {
        LeagueCardValidTargetsResponse r = leagueRewardsService.validTargets(idLiga, idCarta, idUsuario);
        return ResponseEntity.ok(r);
    }

    @PostMapping("/{idLiga}/rewards/cards/{idCarta}/redeem")
    public ResponseEntity<?> redeem(
            @PathVariable Long idLiga,
            @PathVariable Long idCarta,
            @RequestParam Long idUsuario,
            @RequestBody(required = false) LeagueCardRedeemRequest body
    ) throws SQLException {
        LeagueCardRedeemResponse r = leagueRewardsService.redeem(idLiga, idCarta, idUsuario, body);
        return ResponseEntity.ok(r);
    }

    @GetMapping("/{idLiga}/rewards/events")
    public ResponseEntity<?> events(@PathVariable Long idLiga, @RequestParam Long idUsuario) throws SQLException {
        List<LeagueRewardEventResponse> r = leagueRewardsService.listEvents(idLiga, idUsuario);
        return ResponseEntity.ok(r);
    }
}
