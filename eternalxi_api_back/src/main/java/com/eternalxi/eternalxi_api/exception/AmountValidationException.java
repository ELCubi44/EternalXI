package com.eternalxi.eternalxi_api.exception;

public class AmountValidationException extends BusinessException {
    public AmountValidationException(String message) {
        super("AMOUNT_MUST_BE_INTEGER", message, 400);
    }
    public AmountValidationException(String errorCode, String message) {
        super(errorCode, message, 400);
    }
}
