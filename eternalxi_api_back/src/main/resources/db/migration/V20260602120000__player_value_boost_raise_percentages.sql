-- Sube porcentajes de cartas PLAYER_VALUE_BOOST (impulso de mercado permanente).

UPDATE definiciones_carta
SET descripcion = 'Elige un jugador de tu plantilla y sube su valor de mercado un 5% de forma permanente.',
    parametros_json = '{"percentage":0.05}'
WHERE codigo = 'VALUE_RECOVERY_SMALL';

UPDATE definiciones_carta
SET descripcion = 'Elige un jugador de tu plantilla y sube su valor de mercado un 8% de forma permanente.',
    parametros_json = '{"percentage":0.08}'
WHERE codigo = 'VALUE_RECOVERY_MEDIUM';

UPDATE definiciones_carta
SET descripcion = 'Elige un jugador de tu plantilla y sube su valor de mercado un 12% de forma permanente.',
    parametros_json = '{"percentage":0.12}'
WHERE codigo = 'VALUE_RECOVERY_SPECIAL';

UPDATE definiciones_carta
SET descripcion = 'Elige un jugador de tu plantilla y sube su valor de mercado un 15% de forma permanente.',
    parametros_json = '{"percentage":0.15}'
WHERE codigo = 'VALUE_RECOVERY_ELITE';

UPDATE definiciones_carta
SET descripcion = 'Elige un jugador de tu plantilla y sube su valor de mercado un 20% de forma permanente.',
    parametros_json = '{"percentage":0.20}'
WHERE codigo = 'VALUE_RECOVERY_LEGENDARY';
