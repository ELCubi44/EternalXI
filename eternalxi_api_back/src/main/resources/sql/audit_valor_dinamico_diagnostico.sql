-- Auditoría valor dinámico — SOLO LECTURA
-- Ajustar @id_liga. targetValue/guardrail exactos: ver logs "Dynamic value guardrail" o depuración Java.

SET @id_liga = 7;

-- Base: estado actual + último partido + media últimos 3 + modificador carta
WITH base AS (
    SELECT lj.id AS id_liga_jugador,
           lj.id_liga,
           j.id AS id_jugador,
           COALESCE(NULLIF(TRIM(j.pila), ''), j.nombre) AS jugador,
           j.posicion,
           lj.valor AS valor_actual,
           lj.valor_anterior,
           (lj.valor - COALESCE(lj.valor_anterior, lj.valor)) AS delta_valor,
           CAST(ROUND(COALESCE(lj.valoracion_actual, j.valoracion), 2) AS DECIMAL(5,2)) AS valoracion_actual,
           lj.estado AS estado_liga,
           COALESCE((
               SELECT AVG(t.puntos)
               FROM (
                   SELECT jp.puntos
                   FROM jugadores_puntos_jornada jp
                   INNER JOIN jornadas jx ON jx.id = jp.id_jornada
                   WHERE jp.id_liga_jugador = lj.id AND jx.id_liga = lj.id_liga
                   ORDER BY jx.numero DESC, jp.id_jornada DESC
                   LIMIT 3
               ) t
           ), 0) AS media_pts_ult3,
           COALESCE((
               SELECT jp.puntos
               FROM jugadores_puntos_jornada jp
               INNER JOIN jornadas jx ON jx.id = jp.id_jornada
               WHERE jp.id_liga_jugador = lj.id AND jx.id_liga = lj.id_liga
               ORDER BY jx.numero DESC, jp.id_jornada DESC
               LIMIT 1
           ), 0) AS puntos_ultimo_partido,
           COALESCE((
               SELECT jp.minutos_jugados
               FROM jugadores_puntos_jornada jp
               INNER JOIN jornadas jx ON jx.id = jp.id_jornada
               WHERE jp.id_liga_jugador = lj.id AND jx.id_liga = lj.id_liga
               ORDER BY jx.numero DESC, jp.id_jornada DESC
               LIMIT 1
           ), 0) AS minutos_ultimo_partido,
           COALESCE((
               SELECT MAX(m.porcentaje)
               FROM liga_jugador_modificadores_valor m
               WHERE m.id_liga = lj.id_liga
                 AND m.id_liga_jugador = lj.id
                 AND m.activo = TRUE
           ), 0) AS pct_modificador_valor,
           FLOOR(lj.valor * (1 + COALESCE((
               SELECT MAX(m.porcentaje)
               FROM liga_jugador_modificadores_valor m
               WHERE m.id_liga = lj.id_liga AND m.id_liga_jugador = lj.id AND m.activo = TRUE
           ), 0))) AS valor_mercado_efectivo
    FROM liga_jugadores lj
    INNER JOIN jugadores j ON j.id = lj.id_jugador
    WHERE lj.id_liga = @id_liga
),
with_par AS (
    SELECT b.*,
           ROUND(
               CASE
                   WHEN b.valor_actual / 1000000.0 >= 120 THEN 10.2
                   WHEN b.valor_actual / 1000000.0 >= 100 THEN 8.35 + (b.valor_actual / 1e6 - 100) * (10.2 - 8.35) / 20
                   WHEN b.valor_actual / 1000000.0 >= 90  THEN 7.65 + (b.valor_actual / 1e6 - 90) * (8.35 - 7.65) / 10
                   WHEN b.valor_actual / 1000000.0 >= 70  THEN 7.35 + (b.valor_actual / 1e6 - 70) * (7.65 - 7.35) / 20
                   WHEN b.valor_actual / 1000000.0 >= 50  THEN 6.0 + (b.valor_actual / 1e6 - 50) * (7.35 - 6.0) / 20
                   WHEN b.valor_actual / 1000000.0 >= 10  THEN 5.35 + (b.valor_actual / 1e6 - 10) * (6.0 - 5.35) / 40
                   ELSE 3.55 + GREATEST(0, b.valor_actual / 1e6 - 0.5) * (5.35 - 3.55) / 9.5
               END, 2
           ) AS par_pts_aprox
    FROM base b
),
con_par AS (
    SELECT p.*,
           CASE
               WHEN p.media_pts_ult3 <= 0 OR p.par_pts_aprox IS NULL OR p.par_pts_aprox < 0.5 THEN NULL
               WHEN p.media_pts_ult3 / p.par_pts_aprox >= 1
               THEN ROUND(10 * POW(p.media_pts_ult3 / p.par_pts_aprox, 1.30), 2)
               ELSE ROUND(10 * POW(p.media_pts_ult3 / p.par_pts_aprox, 1.06), 2)
           END AS indice_rendimiento_aprox
    FROM with_par p
),
ultimo_detalle AS (
    SELECT jp.id_liga_jugador,
           jp.goles,
           jp.asistencias,
           jp.paradas,
           jp.porteria_cero,
           jp.tarjetas_rojas,
           jp.lesionado_en_partido,
           jp.balones_recuperados
    FROM jugadores_puntos_jornada jp
    INNER JOIN jornadas j ON j.id = jp.id_jornada AND j.id_liga = @id_liga
    INNER JOIN (
        SELECT id_liga_jugador, MAX(j.numero) AS max_num
        FROM jugadores_puntos_jornada jp2
        INNER JOIN jornadas j2 ON j2.id = jp2.id_jornada AND j2.id_liga = @id_liga
        GROUP BY id_liga_jugador
    ) t ON t.id_liga_jugador = jp.id_liga_jugador
    INNER JOIN jornadas jn ON jn.id = jp.id_jornada AND jn.numero = t.max_num
)
SELECT c.id_liga,
       c.id_liga_jugador,
       c.jugador,
       c.posicion,
       c.valor_anterior,
       c.valor_actual,
       c.delta_valor,
       c.valoracion_actual,
       c.media_pts_ult3,
       c.par_pts_aprox,
       c.indice_rendimiento_aprox,
       c.puntos_ultimo_partido,
       c.minutos_ultimo_partido,
       ud.goles,
       ud.asistencias,
       ud.paradas,
       ud.porteria_cero,
       ud.tarjetas_rojas,
       ud.lesionado_en_partido,
       ud.balones_recuperados,
       c.estado_liga,
       c.pct_modificador_valor,
       c.valor_mercado_efectivo,
       CASE
           WHEN c.delta_valor = 0 AND c.puntos_ultimo_partido >= 7 AND c.minutos_ultimo_partido >= 60
               THEN 'SIN_CAMBIO_TRAS_BUEN_PARTIDO (guardrail o moveTowards o media ya alta)'
           WHEN c.delta_valor = 0 AND c.puntos_ultimo_partido <= 3 AND c.minutos_ultimo_partido >= 45
               THEN 'SIN_CAMBIO_TRAS_MAL_PARTIDO (par bajo / media arrastra / cap subida)'
           WHEN c.delta_valor = 0 THEN 'SIN_CAMBIO_NEUTRO'
           WHEN c.delta_valor > 0 THEN 'SUBE'
           ELSE 'BAJA'
       END AS lectura_humana
FROM con_par c
LEFT JOIN ultimo_detalle ud ON ud.id_liga_jugador = c.id_liga_jugador
ORDER BY ABS(c.delta_valor) DESC, c.valor_actual DESC;

-- Casos A–F rápidos (misma @id_liga): ejecutar docs/informe-valor-mercado-ejemplos.sql
-- o filtrar el resultado anterior:
--   A: lectura_humana LIKE 'SUBE%' ORDER BY delta_valor DESC
--   B: delta_valor < 0 ORDER BY delta_valor
--   C: delta_valor = 0 AND puntos_ultimo_partido >= 7
--   D: delta_valor = 0 AND puntos_ultimo_partido <= 3
--   E: valor_actual >= 70e6 ORDER BY ABS(delta_valor) DESC
--   F: valor_actual <= 5e6 AND delta_valor > 0 ORDER BY delta_valor DESC
