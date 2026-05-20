package com.eternalxi.eternalxi_api.dto.user;

public record UpdateUserRequest(
        String nickname,
        Integer nivel
) {}