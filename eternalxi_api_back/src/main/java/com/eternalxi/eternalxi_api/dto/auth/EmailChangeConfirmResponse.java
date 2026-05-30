package com.eternalxi.eternalxi_api.dto.auth;

import com.eternalxi.eternalxi_api.dto.user.UserResponse;

public record EmailChangeConfirmResponse(
        String message,
        UserResponse user
) {}
