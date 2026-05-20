-- Manual (prod sin Flyway o adelantar migración):
-- V20260520120000__liga_recompensa_eventos_kick_preservar.sql
-- Ejecutar ANTES de desplegar el backend con cleanup de recompensas en kick/leave.

ALTER TABLE liga_recompensa_eventos
    ADD COLUMN id_usuario_snapshot BIGINT NULL AFTER id_usuario,
    ADD COLUMN nickname_snapshot VARCHAR(50) NULL AFTER id_usuario_snapshot;

UPDATE liga_recompensa_eventos e
    INNER JOIN liga_participantes lp ON lp.id = e.id_liga_participante
    INNER JOIN usuarios u ON u.id = lp.id_usuario
SET e.id_usuario = COALESCE(e.id_usuario, lp.id_usuario),
    e.id_usuario_snapshot = COALESCE(e.id_usuario_snapshot, lp.id_usuario),
    e.nickname_snapshot = COALESCE(e.nickname_snapshot, u.nickname)
WHERE e.id_liga_participante IS NOT NULL;

UPDATE liga_recompensa_eventos e
    INNER JOIN liga_participantes lp ON lp.id = e.id_liga_participante_objetivo
    INNER JOIN usuarios u ON u.id = lp.id_usuario
SET e.id_usuario_snapshot = COALESCE(e.id_usuario_snapshot, lp.id_usuario),
    e.nickname_snapshot = COALESCE(e.nickname_snapshot, u.nickname)
WHERE e.id_liga_participante_objetivo IS NOT NULL
  AND e.id_usuario_snapshot IS NULL;

ALTER TABLE liga_recompensa_eventos DROP FOREIGN KEY fk_lre_participante;
ALTER TABLE liga_recompensa_eventos
    ADD CONSTRAINT fk_lre_participante
        FOREIGN KEY (id_liga_participante) REFERENCES liga_participantes (id)
        ON DELETE SET NULL;

ALTER TABLE liga_recompensa_eventos DROP FOREIGN KEY fk_lre_part_obj;
ALTER TABLE liga_recompensa_eventos
    ADD CONSTRAINT fk_lre_part_obj
        FOREIGN KEY (id_liga_participante_objetivo) REFERENCES liga_participantes (id)
        ON DELETE SET NULL;

ALTER TABLE liga_recompensa_eventos DROP FOREIGN KEY fk_lre_carta;
ALTER TABLE liga_recompensa_eventos
    ADD CONSTRAINT fk_lre_carta
        FOREIGN KEY (id_carta) REFERENCES liga_participante_cartas (id)
        ON DELETE SET NULL;
