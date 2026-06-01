package com.eternalxi.eternalxi_api.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "eternalxi.security")
public class EternalxiSecurityProperties {

    private String jwtSecret = "";
    private int jwtAccessTtlMinutes = 120;
    private int jwtRefreshTtlDays = 30;
    private int authRateLimitPerMinute = 25;
    private String corsAllowedOrigins = "";

    public String getJwtSecret() {
        return jwtSecret;
    }

    public void setJwtSecret(String jwtSecret) {
        this.jwtSecret = jwtSecret;
    }

    public int getJwtAccessTtlMinutes() {
        return jwtAccessTtlMinutes;
    }

    public void setJwtAccessTtlMinutes(int jwtAccessTtlMinutes) {
        this.jwtAccessTtlMinutes = jwtAccessTtlMinutes;
    }

    public int getJwtRefreshTtlDays() {
        return jwtRefreshTtlDays;
    }

    public void setJwtRefreshTtlDays(int jwtRefreshTtlDays) {
        this.jwtRefreshTtlDays = jwtRefreshTtlDays;
    }

    public int getAuthRateLimitPerMinute() {
        return authRateLimitPerMinute;
    }

    public void setAuthRateLimitPerMinute(int authRateLimitPerMinute) {
        this.authRateLimitPerMinute = authRateLimitPerMinute;
    }

    public String getCorsAllowedOrigins() {
        return corsAllowedOrigins;
    }

    public void setCorsAllowedOrigins(String corsAllowedOrigins) {
        this.corsAllowedOrigins = corsAllowedOrigins;
    }
}
