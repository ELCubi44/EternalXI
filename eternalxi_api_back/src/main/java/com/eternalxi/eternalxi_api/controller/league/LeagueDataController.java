package com.eternalxi.eternalxi_api.controller.league;

import com.eternalxi.eternalxi_api.dto.auth.ApiMessageResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueEditableLineupResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueHomeFeedResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueInstantBuyResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueInstantSellResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueLiveMatchResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueMarketHistoryResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueMarketPlayerResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueMatchDetailResponse;
import com.eternalxi.eternalxi_api.dto.league.LeaguePlayerDetailResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueParticipantLineupHistoryResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueParticipantLineupRoundDetailResponse;
import com.eternalxi.eternalxi_api.dto.league.LeaguePlayerOfferResponse;
import com.eternalxi.eternalxi_api.dto.league.LeaguePlayerOfferUpsertRequest;
import com.eternalxi.eternalxi_api.dto.league.LeagueRoundDetailResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueRoundSummaryResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueTeamStandingRowResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueUnavailablePlayerResponse;
import com.eternalxi.eternalxi_api.dto.league.NightMarketBidRequest;
import com.eternalxi.eternalxi_api.dto.league.NightMarketResponse;
import com.eternalxi.eternalxi_api.services.LeagueDataService;
import com.eternalxi.eternalxi_api.services.LeagueLineupService;
import com.eternalxi.eternalxi_api.services.LeagueMarketHistoryService;
import com.eternalxi.eternalxi_api.services.LeagueTradeService;
import com.eternalxi.eternalxi_api.services.NightMarketService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.sql.SQLException;
import java.util.List;

@RestController
@RequestMapping("/api/v1/leagues")
public class LeagueDataController {

    private final LeagueTradeService leagueTradeService;
    private final NightMarketService nightMarketService;
    private final LeagueDataService leagueDataService;
    private final LeagueLineupService leagueLineupService;
    private final LeagueMarketHistoryService leagueMarketHistoryService;

    public LeagueDataController(
            LeagueDataService leagueDataService,
            LeagueLineupService leagueLineupService,
            LeagueMarketHistoryService leagueMarketHistoryService,
            NightMarketService nightMarketService,
            LeagueTradeService leagueTradeService
    ) {
        this.leagueDataService = leagueDataService;
        this.leagueLineupService = leagueLineupService;
        this.leagueMarketHistoryService = leagueMarketHistoryService;
        this.nightMarketService = nightMarketService;
        this.leagueTradeService = leagueTradeService;
    }

    @GetMapping("/{idLiga}/home-feed")
    public ResponseEntity<?> getLeagueHomeFeed(
            @PathVariable Long idLiga,
            @RequestParam Long idUsuario
    ) throws Exception {
        LeagueHomeFeedResponse response = leagueDataService.getLeagueHomeFeed(idLiga, idUsuario);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/{idLiga}/players/{idLigaJugador}/buy-now")
    public ResponseEntity<?> buyPlayerNow(
            @PathVariable Long idLiga,
            @PathVariable Long idLigaJugador,
            @RequestParam Long idUsuario
    ) throws SQLException {
        LeagueInstantBuyResponse response = nightMarketService.buyPlayerNow(idLiga, idLigaJugador, idUsuario);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{idLiga}/market")
    public ResponseEntity<?> listLeagueMarketPlayers(
            @PathVariable Long idLiga,
            @RequestParam Long idUsuario,
            @RequestParam(required = false) Long teamId,
            @RequestParam(required = false) Long ownerId,
            @RequestParam(required = false) String position,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) Long idJornada
    ) throws SQLException {
        List<LeagueMarketPlayerResponse> response = leagueDataService.listLeagueMarketPlayers(
                idLiga, idUsuario, teamId, ownerId, position, search, idJornada
        );
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{idLiga}/market/history")
    public ResponseEntity<?> getMarketHistory(
            @PathVariable Long idLiga,
            @RequestParam Long idUsuario
    ) throws SQLException {
        List<LeagueMarketHistoryResponse> response =
                leagueMarketHistoryService.getMarketHistory(idLiga, idUsuario);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{idLiga}/night-market")
    public ResponseEntity<?> getNightMarket(
            @PathVariable Long idLiga,
            @RequestParam Long idUsuario
    ) throws SQLException {
        NightMarketResponse response = nightMarketService.getNightMarket(idLiga, idUsuario);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/{idLiga}/night-market/{idMercadoDiario}/bid")
    public ResponseEntity<?> upsertNightMarketBid(
            @PathVariable Long idLiga,
            @PathVariable Long idMercadoDiario,
            @RequestBody NightMarketBidRequest request
    ) throws SQLException {
        nightMarketService.upsertBid(idLiga, idMercadoDiario, request);
        return ResponseEntity.ok(new ApiMessageResponse("Puja guardada correctamente"));
    }

    @DeleteMapping("/{idLiga}/night-market/{idMercadoDiario}/bid")
    public ResponseEntity<?> deleteNightMarketBid(
            @PathVariable Long idLiga,
            @PathVariable Long idMercadoDiario,
            @RequestParam Long idUsuario
    ) throws SQLException {
        nightMarketService.deleteBid(idLiga, idMercadoDiario, idUsuario);
        return ResponseEntity.ok(new ApiMessageResponse("Puja eliminada correctamente"));
    }

    @PostMapping("/night-market/cleanup-corrupt")
    public ResponseEntity<?> cleanupCorruptNightMarketItems() throws SQLException {
        NightMarketService.CleanupCorruptMarketResult result =
                nightMarketService.cleanupCorruptDailyMarketItems();
        return ResponseEntity.ok(result);
    }

    @PostMapping("/{idLiga}/players/{idLigaJugador}/sell")
    public ResponseEntity<?> sellPlayerToMarket(
            @PathVariable Long idLiga,
            @PathVariable Long idLigaJugador,
            @RequestParam Long idUsuario
    ) throws SQLException {
        LeagueInstantSellResponse response =
                leagueTradeService.sellPlayerToMarket(idLiga, idLigaJugador, idUsuario);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/{idLiga}/players/{idLigaJugador}/offers")
    public ResponseEntity<?> upsertPlayerOffer(
            @PathVariable Long idLiga,
            @PathVariable Long idLigaJugador,
            @RequestBody LeaguePlayerOfferUpsertRequest request
    ) throws SQLException {
        leagueTradeService.upsertOffer(idLiga, idLigaJugador, request);
        return ResponseEntity.ok(new ApiMessageResponse("Oferta guardada correctamente"));
    }

    @GetMapping("/{idLiga}/offers/sent")
    public ResponseEntity<?> getSentOffers(
            @PathVariable Long idLiga,
            @RequestParam Long idUsuario
    ) throws SQLException {
        List<LeaguePlayerOfferResponse> response =
                leagueTradeService.getSentOffers(idLiga, idUsuario);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{idLiga}/offers/received")
    public ResponseEntity<?> getReceivedOffers(
            @PathVariable Long idLiga,
            @RequestParam Long idUsuario
    ) throws SQLException {
        List<LeaguePlayerOfferResponse> response =
                leagueTradeService.getReceivedOffers(idLiga, idUsuario);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/{idLiga}/offers/{idOferta}/accept")
    public ResponseEntity<?> acceptOffer(
            @PathVariable Long idLiga,
            @PathVariable Long idOferta,
            @RequestParam Long idUsuario
    ) throws SQLException {
        leagueTradeService.acceptOffer(idLiga, idOferta, idUsuario);
        return ResponseEntity.ok(new ApiMessageResponse("Oferta aceptada correctamente"));
    }

    @PostMapping("/{idLiga}/offers/{idOferta}/reject")
    public ResponseEntity<?> rejectOffer(
            @PathVariable Long idLiga,
            @PathVariable Long idOferta,
            @RequestParam Long idUsuario
    ) throws SQLException {
        leagueTradeService.rejectOffer(idLiga, idOferta, idUsuario);
        return ResponseEntity.ok(new ApiMessageResponse("Oferta rechazada correctamente"));
    }

    @DeleteMapping("/{idLiga}/offers/{idOferta}")
    public ResponseEntity<?> cancelOffer(
            @PathVariable Long idLiga,
            @PathVariable Long idOferta,
            @RequestParam Long idUsuario
    ) throws SQLException {
        leagueTradeService.cancelOffer(idLiga, idOferta, idUsuario);
        return ResponseEntity.ok(new ApiMessageResponse("Oferta cancelada correctamente"));
    }

    @GetMapping("/{idLiga}/lineup")
    public ResponseEntity<?> getEditableLineup(
            @PathVariable Long idLiga,
            @RequestParam Long idUsuario
    ) throws SQLException {
        LeagueEditableLineupResponse response = leagueLineupService.getEditableLineup(idLiga, idUsuario);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{idLiga}/rounds")
    public ResponseEntity<?> listLeagueRounds(
            @PathVariable Long idLiga,
            @RequestParam Long idUsuario
    ) throws SQLException {
        List<LeagueRoundSummaryResponse> response = leagueDataService.listLeagueRounds(idLiga, idUsuario);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{idLiga}/team-standings")
    public ResponseEntity<?> getLeagueTeamStandings(
            @PathVariable Long idLiga,
            @RequestParam Long idUsuario
    ) throws SQLException {
        List<LeagueTeamStandingRowResponse> response =
                leagueDataService.getLeagueTeamStandings(idLiga, idUsuario);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{idLiga}/participants/{idLigaParticipante}/lineup-history")
    public ResponseEntity<?> getParticipantLineupHistory(
            @PathVariable Long idLiga,
            @PathVariable Long idLigaParticipante,
            @RequestParam Long idUsuario
    ) throws SQLException {
        LeagueParticipantLineupHistoryResponse response =
                leagueDataService.getParticipantLineupHistory(idLiga, idLigaParticipante, idUsuario);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{idLiga}/participants/{idLigaParticipante}/lineup-history/{idJornada}")
    public ResponseEntity<?> getParticipantLineupHistoryRoundDetail(
            @PathVariable Long idLiga,
            @PathVariable Long idLigaParticipante,
            @PathVariable Long idJornada,
            @RequestParam Long idUsuario
    ) throws SQLException {
        LeagueParticipantLineupRoundDetailResponse response =
                leagueDataService.getParticipantLineupHistoryRoundDetail(
                        idLiga, idLigaParticipante, idJornada, idUsuario
                );
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{idLiga}/rounds/{idJornada}")
    public ResponseEntity<?> getLeagueRoundDetail(
            @PathVariable Long idLiga,
            @PathVariable Long idJornada,
            @RequestParam Long idUsuario
    ) throws SQLException {
        LeagueRoundDetailResponse response = leagueDataService.getLeagueRoundDetail(idLiga, idJornada, idUsuario);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{idLiga}/matches/{idPartido}")
    public ResponseEntity<?> getLeagueMatchDetail(
            @PathVariable Long idLiga,
            @PathVariable Long idPartido,
            @RequestParam Long idUsuario
    ) throws SQLException {
        LeagueMatchDetailResponse response = leagueDataService.getLeagueMatchDetail(idLiga, idPartido, idUsuario);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{idLiga}/matches/{idPartido}/live")
    public ResponseEntity<?> getLeagueLiveMatch(
            @PathVariable Long idLiga,
            @PathVariable Long idPartido,
            @RequestParam Long idUsuario
    ) throws SQLException {
        LeagueLiveMatchResponse response = leagueDataService.getLeagueLiveMatch(idLiga, idPartido, idUsuario);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{idLiga}/players/{idLigaJugador}")
    public ResponseEntity<?> getLeaguePlayerDetail(
            @PathVariable Long idLiga,
            @PathVariable Long idLigaJugador,
            @RequestParam Long idUsuario,
            @RequestParam(required = false) Long idJornada
    ) throws SQLException {
        LeaguePlayerDetailResponse response =
                leagueDataService.getLeaguePlayerDetail(idLiga, idLigaJugador, idUsuario, idJornada);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{idLiga}/unavailable-players")
    public ResponseEntity<?> getUnavailablePlayers(
            @PathVariable Long idLiga,
            @RequestParam Long idUsuario
    ) throws SQLException {
        List<LeagueUnavailablePlayerResponse> response = leagueDataService.getUnavailablePlayers(idLiga, idUsuario);
        return ResponseEntity.ok(response);
    }
}
