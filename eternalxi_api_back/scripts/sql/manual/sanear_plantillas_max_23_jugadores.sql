-- ============================================================
-- Sanear plantillas con más de 23 jugadores (límite máximo)
-- Vende los jugadores más baratos hasta quedar en 23 por usuario/liga.
-- El jugador se transfiere al usuario mercado (id=1) con valor actual.
-- El usuario recupera el dinero del valor del jugador vendido.
--
-- INSTRUCCIONES:
--   1. Ejecutar primero el bloque de DIAGNÓSTICO para ver afectados.
--   2. Revisar la tabla temporal #excedentes.
--   3. Si todo ok, ejecutar el bloque de CORRECCIÓN dentro de transacción.
--   4. Confirmar con SELECT final.
-- ============================================================

-- ========================
-- BLOQUE 1: DIAGNÓSTICO
-- ========================

-- Usuarios con más de 23 jugadores por liga
SELECT
    lj.id_liga,
    l.nombre              AS liga,
    lj.id_usuario_dueno   AS id_usuario,
    u.nombre              AS usuario,
    COUNT(*)              AS total_jugadores,
    COUNT(*) - 23         AS jugadores_excedentes
FROM liga_jugadores lj
INNER JOIN ligas l      ON l.id = lj.id_liga
INNER JOIN usuarios u   ON u.id = lj.id_usuario_dueno
WHERE lj.id_usuario_dueno <> 1   -- excluir usuario mercado
GROUP BY lj.id_liga, lj.id_usuario_dueno
HAVING COUNT(*) > 23
ORDER BY liga, usuario;

-- ========================
-- BLOQUE 2: CORRECCIÓN
-- ========================
-- Ajusta el número de repeticiones al máximo de excedentes que haya.
-- Cada iteración vende un jugador (el más barato) por usuario/liga afectado.
-- Ejecutar dentro de una transacción y hacer COMMIT solo si todo es correcto.

START TRANSACTION;

-- Paso A: identificar los jugadores a vender (más baratos, excluyendo los 23 mejores)
-- Se crea una vista temporal con los candidatos a venta
CREATE TEMPORARY TABLE IF NOT EXISTS tmp_venta_excedentes AS
SELECT
    sub.id         AS id_liga_jugador,
    sub.id_liga,
    sub.id_usuario_dueno,
    sub.valor
FROM (
    SELECT
        lj.id,
        lj.id_liga,
        lj.id_usuario_dueno,
        lj.valor,
        ROW_NUMBER() OVER (
            PARTITION BY lj.id_liga, lj.id_usuario_dueno
            ORDER BY lj.valor ASC, lj.id ASC   -- más baratos primero; desempate por id
        ) AS rn,
        COUNT(*) OVER (
            PARTITION BY lj.id_liga, lj.id_usuario_dueno
        ) AS total
    FROM liga_jugadores lj
    WHERE lj.id_usuario_dueno <> 1
) sub
WHERE sub.total > 23
  AND sub.rn <= (sub.total - 23)   -- solo los excedentes más baratos
ORDER BY id_liga, id_usuario_dueno, valor ASC;

-- Vista previa de lo que se va a vender
SELECT
    tv.id_liga,
    l.nombre     AS liga,
    tv.id_usuario_dueno,
    u.nombre     AS usuario,
    tv.id_liga_jugador,
    COALESCE(NULLIF(j.pila, ''), j.nombre) AS jugador,
    j.demarcacion,
    tv.valor
FROM tmp_venta_excedentes tv
INNER JOIN liga_jugadores lj ON lj.id = tv.id_liga_jugador
INNER JOIN jugadores j       ON j.id  = lj.id_jugador
INNER JOIN ligas l           ON l.id  = tv.id_liga
INNER JOIN usuarios u        ON u.id  = tv.id_usuario_dueno
ORDER BY l.nombre, u.nombre, tv.valor ASC;

-- Paso B: transferir los jugadores al usuario mercado (id=1)
UPDATE liga_jugadores lj
INNER JOIN tmp_venta_excedentes tv ON tv.id_liga_jugador = lj.id
SET lj.id_usuario_dueno = 1;

-- Paso C: devolver el dinero a cada usuario (valor del jugador vendido)
UPDATE liga_participantes lp
INNER JOIN (
    SELECT id_liga, id_usuario_dueno, SUM(valor) AS total_reembolso
    FROM tmp_venta_excedentes
    GROUP BY id_liga, id_usuario_dueno
) reembolso ON reembolso.id_liga = lp.id_liga
           AND reembolso.id_usuario_dueno = lp.id_usuario
SET lp.dinero = lp.dinero + reembolso.total_reembolso;

-- Paso D: quitar de alineaciones los jugadores vendidos (si estaban titulares/suplentes)
UPDATE liga_alineacion_jugadores laj
INNER JOIN tmp_venta_excedentes tv ON tv.id_liga_jugador = laj.id_liga_jugador
SET laj.activo = 0;

-- Limpieza tabla temporal
DROP TEMPORARY TABLE IF EXISTS tmp_venta_excedentes;

-- ========================
-- BLOQUE 3: VERIFICACIÓN FINAL
-- ========================
-- Ejecutar ANTES de COMMIT para confirmar que no quedan afectados

SELECT
    lj.id_liga,
    lj.id_usuario_dueno,
    COUNT(*) AS total_jugadores
FROM liga_jugadores lj
WHERE lj.id_usuario_dueno <> 1
GROUP BY lj.id_liga, lj.id_usuario_dueno
HAVING COUNT(*) > 23;
-- Si devuelve 0 filas → todo correcto → COMMIT

-- COMMIT;   -- <-- Descomentar cuando se haya revisado la verificación
-- ROLLBACK; -- <-- Descomentar para cancelar si algo falla
