package com.eternalxi.eternalxi_api.exception;

public class InputValidationException extends BusinessException {
    public InputValidationException(String message) {
        super("VALIDATION_ERROR", message, 400);
    }
    public InputValidationException(String errorCode, String message) {
        super(errorCode, message, 400);
    }
}
