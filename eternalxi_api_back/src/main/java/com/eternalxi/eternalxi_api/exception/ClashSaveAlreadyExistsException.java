package com.eternalxi.eternalxi_api.exception;

public class ClashSaveAlreadyExistsException extends BusinessException {
    public ClashSaveAlreadyExistsException() {
        super("CLASH_SAVE_ALREADY_EXISTS", "Ya existe una partida Clash para este usuario", 409);
    }
}
