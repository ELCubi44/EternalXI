-- Límites de cláusula por rareza: 10M / 20M / 40M / 80M / sin tope (legendaria).

UPDATE definiciones_carta
SET parametros_json = '{"maxPlayerValue":10000000,"buyerMultiplier":1.0,"ownerCompensationMultiplier":1.0}',
    descripcion = 'Ficha directamente un jugador rival de hasta 10M pagando el 100% de su valor.'
WHERE codigo = 'CLAUSE_5M';

UPDATE definiciones_carta
SET parametros_json = '{"maxPlayerValue":20000000,"buyerMultiplier":1.0,"ownerCompensationMultiplier":1.0}',
    descripcion = 'Ficha directamente un jugador rival de hasta 20M pagando el 100% de su valor.'
WHERE codigo = 'CLAUSE_10M';

UPDATE definiciones_carta
SET parametros_json = '{"maxPlayerValue":40000000,"buyerMultiplier":1.0,"ownerCompensationMultiplier":1.0}',
    descripcion = 'Ficha directamente un jugador rival de hasta 40M pagando el 100% de su valor.'
WHERE codigo = 'CLAUSE_20M';

UPDATE definiciones_carta
SET parametros_json = '{"maxPlayerValue":80000000,"buyerMultiplier":1.0,"ownerCompensationMultiplier":1.0}',
    descripcion = 'Ficha directamente un jugador rival de hasta 80M pagando el 100% de su valor.'
WHERE codigo = 'CLAUSE_35M';

UPDATE definiciones_carta
SET parametros_json = '{"maxPlayerValue":null,"buyerMultiplier":1.0,"ownerCompensationMultiplier":1.0}',
    descripcion = 'Ficha directamente cualquier jugador rival pagando el 100% de su valor.'
WHERE codigo = 'CLAUSE_ANY';
