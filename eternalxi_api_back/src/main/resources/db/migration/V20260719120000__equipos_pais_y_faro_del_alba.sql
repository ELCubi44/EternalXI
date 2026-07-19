-- País del equipo + rebalance Faro del Alba (Portugal; as Clash = Brisamar LAT).
-- Nota: jugadores.posicion en BD sigue siendo ENUM POR/DEF/MED/DEL.
-- Las posiciones finas (LAT/DFC/MCD/MCO/EXT) viven en el catálogo Clash.

SET @exist := (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'equipos'
      AND COLUMN_NAME = 'pais'
);
SET @sql := IF(
    @exist = 0,
    'ALTER TABLE equipos ADD COLUMN pais VARCHAR(64) NULL COMMENT ''País/sede del club'' AFTER nombre',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

UPDATE equipos SET pais = 'España' WHERE nombre = 'Eternal XI';
UPDATE equipos SET pais = 'Japón' WHERE nombre = 'Furia Menuda';
UPDATE equipos SET pais = 'Francia' WHERE nombre = 'Academia Zenith';
UPDATE equipos SET pais = 'España' WHERE nombre = 'Asfalto Sur';
UPDATE equipos SET pais = 'Rumanía' WHERE nombre = 'Ojo Vigilante';
UPDATE equipos SET pais = 'Australia' WHERE nombre = 'Instinto Real';
UPDATE equipos SET pais = 'Estados Unidos' WHERE nombre = 'Legado Unido';
UPDATE equipos SET pais = 'Grecia' WHERE nombre = 'Panteon Caido';
UPDATE equipos SET pais = 'Inglaterra' WHERE nombre = 'Colegio Runaria';
UPDATE equipos SET pais = 'Alemania' WHERE nombre = 'Bastion Adler';
UPDATE equipos SET pais = 'China' WHERE nombre = 'Academia Tianlong';
UPDATE equipos SET pais = 'Corea del Sur' WHERE nombre = 'Sistema Cero';
UPDATE equipos SET pais = 'Noruega' WHERE nombre = 'Pico Artico';
UPDATE equipos SET pais = 'Egipto' WHERE nombre = 'Dunas Movedizas';
UPDATE equipos SET pais = 'Brasil' WHERE nombre = 'Favela Estrela';
UPDATE equipos SET pais = 'Portugal' WHERE nombre = 'Faro del Alba';

UPDATE jugadores SET posicion = 'POR', valoracion = 85, estilo = 'PRECISO', pais = 'Portugal' WHERE id_equipo = 31 AND dorsal = 1;
UPDATE jugadores SET posicion = 'POR', valoracion = 75, estilo = 'PICARO', pais = 'Portugal' WHERE id_equipo = 31 AND dorsal = 13;

UPDATE jugadores SET posicion = 'DEF', valoracion = 88, estilo = 'PRECISO', pais = 'Portugal' WHERE id_equipo = 31 AND dorsal = 10;
UPDATE jugadores SET posicion = 'DEF', valoracion = 80, estilo = 'POTENTE', pais = 'Portugal' WHERE id_equipo = 31 AND dorsal = 2;
UPDATE jugadores SET posicion = 'DEF', valoracion = 77, estilo = 'VALIENTE', pais = 'Portugal' WHERE id_equipo = 31 AND dorsal = 3;

UPDATE jugadores SET posicion = 'DEF', valoracion = 80, estilo = 'POTENTE', pais = 'Portugal' WHERE id_equipo = 31 AND dorsal = 4;
UPDATE jugadores SET posicion = 'DEF', valoracion = 83, estilo = 'VALIENTE', pais = 'Portugal' WHERE id_equipo = 31 AND dorsal = 5;
UPDATE jugadores SET posicion = 'DEF', valoracion = 73, estilo = 'PRECISO', pais = 'Brasil' WHERE id_equipo = 31 AND dorsal = 15;

UPDATE jugadores SET posicion = 'MED', valoracion = 82, estilo = 'AGIL', pais = 'Portugal' WHERE id_equipo = 31 AND dorsal = 6;
UPDATE jugadores SET posicion = 'MED', valoracion = 81, estilo = 'PICARO', pais = 'Portugal' WHERE id_equipo = 31 AND dorsal = 14;
UPDATE jugadores SET posicion = 'MED', valoracion = 72, estilo = 'PICARO', pais = 'Portugal' WHERE id_equipo = 31 AND dorsal = 20;

UPDATE jugadores SET posicion = 'MED', valoracion = 78, estilo = 'VALIENTE', pais = 'Portugal' WHERE id_equipo = 31 AND dorsal = 8;
UPDATE jugadores SET posicion = 'MED', valoracion = 76, estilo = 'AGIL', pais = 'Portugal' WHERE id_equipo = 31 AND dorsal = 16;
UPDATE jugadores SET posicion = 'MED', valoracion = 76, estilo = 'PRECISO', pais = 'Brasil' WHERE id_equipo = 31 AND dorsal = 22;

UPDATE jugadores SET posicion = 'DEL', valoracion = 84, estilo = 'AGIL', pais = 'Portugal' WHERE id_equipo = 31 AND dorsal = 7;
UPDATE jugadores SET posicion = 'DEL', valoracion = 83, estilo = 'PRECISO', pais = 'Portugal' WHERE id_equipo = 31 AND dorsal = 11;
UPDATE jugadores SET posicion = 'DEL', valoracion = 83, estilo = 'AGIL', pais = 'Portugal' WHERE id_equipo = 31 AND dorsal = 9;

UPDATE jugadores SET posicion = 'DEL', valoracion = 86, estilo = 'POTENTE', pais = 'Portugal' WHERE id_equipo = 31 AND dorsal = 19;
UPDATE jugadores SET posicion = 'DEL', valoracion = 70, estilo = 'PICARO', pais = 'Portugal' WHERE id_equipo = 31 AND dorsal = 18;
