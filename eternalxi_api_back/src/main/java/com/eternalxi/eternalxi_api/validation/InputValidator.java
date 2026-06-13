package com.eternalxi.eternalxi_api.validation;

import java.time.LocalDate;
import java.time.Period;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.regex.Pattern;

public final class InputValidator {

    private InputValidator() {}

    private static final Pattern NICKNAME_PATTERN = Pattern.compile("^[\\p{L}\\p{N}_\\-.]{3,24}$");
    private static final Pattern EMAIL_PATTERN = Pattern.compile("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$");
    private static final Pattern LEAGUE_NAME_PATTERN = Pattern.compile("^[\\p{L}\\p{N} _\\-.]{3,50}$");
    private static final Pattern INVITATION_CODE_PATTERN = Pattern.compile("^[A-Z0-9]{4,20}$");
    private static final Pattern CONTROL_CHARS = Pattern.compile("[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F\\x7F]");
    private static final DateTimeFormatter ISO_DATE = DateTimeFormatter.ISO_LOCAL_DATE;
    public static final int MINIMUM_AGE_YEARS = 13;

    public static LocalDate validateBirthDate(String fechaNacimiento) {
        if (fechaNacimiento == null || fechaNacimiento.isBlank()) {
            throw new IllegalArgumentException("La fecha de nacimiento es obligatoria.");
        }
        LocalDate birth;
        try {
            birth = LocalDate.parse(fechaNacimiento.trim(), ISO_DATE);
        } catch (DateTimeParseException e) {
            throw new IllegalArgumentException("La fecha de nacimiento no es válida.");
        }
        LocalDate today = LocalDate.now();
        if (birth.isAfter(today)) {
            throw new IllegalArgumentException("La fecha de nacimiento no puede ser futura.");
        }
        if (birth.isBefore(today.minusYears(120))) {
            throw new IllegalArgumentException("La fecha de nacimiento no es válida.");
        }
        int age = Period.between(birth, today).getYears();
        if (age < MINIMUM_AGE_YEARS) {
            throw new IllegalArgumentException(
                    "Debes tener al menos " + MINIMUM_AGE_YEARS + " años para usar Eternal XI.");
        }
        return birth;
    }

    public static void requireTermsAccepted(Boolean aceptaTerminos) {
        if (aceptaTerminos == null || !aceptaTerminos) {
            throw new IllegalArgumentException("Debes aceptar los términos de servicio y la política de privacidad.");
        }
    }

    public static String validateNickname(String nickname) {
        if (nickname == null || nickname.isBlank()) {
            throw new IllegalArgumentException("El nickname es obligatorio.");
        }
        String trimmed = nickname.trim();
        if (trimmed.length() < 3 || trimmed.length() > 24) {
            throw new IllegalArgumentException("El nickname debe tener entre 3 y 24 caracteres.");
        }
        if (!NICKNAME_PATTERN.matcher(trimmed).matches()) {
            throw new IllegalArgumentException("El nickname solo puede contener letras, números, guiones, puntos y guiones bajos.");
        }
        return trimmed;
    }

    public static String validateEmail(String email) {
        if (email == null || email.isBlank()) {
            throw new IllegalArgumentException("El correo es obligatorio.");
        }
        String trimmed = email.trim().toLowerCase();
        if (trimmed.length() > 190) {
            throw new IllegalArgumentException("El correo es demasiado largo (máximo 190 caracteres).");
        }
        if (!EMAIL_PATTERN.matcher(trimmed).matches()) {
            throw new IllegalArgumentException("El formato del correo no es válido.");
        }
        return trimmed;
    }

    public static String validatePassword(String password) {
        if (password == null || password.isBlank()) {
            throw new IllegalArgumentException("La contraseña es obligatoria.");
        }
        if (password.length() < 8) {
            throw new IllegalArgumentException("La contraseña debe tener al menos 8 caracteres.");
        }
        if (password.length() > 128) {
            throw new IllegalArgumentException("La contraseña es demasiado larga (máximo 128 caracteres).");
        }
        return password;
    }

    public static String validateLeagueName(String name) {
        if (name == null || name.isBlank()) {
            throw new IllegalArgumentException("El nombre de la liga es obligatorio.");
        }
        String trimmed = name.trim();
        if (trimmed.length() < 3 || trimmed.length() > 50) {
            throw new IllegalArgumentException("El nombre de la liga debe tener entre 3 y 50 caracteres.");
        }
        if (!LEAGUE_NAME_PATTERN.matcher(trimmed).matches()) {
            throw new IllegalArgumentException("El nombre de la liga contiene caracteres no permitidos.");
        }
        return trimmed;
    }

    public static String validateInvitationCode(String code) {
        if (code == null || code.isBlank()) {
            throw new IllegalArgumentException("El código de invitación es obligatorio.");
        }
        String trimmed = code.trim().toUpperCase();
        if (!INVITATION_CODE_PATTERN.matcher(trimmed).matches()) {
            throw new IllegalArgumentException("Formato de código de invitación no válido.");
        }
        return trimmed;
    }

    public static String sanitizeSearchText(String text, int maxLength) {
        if (text == null) return null;
        String sanitized = CONTROL_CHARS.matcher(text).replaceAll("");
        sanitized = sanitized.trim();
        if (sanitized.length() > maxLength) {
            sanitized = sanitized.substring(0, maxLength);
        }
        return sanitized;
    }

    public static long validatePositiveAmount(Long amount, String fieldName) {
        if (amount == null) {
            throw new IllegalArgumentException(fieldName + " es obligatorio.");
        }
        if (amount <= 0) {
            throw new IllegalArgumentException(fieldName + " debe ser un número entero positivo.");
        }
        if (amount > 999_999_999_999L) {
            throw new IllegalArgumentException(fieldName + " es demasiado grande.");
        }
        return amount;
    }

    public static int validatePositiveInt(Integer value, String fieldName) {
        if (value == null) {
            throw new IllegalArgumentException(fieldName + " es obligatorio.");
        }
        if (value <= 0) {
            throw new IllegalArgumentException(fieldName + " debe ser un número entero positivo.");
        }
        return value;
    }
}
