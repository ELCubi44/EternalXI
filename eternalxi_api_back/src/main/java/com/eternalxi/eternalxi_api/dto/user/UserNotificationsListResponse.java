package com.eternalxi.eternalxi_api.dto.user;

import java.util.List;

public record UserNotificationsListResponse(
        List<UserNotificationItemResponse> items,
        int noLeidas
) {
}
