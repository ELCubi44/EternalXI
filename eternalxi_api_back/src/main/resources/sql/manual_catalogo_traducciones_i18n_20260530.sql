-- Manual (prod sin Flyway): tablas de traducción catálogo es/en

CREATE TABLE IF NOT EXISTS temporada_traduccion (
    id_temporada INT NOT NULL,
    locale VARCHAR(5) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    PRIMARY KEY (id_temporada, locale),
    CONSTRAINT fk_temp_trad_temp FOREIGN KEY (id_temporada) REFERENCES temporadas (id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS equipo_traduccion (
    id_equipo INT NOT NULL,
    locale VARCHAR(5) NOT NULL,
    nombre VARCHAR(120) NOT NULL,
    PRIMARY KEY (id_equipo, locale),
    CONSTRAINT fk_equipo_trad_equipo FOREIGN KEY (id_equipo) REFERENCES equipos (id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS jugador_traduccion (
    id_jugador INT NOT NULL,
    locale VARCHAR(5) NOT NULL,
    descripcion TEXT NULL,
    PRIMARY KEY (id_jugador, locale),
    CONSTRAINT fk_jugador_trad_jugador FOREIGN KEY (id_jugador) REFERENCES jugadores (id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS supertecnica_traduccion (
    id_supertecnica BIGINT NOT NULL,
    locale VARCHAR(5) NOT NULL,
    nombre VARCHAR(128) NOT NULL,
    PRIMARY KEY (id_supertecnica, locale),
    CONSTRAINT fk_st_trad_st FOREIGN KEY (id_supertecnica) REFERENCES supertecnicas (id) ON DELETE CASCADE
);

INSERT IGNORE INTO temporada_traduccion (id_temporada, locale, nombre)
SELECT id, 'es', nombre FROM temporadas;

INSERT IGNORE INTO equipo_traduccion (id_equipo, locale, nombre)
SELECT id, 'es', nombre FROM equipos;

INSERT IGNORE INTO jugador_traduccion (id_jugador, locale, descripcion)
SELECT id, 'es', descripcion FROM jugadores
WHERE descripcion IS NOT NULL AND TRIM(descripcion) <> '';
