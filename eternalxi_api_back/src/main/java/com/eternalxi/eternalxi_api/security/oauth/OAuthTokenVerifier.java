package com.eternalxi.eternalxi_api.security.oauth;

import com.eternalxi.eternalxi_api.config.EternalxiSecurityProperties;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.jwk.source.JWKSource;
import com.nimbusds.jose.jwk.source.RemoteJWKSet;
import com.nimbusds.jose.proc.JWSKeySelector;
import com.nimbusds.jose.proc.JWSVerificationKeySelector;
import com.nimbusds.jose.proc.SecurityContext;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;
import com.nimbusds.jwt.proc.ConfigurableJWTProcessor;
import com.nimbusds.jwt.proc.DefaultJWTProcessor;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.net.URL;
import java.time.Instant;
import java.util.Arrays;
import java.util.Locale;
import java.util.Set;
import java.util.stream.Collectors;

@Component
public class OAuthTokenVerifier {

    private static final String GOOGLE_TOKEN_INFO = "https://oauth2.googleapis.com/tokeninfo";
    private static final String APPLE_JWKS_URL = "https://appleid.apple.com/auth/keys";
    private static final String APPLE_ISSUER = "https://appleid.apple.com";

    private final EternalxiSecurityProperties securityProperties;
    private final RestClient restClient;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public OAuthTokenVerifier(EternalxiSecurityProperties securityProperties) {
        this.securityProperties = securityProperties;
        this.restClient = RestClient.create();
    }

    public VerifiedOAuthIdentity verifyGoogle(String idToken) {
        if (idToken == null || idToken.isBlank()) {
            throw new IllegalArgumentException("Token de Google no valido");
        }
        try {
            String body = restClient.get()
                    .uri(GOOGLE_TOKEN_INFO + "?id_token={token}", idToken.trim())
                    .retrieve()
                    .body(String.class);
            JsonNode json = objectMapper.readTree(body);
            if (json.has("error_description") || json.has("error")) {
                throw new IllegalArgumentException("Token de Google no valido");
            }
            String subject = text(json, "sub");
            String email = text(json, "email");
            boolean emailVerified = "true".equalsIgnoreCase(text(json, "email_verified"));
            String audience = text(json, "aud");
            validateGoogleAudience(audience);
            if (email == null || email.isBlank()) {
                throw new IllegalArgumentException("Google no devolvio un correo valido");
            }
            if (!emailVerified) {
                throw new IllegalArgumentException("El correo de Google no esta verificado");
            }
            String name = text(json, "name");
            return new VerifiedOAuthIdentity("GOOGLE", subject, email.toLowerCase(Locale.ROOT), name);
        } catch (IllegalArgumentException e) {
            throw e;
        } catch (Exception e) {
            throw new IllegalArgumentException("No se pudo validar el token de Google");
        }
    }

    public VerifiedOAuthIdentity verifyApple(String idToken) {
        if (idToken == null || idToken.isBlank()) {
            throw new IllegalArgumentException("Token de Apple no valido");
        }
        try {
            SignedJWT jwt = SignedJWT.parse(idToken.trim());
            ConfigurableJWTProcessor<SecurityContext> processor = new DefaultJWTProcessor<>();
            JWKSource<SecurityContext> keySource = new RemoteJWKSet<>(new URL(APPLE_JWKS_URL));
            JWSKeySelector<SecurityContext> keySelector = new JWSVerificationKeySelector<>(
                    JWSAlgorithm.RS256,
                    keySource
            );
            processor.setJWSKeySelector(keySelector);
            JWTClaimsSet claims = processor.process(jwt, null);

            if (!APPLE_ISSUER.equals(claims.getIssuer())) {
                throw new IllegalArgumentException("Emisor de Apple no valido");
            }
            Instant exp = claims.getExpirationTime() == null
                    ? Instant.EPOCH
                    : claims.getExpirationTime().toInstant();
            if (exp.isBefore(Instant.now())) {
                throw new IllegalArgumentException("Token de Apple expirado");
            }
            String audience = claims.getAudience() == null || claims.getAudience().isEmpty()
                    ? ""
                    : claims.getAudience().get(0);
            validateAppleAudience(audience);

            String subject = claims.getSubject();
            if (subject == null || subject.isBlank()) {
                throw new IllegalArgumentException("Token de Apple sin identificador");
            }
            String email = claims.getStringClaim("email");
            Boolean emailVerified = claims.getBooleanClaim("email_verified");
            if (email != null && Boolean.FALSE.equals(emailVerified)) {
                throw new IllegalArgumentException("El correo de Apple no esta verificado");
            }
            return new VerifiedOAuthIdentity(
                    "APPLE",
                    subject,
                    email == null ? null : email.toLowerCase(Locale.ROOT),
                    null
            );
        } catch (IllegalArgumentException e) {
            throw e;
        } catch (Exception e) {
            throw new IllegalArgumentException("No se pudo validar el token de Apple");
        }
    }

    private void validateGoogleAudience(String audience) {
        Set<String> allowed = allowedGoogleClientIds();
        if (allowed.isEmpty()) {
            return;
        }
        if (audience == null || !allowed.contains(audience)) {
            throw new IllegalArgumentException("Audiencia de Google no autorizada");
        }
    }

    private void validateAppleAudience(String audience) {
        String bundleId = securityProperties.getOauthAppleBundleId();
        if (bundleId == null || bundleId.isBlank()) {
            return;
        }
        if (!bundleId.equals(audience)) {
            throw new IllegalArgumentException("Audiencia de Apple no autorizada");
        }
    }

    private Set<String> allowedGoogleClientIds() {
        String raw = securityProperties.getOauthGoogleClientIds();
        if (raw == null || raw.isBlank()) {
            return Set.of();
        }
        return Arrays.stream(raw.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .collect(Collectors.toSet());
    }

    private String text(JsonNode json, String field) {
        JsonNode node = json.get(field);
        return node == null || node.isNull() ? null : node.asText();
    }

    public record VerifiedOAuthIdentity(
            String provider,
            String providerUserId,
            String email,
            String displayName
    ) {
    }
}
