-- Evita reintentos infinitos del scheduler cuando la preparación falla por error estructural (formación/plantilla).
ALTER TABLE partidos_jornada
    ADD COLUMN preparacion_bloqueada_en TIMESTAMP NULL DEFAULT NULL,
    ADD COLUMN preparacion_bloqueada_motivo VARCHAR(512) NULL DEFAULT NULL;

CREATE INDEX idx_pj_preparacion_bloqueada
    ON partidos_jornada (preparacion_bloqueada_en, estado);
