package com.eternalxi.eternalxi_api.exception;

public class LeagueRewardConflictException extends BusinessException {
    public LeagueRewardConflictException(String message) {
        super("REWARD_CONFLICT", message, 409);
    }
    public LeagueRewardConflictException(String errorCode, String message) {
        super(errorCode, message, 409);
    }
}
