package com.eternalxi.eternalxi_api.dto.user;

import java.util.List;

public record RegisterAvatarUnlocksRequest(
        List<Long> playerIds,
        String origen
) {
}
