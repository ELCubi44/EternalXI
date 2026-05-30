-- Manual (prod sin Flyway): ficha jugador + catálogo supertécnicas
-- Ejecutar una vez. Si alguna columna ya existe, omitir esa línea del ALTER.

ALTER TABLE jugadores
    ADD COLUMN pais VARCHAR(64) NULL COMMENT 'País de origen' AFTER genero;

ALTER TABLE jugadores
    ADD COLUMN altura SMALLINT UNSIGNED NULL COMMENT 'Altura en cm' AFTER pais;

ALTER TABLE jugadores
    ADD COLUMN estilo ENUM('PICARO', 'PRECISO', 'POTENTE') NULL AFTER altura;

-- Si existía la versión anterior monolítica, eliminarla antes:
-- DROP TABLE IF EXISTS jugador_supertecnicas;

CREATE TABLE IF NOT EXISTS supertecnicas (
    id BIGINT NOT NULL AUTO_INCREMENT,
    nombre VARCHAR(128) NOT NULL,
    potencia TINYINT UNSIGNED NOT NULL,
    tipo ENUM('REGATE', 'DEFENSA', 'PARADA', 'TIRO') NOT NULL,
    estilo ENUM('PICARO', 'PRECISO', 'POTENTE') NOT NULL,
    creado_en TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id),
    UNIQUE KEY uk_supertecnica_def (nombre, potencia, tipo, estilo),
    KEY idx_supertecnicas_tipo (tipo)
);

CREATE TABLE IF NOT EXISTS jugador_supertecnica (
    id BIGINT NOT NULL AUTO_INCREMENT,
    id_jugador INT NOT NULL,
    id_supertecnica BIGINT NOT NULL,
    orden TINYINT UNSIGNED NOT NULL,
    creado_en TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id),
    UNIQUE KEY uk_jugador_supertecnica_orden (id_jugador, orden),
    UNIQUE KEY uk_jugador_supertecnica_par (id_jugador, id_supertecnica),
    KEY idx_jugador_supertecnica_supertecnica (id_supertecnica),
    CONSTRAINT fk_js_jugador FOREIGN KEY (id_jugador) REFERENCES jugadores (id) ON DELETE CASCADE,
    CONSTRAINT fk_js_supertecnica FOREIGN KEY (id_supertecnica) REFERENCES supertecnicas (id) ON DELETE RESTRICT
);

-- =============================================================================
-- DESCRIBE lógico (para ChatGPT / carga de datos)
-- =============================================================================
--
-- ORDEN DE INSERCIÓN:
--   1. temporadas
--   2. equipos              (id_temporada)
--   3. jugadores            (id_equipo)
--   4. supertecnicas        (catálogo; reutilizar id si ya existe la misma definición)
--   5. jugador_supertecnica (enlace: id_jugador + id_supertecnica + orden 1..4)
--
-- --- supertecnicas (catálogo compartido) ---
-- id        BIGINT PK AUTO_INCREMENT
-- nombre    VARCHAR       — ej. Tacón de Porcelana
-- potencia  TINYINT       — ej. 25
-- tipo      ENUM          — REGATE | DEFENSA | PARADA | TIRO
-- estilo    ENUM          — PICARO | PRECISO | POTENTE
-- UNIQUE(nombre, potencia, tipo, estilo) — evita duplicar la misma técnica en catálogo
--
-- --- jugador_supertecnica (asignación al jugador) ---
-- id_jugador       INT FK → jugadores.id
-- id_supertecnica  BIGINT FK → supertecnicas.id
-- orden            TINYINT 1-4 — slot del jugador (único por jugador)
-- UNIQUE(id_jugador, id_supertecnica) — un jugador no lleva la misma ST dos veces
-- Varios jugadores pueden compartir el mismo id_supertecnica.
--
-- CARGA DE supertecnicas:
-- - Si la técnica ya existe (mismo nombre+potencia+tipo+estilo), reutiliza su id:
--     SELECT id FROM supertecnicas WHERE nombre=? AND potencia=? AND tipo=? AND estilo=?;
-- - Si no existe, INSERT y usa LAST_INSERT_ID().
-- - O INSERT IGNORE / ON DUPLICATE KEY UPDATE id=LAST_INSERT_ID(id) según prefieras.
--
-- =============================================================================
-- EJEMPLO: Sacha Legrand + supertécnicas (algunas reutilizables entre jugadores)
-- =============================================================================

INSERT INTO temporadas (nombre, foto)
VALUES ('Dream Eleven — Temporada 1', NULL);
SET @id_temporada = LAST_INSERT_ID();

INSERT INTO equipos (nombre, id_temporada, foto)
VALUES ('Nombre del club de Sacha', @id_temporada, NULL);
SET @id_equipo = LAST_INSERT_ID();

INSERT INTO jugadores (
    id_equipo, nombre, pila, dorsal, descripcion, valoracion,
    genero, posicion, pais, altura, estilo, foto
) VALUES (
    @id_equipo,
    'Sacha Legrand',
    'Sacha',
    19,
    'Sacha es un chico tranquilo y elegante...',
    77,
    'H',
    'MED',
    'Francia',
    174,
    'PRECISO',
    NULL
);
SET @id_jugador = LAST_INSERT_ID();

-- Catálogo de supertécnicas (INSERT IGNORE si ya existían por otro jugador)
INSERT IGNORE INTO supertecnicas (nombre, potencia, tipo, estilo) VALUES
('Tacón de Porcelana',    25, 'REGATE', 'PICARO'),
('Paso de Galería',       45, 'REGATE', 'PRECISO'),
('Disparo de Campanario', 35, 'TIRO',   'PRECISO'),
('Rayo de Salón',         55, 'TIRO',   'POTENTE');

SELECT id INTO @st1 FROM supertecnicas WHERE nombre='Tacón de Porcelana'    AND potencia=25 AND tipo='REGATE' AND estilo='PICARO'   LIMIT 1;
SELECT id INTO @st2 FROM supertecnicas WHERE nombre='Paso de Galería'       AND potencia=45 AND tipo='REGATE' AND estilo='PRECISO'  LIMIT 1;
SELECT id INTO @st3 FROM supertecnicas WHERE nombre='Disparo de Campanario' AND potencia=35 AND tipo='TIRO'   AND estilo='PRECISO'  LIMIT 1;
SELECT id INTO @st4 FROM supertecnicas WHERE nombre='Rayo de Salón'         AND potencia=55 AND tipo='TIRO'   AND estilo='POTENTE'  LIMIT 1;

INSERT INTO jugador_supertecnica (id_jugador, id_supertecnica, orden) VALUES
(@id_jugador, @st1, 1),
(@id_jugador, @st2, 2),
(@id_jugador, @st3, 3),
(@id_jugador, @st4, 4);

-- Otro jugador con 2 supertécnicas repetidas (reutiliza @st1 y @st3):
-- INSERT INTO jugadores (...) VALUES (...);
-- SET @id_jugador_2 = LAST_INSERT_ID();
-- INSERT INTO jugador_supertecnica (id_jugador, id_supertecnica, orden) VALUES
-- (@id_jugador_2, @st1, 1),
-- (@id_jugador_2, @st3, 2),
-- (@id_jugador_2, @st_nueva, 3),
-- (@id_jugador_2, @st_otra, 4);
