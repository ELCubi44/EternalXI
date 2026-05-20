-- Configuración de creación de liga (solo DEFAULTs; ligas existentes conservan comportamiento legacy).
ALTER TABLE ligas
    ADD COLUMN semana_previa_fichajes BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN permite_entresemana BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN ida_y_vuelta BOOLEAN NOT NULL DEFAULT TRUE,
    ADD COLUMN max_participantes INT NOT NULL DEFAULT 10,
    ADD COLUMN recompensa_base_jornada INT NOT NULL DEFAULT 150,
    ADD COLUMN recompensa_bonus_ganador INT NOT NULL DEFAULT 250,
    ADD COLUMN dinero_por_punto_fantasy BIGINT NOT NULL DEFAULT 100000;
