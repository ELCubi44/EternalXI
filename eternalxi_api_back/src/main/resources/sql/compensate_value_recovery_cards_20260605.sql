-- Manual (producción): mismo contenido que V20260605120000__compensate_value_recovery_cards.sql
-- Ejecutar DESPUÉS de V20260601180000 y V20260602120000.

INSERT INTO liga_participante_cartas (id_liga_participante, id_definicion_carta, estado, metadata_json)
SELECT DISTINCT
    m.id_liga_participante,
    lpc.id_definicion_carta,
    'AVAILABLE',
    CONCAT(
        '{"grantedReason":"VALUE_BOOST_MIGRATION_COMPENSATION","sourceModifierId":',
        m.id,
        ',"replaces":"TEMPORARY_VALUE_RECOVERY"}'
    )
FROM liga_jugador_modificadores_valor m
INNER JOIN liga_participante_cartas lpc ON lpc.id = m.id_carta_origen
INNER JOIN definiciones_carta dc ON dc.id = lpc.id_definicion_carta
WHERE m.tipo = 'TEMPORARY_VALUE_RECOVERY'
  AND m.activo = FALSE
  AND m.id_carta_origen IS NOT NULL
  AND dc.codigo IN (
      'VALUE_RECOVERY_SMALL',
      'VALUE_RECOVERY_MEDIUM',
      'VALUE_RECOVERY_SPECIAL',
      'VALUE_RECOVERY_ELITE',
      'VALUE_RECOVERY_LEGENDARY'
  )
  AND (
      m.id_jornada_expiracion IS NULL
      OR EXISTS (
          SELECT 1
          FROM jornadas j
          WHERE j.id = m.id_jornada_expiracion
            AND j.estado <> 'FINALIZADA'
      )
  )
  AND NOT EXISTS (
      SELECT 1
      FROM liga_participante_cartas g
      WHERE g.metadata_json LIKE CONCAT('%"sourceModifierId":', m.id, '%')
  );
