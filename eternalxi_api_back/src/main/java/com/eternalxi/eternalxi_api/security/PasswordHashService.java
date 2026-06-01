package com.eternalxi.eternalxi_api.security;

import com.eternalxi.eternalxi_api.model.Usuario;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;

@Service
public class PasswordHashService {

    private final PasswordEncoder bcrypt = new BCryptPasswordEncoder(12);

    public String hashForStorage(String plainPassword) {
        return bcrypt.encode(plainPassword);
    }

    /**
     * Acepta BCrypt ({@code $2}) o legado SHA-256 hex sin salt.
     *
     * @return hash BCrypt actualizado si era legado y coincidía (para migración transparente)
     */
    public PasswordMatchResult verifyAndMaybeUpgrade(String plainPassword, String storedHash) {
        if (storedHash == null || storedHash.isBlank()) {
            return PasswordMatchResult.noMatch();
        }
        if (storedHash.startsWith("$2a$") || storedHash.startsWith("$2b$") || storedHash.startsWith("$2y$")) {
            boolean ok = bcrypt.matches(plainPassword, storedHash);
            return ok ? PasswordMatchResult.match(storedHash) : PasswordMatchResult.noMatch();
        }
        String legacy = Usuario.encriptarContrasena(plainPassword);
        if (!legacy.equalsIgnoreCase(storedHash)) {
            return PasswordMatchResult.noMatch();
        }
        return PasswordMatchResult.matchWithUpgrade(hashForStorage(plainPassword));
    }

    public record PasswordMatchResult(boolean matches, String upgradedHashIfAny) {
        static PasswordMatchResult noMatch() {
            return new PasswordMatchResult(false, null);
        }

        static PasswordMatchResult match(String current) {
            return new PasswordMatchResult(true, null);
        }

        static PasswordMatchResult matchWithUpgrade(String upgraded) {
            return new PasswordMatchResult(true, upgraded);
        }
    }
}
