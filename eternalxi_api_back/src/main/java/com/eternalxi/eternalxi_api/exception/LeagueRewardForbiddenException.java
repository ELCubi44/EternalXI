package com.eternalxi.eternalxi_api.exception;

public class LeagueRewardForbiddenException extends BusinessException {
    public LeagueRewardForbiddenException(String message) {
        super("FORBIDDEN", message, 403);
    }
}
