-- Ajuste de parámetros, descripciones y nombres de definiciones_carta
-- SELL_PLAYER_BONUS: bajar multiplicadores
UPDATE definiciones_carta SET parametros_json = '{"sellMultiplier":1.0}',
       descripcion = 'Vende un jugador por el 100% de su valor.'
WHERE codigo = 'SELL_100';

UPDATE definiciones_carta SET parametros_json = '{"sellMultiplier":1.1}',
       descripcion = 'Vende un jugador por el 110% de su valor.'
WHERE codigo = 'SELL_120';

UPDATE definiciones_carta SET parametros_json = '{"sellMultiplier":1.2}',
       descripcion = 'Vende un jugador por el 120% de su valor.'
WHERE codigo = 'SELL_140';

UPDATE definiciones_carta SET parametros_json = '{"sellMultiplier":1.35}',
       descripcion = 'Vende un jugador por el 135% de su valor.'
WHERE codigo = 'SELL_160';

UPDATE definiciones_carta SET parametros_json = '{"sellMultiplier":1.5}',
       descripcion = 'Vende un jugador por el 150% de su valor.'
WHERE codigo = 'SELL_200';

-- DIRECT_CLAUSE: todo a 1.0, legendaria max 150M
UPDATE definiciones_carta SET parametros_json = '{"maxPlayerValue":5000000,"buyerMultiplier":1.0,"ownerCompensationMultiplier":1.0}',
       descripcion = 'Ficha directamente un jugador rival de hasta 5M pagando el 100% de su valor.'
WHERE codigo = 'CLAUSE_5M';

UPDATE definiciones_carta SET parametros_json = '{"maxPlayerValue":10000000,"buyerMultiplier":1.0,"ownerCompensationMultiplier":1.0}',
       descripcion = 'Ficha directamente un jugador rival de hasta 10M pagando el 100% de su valor.'
WHERE codigo = 'CLAUSE_10M';

UPDATE definiciones_carta SET parametros_json = '{"maxPlayerValue":20000000,"buyerMultiplier":1.0,"ownerCompensationMultiplier":1.0}',
       descripcion = 'Ficha directamente un jugador rival de hasta 20M pagando el 100% de su valor.'
WHERE codigo = 'CLAUSE_20M';

UPDATE definiciones_carta SET parametros_json = '{"maxPlayerValue":35000000,"buyerMultiplier":1.0,"ownerCompensationMultiplier":1.0}',
       descripcion = 'Ficha directamente un jugador rival de hasta 35M pagando el 100% de su valor.'
WHERE codigo = 'CLAUSE_35M';

UPDATE definiciones_carta SET parametros_json = '{"maxPlayerValue":150000000,"buyerMultiplier":1.0,"ownerCompensationMultiplier":1.0}',
       descripcion = 'Ficha directamente cualquier jugador rival de hasta 150M pagando el 100% de su valor.'
WHERE codigo = 'CLAUSE_ANY';

-- PROTECT_PLAYER: SUPER_RARE de 8 a 6 jornadas
UPDATE definiciones_carta SET parametros_json = '{"rounds":6,"seasonLong":false}',
       descripcion = 'Protege un jugador durante 6 jornadas.'
WHERE codigo = 'PROTECT_8_ROUNDS';

-- ADD_LEAGUE_POINTS: bajar SUPER_RARE y LEGENDARY
UPDATE definiciones_carta SET parametros_json = '{"points":25}',
       descripcion = 'Suma 25 puntos al total de la liga.'
WHERE codigo = 'LEAGUE_POINTS_35';

UPDATE definiciones_carta SET parametros_json = '{"points":30}',
       descripcion = 'Suma 30 puntos al total de la liga.'
WHERE codigo = 'LEAGUE_POINTS_60';

-- TEMPORARY_VALUE_RECOVERY: bajar porcentajes
UPDATE definiciones_carta SET parametros_json = '{"percentage":0.01}',
       descripcion = 'Aumenta temporalmente un 1% el valor de un jugador propio que esté bajando.'
WHERE codigo = 'VALUE_RECOVERY_SMALL';

UPDATE definiciones_carta SET parametros_json = '{"percentage":0.02}',
       descripcion = 'Aumenta temporalmente un 2% el valor de un jugador propio que esté bajando.'
WHERE codigo = 'VALUE_RECOVERY_MEDIUM';

UPDATE definiciones_carta SET parametros_json = '{"percentage":0.03}',
       descripcion = 'Aumenta temporalmente un 3% el valor de un jugador propio que esté bajando.'
WHERE codigo = 'VALUE_RECOVERY_SPECIAL';

UPDATE definiciones_carta SET parametros_json = '{"percentage":0.05}',
       descripcion = 'Aumenta temporalmente un 5% el valor de un jugador propio que esté bajando.'
WHERE codigo = 'VALUE_RECOVERY_ELITE';

UPDATE definiciones_carta SET parametros_json = '{"percentage":0.07}',
       descripcion = 'Aumenta temporalmente un 7% el valor de un jugador propio que esté bajando.'
WHERE codigo = 'VALUE_RECOVERY_LEGENDARY';
