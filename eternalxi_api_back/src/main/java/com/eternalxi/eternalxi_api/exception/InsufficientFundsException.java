package com.eternalxi.eternalxi_api.exception;

public class InsufficientFundsException extends BusinessException {
    public InsufficientFundsException(String message) {
        super("INSUFFICIENT_FUNDS", message, 409);
    }
}
