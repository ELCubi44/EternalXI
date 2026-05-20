-- Informe valor de mercado (5 ejemplos). Ajustar :id_liga.
-- No modifica datos. Campos de guardrail/target dependen de logs o depuración en applyDynamicRatingCore.

SET @id_liga = 1;

WITH ultimos AS (
    SELECT jp.id_liga_jugador,
           GROUP_CONCAT(jp.puntos ORDER BY j.numero DESC SEPARATOR ',') AS puntos_ult3,
           SUM(jp.minutos_jugados) AS minutos_ult3,
           SUM(jp.goles) AS goles_ult3,
           SUM(jp.asistencias) AS asist_ult3,
           SUM(jp.paradas) AS paradas_ult3
    FROM jugadores_puntos_jornada jp
    INNER JOIN jornadas j ON j.id = jp.id_jornada AND j.id_liga = @id_liga
    INNER JOIN (
        SELECT id_liga_jugador, id_jornada
        FROM (
            SELECT jp2.id_liga_jugador, jp2.id_jornada,
                   ROW_NUMBER() OVER (PARTITION BY jp2.id_liga_jugador ORDER BY j2.numero DESC) AS rn
            FROM jugadores_puntos_jornada jp2
            INNER JOIN jornadas j2 ON j2.id = jp2.id_jornada AND j2.id_liga = @id_liga
        ) x
        WHERE rn <= 3
    ) t ON t.id_liga_jugador = jp.id_liga_jugador AND t.id_jornada = jp.id_jornada
    GROUP BY jp.id_liga_jugador
),
cambios AS (
    SELECT lj.id AS id_liga_jugador,
           j.nombre, j.pila, j.posicion,
           lj.valor_anterior, lj.valor,
           (lj.valor - lj.valor_anterior) AS delta,
           u.puntos_ult3, u.minutos_ult3, u.goles_ult3, u.asist_ult3, u.paradas_ult3
    FROM liga_jugadores lj
    INNER JOIN jugadores j ON j.id = lj.id_jugador
    LEFT JOIN ultimos u ON u.id_liga_jugador = lj.id
    WHERE lj.id_liga = @id_liga
      AND lj.valor_anterior IS NOT NULL
)
-- 1) Sube mucho
(SELECT 'SUBE_MUCHO' AS caso, c.* FROM cambios c ORDER BY delta DESC LIMIT 1)
UNION ALL
-- 2) Baja mucho
(SELECT 'BAJA_MUCHO', c.* FROM cambios c ORDER BY delta ASC LIMIT 1)
UNION ALL
-- 3) Sin cambio, buen partido (delta=0, max puntos última jornada)
(SELECT 'SIN_CAMBIO_BUEN', c.* FROM cambios c
 WHERE delta = 0 ORDER BY CAST(SUBSTRING_INDEX(puntos_ult3, ',', 1) AS SIGNED) DESC LIMIT 1)
UNION ALL
-- 4) Sin cambio, mal partido
(SELECT 'SIN_CAMBIO_MAL', c.* FROM cambios c
 WHERE delta = 0 ORDER BY CAST(SUBSTRING_INDEX(puntos_ult3, ',', 1) AS SIGNED) ASC LIMIT 1)
UNION ALL
-- 5) Caro con delta raro (alto valor, delta lejos de mediana)
(SELECT 'CARO_DELTA_RARO', c.* FROM cambios c
 ORDER BY valor DESC, ABS(delta) DESC LIMIT 1);
