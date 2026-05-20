-- Nuevos participantes: 1000 puntos de recompensa por defecto (no altera filas ya existentes).
ALTER TABLE liga_participantes
    MODIFY COLUMN puntos_recompensa BIGINT NOT NULL DEFAULT 1000;
