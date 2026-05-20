package com.eternalxi.eternalxi_api.dto.auth;

import com.eternalxi.eternalxi_api.dto.user.UserResponse;

public record AuthResponse(
        String accessToken,
        String refreshToken,
        String tokenType,
        UserResponse user
) {}