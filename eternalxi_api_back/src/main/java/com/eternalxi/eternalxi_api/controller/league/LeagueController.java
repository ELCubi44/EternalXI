package com.eternalxi.eternalxi_api.controller.league;

import com.eternalxi.eternalxi_api.security.AuthenticatedUser;
import com.eternalxi.eternalxi_api.dto.auth.ApiMessageResponse;
import com.eternalxi.eternalxi_api.dto.league.CreateLeagueRequest;
import com.eternalxi.eternalxi_api.dto.league.CreateLeagueResponse;
import com.eternalxi.eternalxi_api.dto.league.InviteFriendToLeagueRequest;
import com.eternalxi.eternalxi_api.dto.league.JoinLeagueRequest;
import com.eternalxi.eternalxi_api.dto.league.KickParticipantRequest;
import com.eternalxi.eternalxi_api.dto.league.LeagueChatMessageResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueDmMessageResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueDmThreadResponse;
import com.eternalxi.eternalxi_api.dto.league.PostLeagueChatMessageRequest;
import com.eternalxi.eternalxi_api.dto.league.PostLeagueDmMessageRequest;
import com.eternalxi.eternalxi_api.dto.league.ReportChatMessageRequest;
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
import com.eternalxi.eternalxi_api.services.LeagueDmService;
import com.eternalxi.eternalxi_api.services.LeagueLineupService;
import com.eternalxi.eternalxi_api.services.LeagueService;
import com.eternalxi.eternalxi_api.services.LeagueStarterProbabilityService;
import com.eternalxi.eternalxi_api.services.UserSafetyService;
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
    private final LeagueDmService leagueDmService;
    private final UserSafetyService userSafetyService;

    public LeagueController(
            LeagueService leagueService,
            LeagueLineupService leagueLineupService,
            LeagueStarterProbabilityService leagueStarterProbabilityService,
            LeagueActivityService leagueActivityService,
            LeagueChatService leagueChatService,
            LeagueDmService leagueDmService,
            UserSafetyService userSafetyService
    ) {
        this.leagueService = leagueService;
        this.leagueLineupService = leagueLineupService;
        this.leagueStarterProbabilityService = leagueStarterProbabilityService;
        this.leagueActivityService = leagueActivityService;
        this.leagueChatService = leagueChatService;
        this.leagueDmService = leagueDmService;
        this.userSafetyService = userSafetyService;
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

    @PostMapping("/{idLiga}/invite-friend")
    public ResponseEntity<?> inviteFriendToLeague(
            @PathVariable Long idLiga,
            @RequestBody InviteFriendToLeagueRequest request
    ) throws SQLException {
        if (request == null || request.idUsuario() == null) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse("Falta el usuario"));
        }
        if (request.idAmigo() == null) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse("Falta el amigo a invitar"));
        }
        AuthenticatedUser.assertSameUser(request.idUsuario());
        leagueService.inviteFriendToLeague(idLiga, request.idUsuario(), request.idAmigo());
        return ResponseEntity.ok(new ApiMessageResponse("Invitación enviada"));
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

    @GetMapping("/{idLiga}/dm/threads")
    public ResponseEntity<List<LeagueDmThreadResponse>> getDmThreads(
            @PathVariable Long idLiga,
            @RequestParam Long idUsuario
    ) throws SQLException {
        return ResponseEntity.ok(leagueDmService.listThreads(idLiga, idUsuario));
    }

    @GetMapping("/{idLiga}/dm/{idPeer}")
    public ResponseEntity<List<LeagueDmMessageResponse>> getDmMessages(
            @PathVariable Long idLiga,
            @PathVariable Long idPeer,
            @RequestParam Long idUsuario,
            @RequestParam(required = false) Long afterId,
            @RequestParam(defaultValue = "100") int limit,
            @RequestParam(defaultValue = "false") boolean recent
    ) throws SQLException {
        List<LeagueDmMessageResponse> messages = leagueDmService.listMessages(
                idLiga, idUsuario, idPeer, afterId, limit, recent
        );
        return ResponseEntity.ok(messages);
    }

    @PostMapping("/{idLiga}/dm/{idPeer}")
    public ResponseEntity<LeagueDmMessageResponse> postDmMessage(
            @PathVariable Long idLiga,
            @PathVariable Long idPeer,
            @RequestBody PostLeagueDmMessageRequest request
    ) throws SQLException {
        if (request.idUsuario() == null) {
            return ResponseEntity.badRequest().build();
        }
        AuthenticatedUser.assertSameUser(request.idUsuario());
        LeagueDmMessageResponse message = leagueDmService.postMessage(
                idLiga,
                request.idUsuario(),
                idPeer,
                request.texto()
        );
        return ResponseEntity.status(HttpStatus.CREATED).body(message);
    }

    @PostMapping("/{idLiga}/chat/{idMensaje}/report")
    public ResponseEntity<?> reportChatMessage(
            @PathVariable Long idLiga,
            @PathVariable Long idMensaje,
            @RequestBody ReportChatMessageRequest request
    ) throws SQLException {
        if (request.idUsuario() == null) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse("Usuario no válido"));
        }
        AuthenticatedUser.assertSameUser(request.idUsuario());
        try {
            userSafetyService.reportChatMessage(
                    idLiga,
                    idMensaje,
                    request.idUsuario(),
                    request.motivo()
            );
            return ResponseEntity.ok(new ApiMessageResponse("Mensaje reportado. Lo revisaremos lo antes posible."));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse(e.getMessage()));
        }
    }
}
