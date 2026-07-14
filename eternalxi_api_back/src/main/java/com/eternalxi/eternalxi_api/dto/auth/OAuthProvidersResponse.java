package com.eternalxi.eternalxi_api.dto.auth;

public record OAuthProvidersResponse(
        boolean google,
        boolean apple
) {
}
