package com.eternalxi.eternalxi_api.services;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.MessagingErrorCode;
import com.google.firebase.messaging.Notification;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.FileInputStream;
import java.io.InputStream;
import java.util.List;
import java.util.Map;

@Service
public class FirebasePushNotificationService implements PushNotificationService {

    private static final Logger log = LoggerFactory.getLogger(FirebasePushNotificationService.class);

    private final UserPushTokenService userPushTokenService;

    @Value("${app.push.enabled:false}")
    private boolean pushEnabled;

    @Value("${app.push.firebase.credentials-path:}")
    private String credentialsPath;

    private volatile boolean firebaseReady = false;

    public FirebasePushNotificationService(UserPushTokenService userPushTokenService) {
        this.userPushTokenService = userPushTokenService;
    }

    @PostConstruct
    public void init() {
        if (!pushEnabled) {
            log.info("Push notifications desactivadas por configuración");
            return;
        }

        if (credentialsPath == null || credentialsPath.isBlank()) {
            log.error("Push activadas pero falta app.push.firebase.credentials-path");
            return;
        }

        try {
            if (FirebaseApp.getApps().isEmpty()) {
                try (InputStream is = new FileInputStream(credentialsPath)) {
                    FirebaseOptions options = FirebaseOptions.builder()
                            .setCredentials(GoogleCredentials.fromStream(is))
                            .build();

                    FirebaseApp.initializeApp(options);
                }
            }

            firebaseReady = true;
            log.info("Firebase Admin inicializado correctamente");
        } catch (Exception e) {
            firebaseReady = false;
            log.error("No se pudo inicializar Firebase Admin: {}", e.getMessage(), e);
        }
    }

    @Override
    public void sendToUser(Long idUsuario, String title, String body, Map<String, String> data) {
        if (!pushEnabled || !firebaseReady || idUsuario == null) {
            return;
        }

        try {
            List<String> tokens = userPushTokenService.findActiveTokensByUser(idUsuario);

            for (String token : tokens) {
                try {
                    Message.Builder builder = Message.builder()
                            .setToken(token)
                            .setNotification(Notification.builder()
                                    .setTitle(title)
                                    .setBody(body)
                                    .build());

                    if (data != null && !data.isEmpty()) {
                        builder.putAllData(data);
                    }

                    FirebaseMessaging.getInstance().send(builder.build());
                } catch (FirebaseMessagingException ex) {
                    MessagingErrorCode code = ex.getMessagingErrorCode();

                    if (code == MessagingErrorCode.UNREGISTERED) {
                        log.warn("Token FCM desregistrado. Se desactiva token={}", token);
                        userPushTokenService.deactivateToken(token);
                    } else {
                        log.warn(
                                "Error FCM enviando push al usuario {} token {}: code={}, msg={}",
                                idUsuario,
                                token,
                                code,
                                ex.getMessage()
                        );
                    }
                } catch (Exception ex) {
                    log.warn(
                            "Error no FCM enviando push al usuario {} token {}: {}",
                            idUsuario,
                            token,
                            ex.getMessage()
                    );
                }
            }
        } catch (Exception e) {
            log.error("Error enviando push al usuario {}: {}", idUsuario, e.getMessage(), e);
        }
    }
}