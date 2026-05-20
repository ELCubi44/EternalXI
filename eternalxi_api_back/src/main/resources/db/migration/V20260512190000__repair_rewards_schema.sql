-- Reparación remota INT / sin Flyway: usar SQL manual versionado en el repo:
--   src/main/resources/sql/manual_repair_rewards_EternalXI_20260512.sql (con FK)
--   src/main/resources/sql/manual_repair_rewards_EternalXI_20260512_NO_FK.sql (sin FK)
-- Esta versión Flyway queda como no-op para no duplicar DDL en entornos ya alineados con V20260512180000.
SELECT 1;
