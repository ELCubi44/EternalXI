package com.eternalxi.eternalxi_api.util;

import java.util.Locale;

public final class LocaleSupport {

    public static final String DEFAULT = "es";
    public static final String EN = "en";

    private LocaleSupport() {
    }

    /**
     * Resuelve locale de catálogo: query {@code lang} &gt; Accept-Language &gt; es.
     */
    public static String resolveCatalogLocale(String queryLang, String acceptLanguage) {
        String fromQuery = normalize(queryLang);
        if (fromQuery != null) {
            return fromQuery;
        }
        return fromAcceptLanguage(acceptLanguage);
    }

    public static String fromAcceptLanguage(String acceptLanguage) {
        if (acceptLanguage == null || acceptLanguage.isBlank()) {
            return DEFAULT;
        }
        for (String part : acceptLanguage.split(",")) {
            String token = part.trim();
            if (token.isEmpty()) {
                continue;
            }
            int semi = token.indexOf(';');
            if (semi >= 0) {
                token = token.substring(0, semi).trim();
            }
            String normalized = normalize(token);
            if (normalized != null) {
                return normalized;
            }
        }
        return DEFAULT;
    }

    private static String normalize(String raw) {
        if (raw == null || raw.isBlank()) {
            return null;
        }
        String value = raw.trim().toLowerCase(Locale.ROOT);
        if (value.startsWith("en")) {
            return EN;
        }
        if (value.startsWith("es")) {
            return DEFAULT;
        }
        return null;
    }
}
