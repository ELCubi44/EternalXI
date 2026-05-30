SELECT TABLE_NAME, COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, COLUMN_KEY
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'EternalXI'
  AND TABLE_NAME IN ('temporadas', 'equipos', 'jugadores', 'supertecnicas', 'jugador_supertecnica')
ORDER BY TABLE_NAME, ORDINAL_POSITION;
