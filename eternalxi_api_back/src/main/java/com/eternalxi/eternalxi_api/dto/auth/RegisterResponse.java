package com.eternalxi.eternalxi_api.dto.auth;

import com.eternalxi.eternalxi_api.dto.user.UserResponse;

public record RegisterResponse(
        String message,
        UserResponse user
) {}