package com.eternalxi.eternalxi_api.config;

import org.springframework.core.env.Environment;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public final class DBConnection {

    private static volatile Environment environment;

    private DBConnection() {
    }

    public static void bindEnvironment(Environment env) {
        environment = env;
    }

    public static Connection getConnection() throws SQLException {
        String url = resolve("eternalxi.db.url", "ETERNALXI_DB_URL", "jdbc:mysql://localhost:3306/EternalXI");
        String user = resolve("eternalxi.db.username", "ETERNALXI_DB_USER", "userRoot");
        String password = resolve("eternalxi.db.password", "ETERNALXI_DB_PASSWORD", null);
        if (password == null || password.isBlank()) {
            throw new SQLException(
                    "Falta la contraseña de base de datos. Define ETERNALXI_DB_PASSWORD o eternalxi.db.password."
            );
        }
        return DriverManager.getConnection(url, user, password);
    }

    private static String resolve(String propertyKey, String envKey, String defaultValue) {
        String fromEnv = System.getenv(envKey);
        if (fromEnv != null && !fromEnv.isBlank()) {
            return fromEnv.trim();
        }
        Environment env = environment;
        if (env != null) {
            String fromProps = env.getProperty(propertyKey);
            if (fromProps != null && !fromProps.isBlank()) {
                return fromProps.trim();
            }
        }
        return defaultValue;
    }
}
