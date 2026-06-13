-- Balance: subida de valor de cartas PLAYER_VALUE_BOOST (+2–5 pp) y tope cláusula legendaria.

UPDATE definiciones_carta
SET descripcion = 'Elige un jugador de tu plantilla y sube su valor de mercado un 7% de forma permanente.',
    parametros_json = '{"percentage":0.07}'
WHERE codigo = 'VALUE_RECOVERY_SMALL';

UPDATE definiciones_carta
SET descripcion = 'Elige un jugador de tu plantilla y sube su valor de mercado un 10% de forma permanente.',
    parametros_json = '{"percentage":0.10}'
WHERE codigo = 'VALUE_RECOVERY_MEDIUM';

UPDATE definiciones_carta
SET descripcion = 'Elige un jugador de tu plantilla y sube su valor de mercado un 15% de forma permanente.',
    parametros_json = '{"percentage":0.15}'
WHERE codigo = 'VALUE_RECOVERY_SPECIAL';

UPDATE definiciones_carta
SET descripcion = 'Elige un jugador de tu plantilla y sube su valor de mercado un 18% de forma permanente.',
    parametros_json = '{"percentage":0.18}'
WHERE codigo = 'VALUE_RECOVERY_ELITE';

UPDATE definiciones_carta
SET descripcion = 'Elige un jugador de tu plantilla y sube su valor de mercado un 25% de forma permanente.',
    parametros_json = '{"percentage":0.25}'
WHERE codigo = 'VALUE_RECOVERY_LEGENDARY';

UPDATE definiciones_carta
SET parametros_json = '{"maxPlayerValue":50000000,"buyerMultiplier":1.0,"ownerCompensationMultiplier":1.0}',
    descripcion = 'Ficha directamente un jugador rival de hasta 50M pagando el 100% de su valor.'
WHERE codigo = 'CLAUSE_ANY';
