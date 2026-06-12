package com.eternalxi.eternalxi_api.controller.league;

import com.eternalxi.eternalxi_api.dto.auth.ApiMessageResponse;
import com.eternalxi.eternalxi_api.dto.league.CreateLeagueRequest;
import com.eternalxi.eternalxi_api.dto.league.CreateLeagueResponse;
import com.eternalxi.eternalxi_api.dto.league.JoinLeagueRequest;
import com.eternalxi.eternalxi_api.dto.league.KickParticipantRequest;
import com.eternalxi.eternalxi_api.dto.league.LeagueChatMessageResponse;
import com.eternalxi.eternalxi_api.dto.league.PostLeagueChatMessageRequest;
import com.eternalxi.eternalxi_api.dto.league.LeagueDetailResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueParticipantResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueParticipantSquadResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueOwnSquadResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueRoundStandingsRowResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueStandingsRowResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueStarterProbabilitiesResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueSummaryResponse;
import com.eternalxi.eternalxi_api.dto.league.LeaveLeagueRequest;
import com.eternalxi.eternalxi_api.dto.league.TransferLeagueAdminRequest;
import com.eternalxi.eternalxi_api.dto.league.SaveLeagueLineupRequest;
import com.eternalxi.eternalxi_api.services.LeagueActivityService;
import com.eternalxi.eternalxi_api.services.LeagueChatService;
import com.eternalxi.eternalxi_api.services.LeagueLineupService;
import com.eternalxi.eternalxi_api.services.LeagueStarterProbabilityService;
import com.eternalxi.eternalxi_api.services.LeagueService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.sql.SQLException;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/leagues")
public class LeagueController {

    private final LeagueService leagueService;
    private final LeagueLineupService leagueLineupService;
    private final LeagueStarterProbabilityService leagueStarterProbabilityService;
    private final LeagueActivityService leagueActivityService;
    private final LeagueChatService leagueChatService;

    public LeagueController(
            LeagueService leagueService,
            LeagueLineupService leagueLineupService,
            LeagueStarterProbabilityService leagueStarterProbabilityService,
            LeagueActivityService leagueActivityService,
            LeagueChatService leagueChatService
    ) {
        this.leagueService = leagueService;
        this.leagueLineupService = leagueLineupService;
        this.leagueStarterProbabilityService = leagueStarterProbabilityService;
        this.leagueActivityService = leagueActivityService;
        this.leagueChatService = leagueChatService;
    }

    @PostMapping
    public ResponseEntity<CreateLeagueResponse> createLeague(@RequestBody CreateLeagueRequest request) throws SQLException {
        CreateLeagueResponse response = leagueService.createLeague(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @PostMapping("/join")
    public ResponseEntity<?> joinLeague(@RequestBody JoinLeagueRequest request) throws SQLException {
        return ResponseEntity.ok(leagueService.joinLeague(request));
    }

    @GetMapping("/my")
    public ResponseEntity<?> getMyLeagues(@RequestParam Long idUsuario) throws SQLException {
        List<LeagueSummaryResponse> response = leagueService.getMyLeagues(idUsuario);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{idLiga}")
    public ResponseEntity<?> getLeagueDetail(
            @PathVariable Long idLiga,
            @RequestParam Long idUsuario
    ) throws SQLException {
        LeagueDetailResponse response = leagueService.getLeagueDetail(idLiga, idUsuario);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{idLiga}/standings")
    public ResponseEntity<?> getStandings(
            @PathVariable Long idLiga,
            @RequestParam Long idUsuario
    ) throws SQLException {
        List<LeagueStandingsRowResponse> response = leagueService.getStandings(idLiga, idUsuario);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{idLiga}/rounds/{idJornada}/standings")
    public ResponseEntity<?> getRoundStandings(
            @PathVariable Long idLiga,
            @PathVariable Long idJornada,
            @RequestParam Long idUsuario
    ) throws SQLException {
        List<LeagueRoundStandingsRowResponse> response =
                leagueService.getRoundStandings(idLiga, idJornada, idUsuario);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{idLiga}/participants")
    public ResponseEntity<?> getParticipants(
            @PathVariable Long idLiga,
            @RequestParam Long idUsuario
    ) throws SQLException {
        List<LeagueParticipantResponse> response = leagueService.getParticipants(idLiga, idUsuario);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{idLiga}/participants/{idLigaParticipante}/squad")
    public ResponseEntity<?> getParticipantSquad(
            @PathVariable Long idLiga,
            @PathVariable Long idLigaParticipante,
            @RequestParam Long idUsuario,
            @RequestParam(required = false) Long idJornada
    ) throws SQLException {
        LeagueParticipantSquadResponse response =
                leagueService.getParticipantSquad(idLiga, idLigaParticipante, idUsuario, idJornada);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{idLiga}/squad")
    public ResponseEntity<?> getSquad(
            @PathVariable Long idLiga,
            @RequestParam Long idUsuario,
            @RequestParam(required = false) Long idJornada
    ) throws SQLException {
        LeagueOwnSquadResponse response = leagueService.getSquad(idLiga, idUsuario, idJornada);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/{idLiga}/lineup")
    public ResponseEntity<?> saveEditableLineup(
            @PathVariable Long idLiga,
            @RequestBody SaveLeagueLineupRequest request
    ) throws SQLException {
        leagueLineupService.saveEditableLineup(idLiga, request);
        return ResponseEntity.ok(new ApiMessageResponse("Alineación guardada correctamente"));
    }

    @PostMapping("/{idLiga}/admin/transfer")
    public ResponseEntity<?> transferLeagueAdmin(
            @PathVariable Long idLiga,
            @RequestBody TransferLeagueAdminRequest request
    ) throws SQLException {
        leagueService.transferLeagueAdmin(idLiga, request);
        return ResponseEntity.ok(new ApiMessageResponse("Administrador actualizado correctamente"));
    }

    @PostMapping("/{idLiga}/leave")
    public ResponseEntity<?> leaveLeague(
            @PathVariable Long idLiga,
            @RequestBody LeaveLeagueRequest request
    ) throws SQLException {
        leagueService.leaveLeague(idLiga, request);
        return ResponseEntity.ok(new ApiMessageResponse("Has salido de la liga correctamente"));
    }

    @PostMapping("/{idLiga}/close")
    public ResponseEntity<?> closeLeague(
            @PathVariable Long idLiga,
            @RequestParam Long idUsuario
    ) throws SQLException {
        leagueService.closeLeague(idLiga, idUsuario);
        return ResponseEntity.ok(new ApiMessageResponse("Liga cerrada correctamente"));
    }

    @PostMapping("/{idLiga}/kick")
    public ResponseEntity<?> kickParticipant(
            @PathVariable Long idLiga,
            @RequestBody KickParticipantRequest request
    ) throws SQLException {
        leagueService.kickParticipant(idLiga, request);
        return ResponseEntity.ok(new ApiMessageResponse("Participante expulsado correctamente"));
    }

    @PostMapping("/{idLiga}/starter-probabilities/recalculate")
    public ResponseEntity<?> recalculateStarterProbabilities(
            @PathVariable Long idLiga,
            @RequestParam Long idUsuario,
            @RequestParam(required = false) Long idJornada,
            @RequestParam(required = false) Long idPartido
    ) throws SQLException {
        leagueStarterProbabilityService.recalculateForParticipant(idLiga, idUsuario, idJornada, idPartido);
        return ResponseEntity.ok(new ApiMessageResponse("Probabilidades de titularidad recalculadas"));
    }

    @GetMapping("/{idLiga}/starter-probabilities")
    public ResponseEntity<?> getStarterProbabilities(
            @PathVariable Long idLiga,
            @RequestParam Long idUsuario,
            @RequestParam Long idJornada
    ) throws SQLException {
        LeagueStarterProbabilitiesResponse response =
                leagueStarterProbabilityService.listProbabilities(idLiga, idJornada, idUsuario);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{idLiga}/activity")
    public ResponseEntity<?> getActivity(
            @PathVariable Long idLiga,
            @RequestParam Long idUsuario,
            @RequestParam(defaultValue = "50") int limit,
            @RequestParam(defaultValue = "0") int offset
    ) throws SQLException {
        var events = leagueActivityService.listActivity(idLiga, idUsuario, limit, offset);
        return ResponseEntity.ok(events);
    }

    @GetMapping("/{idLiga}/chat")
    public ResponseEntity<List<LeagueChatMessageResponse>> getChatMessages(
            @PathVariable Long idLiga,
            @RequestParam Long idUsuario,
            @RequestParam(required = false) Long afterId,
            @RequestParam(defaultValue = "100") int limit,
            @RequestParam(defaultValue = "false") boolean recent
    ) throws SQLException {
        List<LeagueChatMessageResponse> messages =
                leagueChatService.listMessages(idLiga, idUsuario, afterId, limit, recent);
        return ResponseEntity.ok(messages);
    }

    @PostMapping("/{idLiga}/chat")
    public ResponseEntity<LeagueChatMessageResponse> postChatMessage(
            @PathVariable Long idLiga,
            @RequestBody PostLeagueChatMessageRequest request
    ) throws SQLException {
        LeagueChatMessageResponse message = leagueChatService.postMessage(
                idLiga,
                request.idUsuario(),
                request.texto()
        );
        return ResponseEntity.status(HttpStatus.CREATED).body(message);
    }
}
