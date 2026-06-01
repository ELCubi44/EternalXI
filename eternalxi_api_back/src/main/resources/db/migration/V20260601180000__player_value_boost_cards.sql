-- Cartas de subida permanente de valor de mercado (sustituyen recuperación temporal).

UPDATE definiciones_carta
SET tipo_efecto = 'PLAYER_VALUE_BOOST',
    nombre = 'Impulso de mercado I',
    descripcion = 'Elige un jugador de tu plantilla y sube su valor de mercado un 5% de forma permanente.',
    parametros_json = '{"percentage":0.05}'
WHERE codigo = 'VALUE_RECOVERY_SMALL';

UPDATE definiciones_carta
SET tipo_efecto = 'PLAYER_VALUE_BOOST',
    nombre = 'Impulso de mercado II',
    descripcion = 'Elige un jugador de tu plantilla y sube su valor de mercado un 8% de forma permanente.',
    parametros_json = '{"percentage":0.08}'
WHERE codigo = 'VALUE_RECOVERY_MEDIUM';

UPDATE definiciones_carta
SET tipo_efecto = 'PLAYER_VALUE_BOOST',
    nombre = 'Impulso de mercado III',
    descripcion = 'Elige un jugador de tu plantilla y sube su valor de mercado un 12% de forma permanente.',
    parametros_json = '{"percentage":0.12}'
WHERE codigo = 'VALUE_RECOVERY_SPECIAL';

UPDATE definiciones_carta
SET tipo_efecto = 'PLAYER_VALUE_BOOST',
    nombre = 'Impulso de mercado IV',
    descripcion = 'Elige un jugador de tu plantilla y sube su valor de mercado un 15% de forma permanente.',
    parametros_json = '{"percentage":0.15}'
WHERE codigo = 'VALUE_RECOVERY_ELITE';

UPDATE definiciones_carta
SET tipo_efecto = 'PLAYER_VALUE_BOOST',
    nombre = 'Impulso de mercado V',
    descripcion = 'Elige un jugador de tu plantilla y sube su valor de mercado un 20% de forma permanente.',
    parametros_json = '{"percentage":0.20}'
WHERE codigo = 'VALUE_RECOVERY_LEGENDARY';

-- Desactivar modificadores temporales heredados (el efecto ya no es temporal).
UPDATE liga_jugador_modificadores_valor
SET activo = FALSE
WHERE activo = TRUE
  AND tipo = 'TEMPORARY_VALUE_RECOVERY';
