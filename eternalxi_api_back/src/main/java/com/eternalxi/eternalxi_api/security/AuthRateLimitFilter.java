package com.eternalxi.eternalxi_api.security;

import com.eternalxi.eternalxi_api.config.EternalxiSecurityProperties;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class AuthRateLimitFilter extends OncePerRequestFilter {

    private final int maxPerMinute;
    private final Map<String, Deque<Long>> buckets = new ConcurrentHashMap<>();

    public AuthRateLimitFilter(EternalxiSecurityProperties properties) {
        this.maxPerMinute = Math.max(5, properties.getAuthRateLimitPerMinute());
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        String path = request.getRequestURI();
        return !path.startsWith("/api/v1/auth/");
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {
        if (!"POST".equalsIgnoreCase(request.getMethod())) {
            filterChain.doFilter(request, response);
            return;
        }

        String key = clientKey(request);
        long now = System.currentTimeMillis();
        Deque<Long> window = buckets.computeIfAbsent(key, k -> new ArrayDeque<>());

        synchronized (window) {
            while (!window.isEmpty() && now - window.peekFirst() > 60_000L) {
                window.pollFirst();
            }
            if (window.size() >= maxPerMinute) {
                response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
                response.setContentType("application/json");
                response.getWriter().write(
                        "{\"error\":\"RATE_LIMIT\",\"message\":\"Demasiados intentos. Espera un minuto.\",\"status\":429}"
                );
                return;
            }
            window.addLast(now);
        }

        filterChain.doFilter(request, response);
    }

    private String clientKey(HttpServletRequest request) {
        String forwarded = request.getHeader("X-Forwarded-For");
        if (forwarded != null && !forwarded.isBlank()) {
            return forwarded.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}
