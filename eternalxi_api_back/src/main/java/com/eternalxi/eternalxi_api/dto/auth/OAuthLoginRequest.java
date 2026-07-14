package com.eternalxi.eternalxi_api.dto.auth;

public record OAuthLoginRequest(
        String idToken,
        Boolean aceptaTerminos,
        String nickname
) {
}
