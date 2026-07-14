package com.eternalxi.eternalxi_api.dto.user;

public record UserSearchResultResponse(
        Long id,
        String nickname,
        String foto,
        String relacionAmistad
) {
}
