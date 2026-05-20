-- Puntos de recompensa por liga (antes eran globales en usuario_recursos)
ALTER TABLE liga_participantes
    ADD COLUMN puntos_recompensa BIGINT NOT NULL DEFAULT 0;

-- Tipo de movimiento para premios de jornada en puntos de recompensa
-- (recompensas_jornada sigue existiendo para idempotencia)
