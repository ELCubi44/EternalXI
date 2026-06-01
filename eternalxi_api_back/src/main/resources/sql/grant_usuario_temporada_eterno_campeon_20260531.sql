-- Acceso de todos los usuarios a la temporada Eterno Campeon (id 2).
USE EternalXI;

INSERT IGNORE INTO usuario_temporadas (id_usuario, id_temporada)
SELECT u.id, 2
FROM usuarios u;

SELECT COUNT(*) AS usuarios_con_acceso_ec
FROM usuario_temporadas
WHERE id_temporada = 2;
