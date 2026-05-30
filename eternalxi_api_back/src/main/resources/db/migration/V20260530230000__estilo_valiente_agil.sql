-- Ampliar estilos de juego: VALIENTE y AGIL (jugadores + catálogo supertécnicas)

ALTER TABLE jugadores
    MODIFY COLUMN estilo ENUM('PICARO', 'PRECISO', 'POTENTE', 'VALIENTE', 'AGIL') NULL
    COMMENT 'Estilo de juego del jugador';

ALTER TABLE supertecnicas
    MODIFY COLUMN estilo ENUM('PICARO', 'PRECISO', 'POTENTE', 'VALIENTE', 'AGIL') NOT NULL;
