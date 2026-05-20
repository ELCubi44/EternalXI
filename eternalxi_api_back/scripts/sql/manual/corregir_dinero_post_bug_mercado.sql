-- ONE-OFF / MANUAL: ejecutar tú una vez en MySQL para corregir el error de dinero (no es migración automática).
-- Regla: dinero = 400_000_000 − SUM(valor) de liga_jugadores del participante en esa liga.

UPDATE liga_participantes lp
LEFT JOIN (
    SELECT id_liga,
           id_usuario_dueno AS id_usuario,
           COALESCE(SUM(valor), 0) AS valor_equipo
    FROM liga_jugadores
    GROUP BY id_liga, id_usuario_dueno
) v ON v.id_liga = lp.id_liga AND v.id_usuario = lp.id_usuario
SET lp.dinero = 400000000 - COALESCE(v.valor_equipo, 0);
