package com.eternalxi.eternalxi_api.util;

public final class PublicApiUrlBuilder {

    private static final String API_V1_SUFFIX = "/api/v1";
    private static final String ACCOUNT_DELETION_CONFIRM_PATH = "/account/deletion/confirm";

    private PublicApiUrlBuilder() {
    }

    public static String normalizePublicApiBaseUrl(String raw) {
        if (raw == null || raw.isBlank()) {
            throw new IllegalArgumentException("public-api-base-url requerido");
        }
        String base = raw.trim();
        while (base.endsWith("/")) {
            base = base.substring(0, base.length() - 1);
        }
        return base;
    }

    public static String apiV1Root(String publicApiBaseUrl) {
        String base = normalizePublicApiBaseUrl(publicApiBaseUrl);
        if (base.endsWith(API_V1_SUFFIX)) {
            return base;
        }
        return base + API_V1_SUFFIX;
    }

    public static String buildAccountDeletionConfirmUrl(String publicApiBaseUrl, String token) {
        if (token == null || token.isBlank()) {
            throw new IllegalArgumentException("token requerido");
        }
        return apiV1Root(publicApiBaseUrl) + ACCOUNT_DELETION_CONFIRM_PATH + "?token=" + token;
    }
}
