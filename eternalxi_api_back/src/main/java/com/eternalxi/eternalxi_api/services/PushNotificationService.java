package com.eternalxi.eternalxi_api.services;

import java.util.Map;

public interface PushNotificationService {

    void sendToUser(
            Long idUsuario,
            String title,
            String body,
            Map<String, String> data
    );
}