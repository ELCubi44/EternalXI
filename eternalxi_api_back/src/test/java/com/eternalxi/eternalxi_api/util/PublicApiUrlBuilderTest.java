package com.eternalxi.eternalxi_api.util;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;

class PublicApiUrlBuilderTest {

    private static final String SAMPLE_TOKEN = "abc123token";

    @Test
    void buildConfirmUrlWhenBaseWithoutApiV1() {
        String url = PublicApiUrlBuilder.buildAccountDeletionConfirmUrl(
                "http://217.154.184.202:8080",
                SAMPLE_TOKEN
        );
        assertEquals(
                "http://217.154.184.202:8080/api/v1/account/deletion/confirm?token=" + SAMPLE_TOKEN,
                url
        );
    }

    @Test
    void buildConfirmUrlWhenBaseAlreadyIncludesApiV1() {
        String url = PublicApiUrlBuilder.buildAccountDeletionConfirmUrl(
                "https://api.eternalxi.com/api/v1",
                SAMPLE_TOKEN
        );
        assertEquals(
                "https://api.eternalxi.com/api/v1/account/deletion/confirm?token=" + SAMPLE_TOKEN,
                url
        );
        assertFalse(url.contains("/api/v1/api/v1/"));
    }

    @Test
    void buildConfirmUrlWhenBaseHasTrailingSlash() {
        String url = PublicApiUrlBuilder.buildAccountDeletionConfirmUrl(
                "http://217.154.184.202:8080/",
                SAMPLE_TOKEN
        );
        assertEquals(
                "http://217.154.184.202:8080/api/v1/account/deletion/confirm?token=" + SAMPLE_TOKEN,
                url
        );
    }

    @Test
    void buildConfirmUrlWhenBaseIncludesApiV1WithTrailingSlash() {
        String url = PublicApiUrlBuilder.buildAccountDeletionConfirmUrl(
                "https://api.eternalxi.com/api/v1/",
                SAMPLE_TOKEN
        );
        assertEquals(
                "https://api.eternalxi.com/api/v1/account/deletion/confirm?token=" + SAMPLE_TOKEN,
                url
        );
        assertFalse(url.contains("/api/v1/api/v1/"));
    }

}
