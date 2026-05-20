ALTER TABLE liga_participantes
ADD CONSTRAINT uk_liga_participantes_liga_usuario UNIQUE (id_liga, id_usuario);

ALTER TABLE liga_jugadores
ADD CONSTRAINT uk_liga_jugadores_liga_jugador UNIQUE (id_liga, id_jugador);

CREATE INDEX idx_liga_participantes_liga ON liga_participantes(id_liga);
CREATE INDEX idx_liga_participantes_usuario ON liga_participantes(id_usuario);
CREATE INDEX idx_liga_jugadores_liga_dueno ON liga_jugadores(id_liga, id_usuario_dueno);
CREATE INDEX idx_liga_jugadores_liga_equipo ON liga_jugadores(id_liga, id_equipo);
CREATE INDEX idx_ligas_codigo_invitacion ON ligas(codigo_invitacion);
CREATE INDEX idx_usuario_temporadas_usuario_temporada ON usuario_temporadas(id_usuario, id_temporada);