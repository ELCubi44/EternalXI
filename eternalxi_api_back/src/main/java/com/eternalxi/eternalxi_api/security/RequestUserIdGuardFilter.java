package com.eternalxi.eternalxi_api.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Impide que un usuario autenticado pase otro {@code idUsuario} en query/path para suplantar identidad.
 */
@Component
public class RequestUserIdGuardFilter extends OncePerRequestFilter {

    private static final Set<String> SELF_USER_PARAMS = Set.of(
            "idUsuario",
            "idUsuarioSolicitante",
            "idAdminUsuario",
            "idUsuarioComprador"
    );

    private static final Pattern USER_PATH = Pattern.compile("^/api/v1/users/(\\d+)(?:/|$)");
    private static final Pattern USER_PHOTO_PATH =
            Pattern.compile("^/api/v1/users/\\d+/photo$");

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return "GET".equalsIgnoreCase(request.getMethod())
                && USER_PHOTO_PATH.matcher(request.getRequestURI()).matches();
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {
        Long current = AuthenticatedUser.currentUserIdOrNull();
        if (current == null) {
            filterChain.doFilter(request, response);
            return;
        }

        for (String param : SELF_USER_PARAMS) {
            String raw = request.getParameter(param);
            if (raw == null || raw.isBlank()) {
                continue;
            }
            try {
                long requested = Long.parseLong(raw);
                if (requested != current) {
                    deny(response);
                    return;
                }
            } catch (NumberFormatException ignored) {
                deny(response);
                return;
            }
        }

        Matcher matcher = USER_PATH.matcher(request.getRequestURI());
        if (matcher.find()) {
            try {
                long pathUserId = Long.parseLong(matcher.group(1));
                if (pathUserId != current) {
                    deny(response);
                    return;
                }
            } catch (NumberFormatException ignored) {
                deny(response);
                return;
            }
        }

        filterChain.doFilter(request, response);
    }

    private void deny(HttpServletResponse response) throws IOException {
        response.setStatus(HttpStatus.FORBIDDEN.value());
        response.setContentType("application/json");
        response.getWriter().write(
                "{\"error\":\"FORBIDDEN\",\"message\":\"No autorizado para este usuario.\",\"status\":403}"
        );
    }
}
