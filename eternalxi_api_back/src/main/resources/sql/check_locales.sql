SELECT 'temporada' AS tabla, locale, COUNT(*) AS filas FROM temporada_traduccion GROUP BY locale
UNION ALL
SELECT 'equipo', locale, COUNT(*) FROM equipo_traduccion GROUP BY locale
UNION ALL
SELECT 'jugador', locale, COUNT(*) FROM jugador_traduccion GROUP BY locale
UNION ALL
SELECT 'supertecnica', locale, COUNT(*) FROM supertecnica_traduccion GROUP BY locale;
