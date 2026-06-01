package com.eternalxi.eternalxi_api.security;

import com.eternalxi.eternalxi_api.config.EternalxiSecurityProperties;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Date;

@Service
public class JwtTokenService {

    public static final String CLAIM_TYPE = "type";
    public static final String TYPE_ACCESS = "access";
    public static final String TYPE_REFRESH = "refresh";

    private final EternalxiSecurityProperties properties;
    private final SecretKey secretKey;

    public JwtTokenService(EternalxiSecurityProperties properties) {
        this.properties = properties;
        byte[] keyBytes = properties.getJwtSecret().getBytes(StandardCharsets.UTF_8);
        if (keyBytes.length < 32) {
            throw new IllegalStateException(
                    "eternalxi.security.jwt-secret debe tener al menos 32 bytes (usa openssl rand -base64 48)"
            );
        }
        this.secretKey = Keys.hmacShaKeyFor(keyBytes);
    }

    public String createAccessToken(long userId, String email) {
        return buildToken(userId, email, TYPE_ACCESS, properties.getJwtAccessTtlMinutes() * 60L);
    }

    public String createRefreshToken(long userId, String email) {
        return buildToken(userId, email, TYPE_REFRESH, properties.getJwtRefreshTtlDays() * 24L * 3600L);
    }

    private String buildToken(long userId, String email, String type, long ttlSeconds) {
        Instant now = Instant.now();
        return Jwts.builder()
                .subject(Long.toString(userId))
                .claim("email", email)
                .claim(CLAIM_TYPE, type)
                .issuedAt(Date.from(now))
                .expiration(Date.from(now.plusSeconds(ttlSeconds)))
                .signWith(secretKey)
                .compact();
    }

    public ParsedToken parse(String token, String expectedType) {
        try {
            Claims claims = Jwts.parser()
                    .verifyWith(secretKey)
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();
            String type = claims.get(CLAIM_TYPE, String.class);
            if (!expectedType.equals(type)) {
                throw new JwtException("Tipo de token incorrecto");
            }
            long userId = Long.parseLong(claims.getSubject());
            String email = claims.get("email", String.class);
            return new ParsedToken(userId, email, type);
        } catch (JwtException | NumberFormatException e) {
            throw new JwtException("Token inválido o expirado", e);
        }
    }

    public record ParsedToken(long userId, String email, String type) {
    }
}
