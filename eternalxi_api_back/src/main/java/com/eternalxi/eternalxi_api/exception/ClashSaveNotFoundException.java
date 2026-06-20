package com.eternalxi.eternalxi_api.exception;

public class ClashSaveNotFoundException extends BusinessException {
    public ClashSaveNotFoundException() {
        super("CLASH_SAVE_NOT_FOUND", "No existe partida Clash para este usuario", 404);
    }
}
