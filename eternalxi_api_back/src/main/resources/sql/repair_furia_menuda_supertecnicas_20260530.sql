-- Reparación: enlaces jugador_supertecnica para Furia Menuda
-- Causa: el script original usó id_supertecnica / id_jugador en SELECT sobre tablas base (PK = id)
-- Ejecutar en MySQL 8, BD EternalXI

USE EternalXI;

-- === Daichi Enomoto ===
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 1 FROM jugadores j
JOIN equipos e ON e.id = j.id_equipo
JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'campana_temeraria' AND st.potencia = 80 AND st.tipo = 'PARADA' AND st.estilo = 'VALIENTE'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Daichi Enomoto';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 2 FROM jugadores j
JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'palmada_relampago' AND st.potencia = 55 AND st.tipo = 'PARADA' AND st.estilo = 'AGIL'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Daichi Enomoto';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 3 FROM jugadores j
JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'garfio_del_recreo' AND st.potencia = 40 AND st.tipo = 'PARADA' AND st.estilo = 'PICARO'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Daichi Enomoto';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 4 FROM jugadores j
JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'traba_del_patio' AND st.potencia = 45 AND st.tipo = 'DEFENSA' AND st.estilo = 'PICARO'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Daichi Enomoto';

-- === Haruto Shimizu ===
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 1 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'sello_de_papel' AND st.potencia = 60 AND st.tipo = 'PARADA' AND st.estilo = 'PRECISO'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Haruto Shimizu';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 2 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'caida_de_bambu' AND st.potencia = 45 AND st.tipo = 'PARADA' AND st.estilo = 'PRECISO'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Haruto Shimizu';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 3 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'garfio_del_recreo' AND st.potencia = 40 AND st.tipo = 'PARADA' AND st.estilo = 'PICARO'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Haruto Shimizu';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 4 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'abrazo_del_tatami' AND st.potencia = 25 AND st.tipo = 'PARADA' AND st.estilo = 'VALIENTE'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Haruto Shimizu';

-- === Kazuki Arata ===
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 1 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'cerrojo_inquieto' AND st.potencia = 70 AND st.tipo = 'DEFENSA' AND st.estilo = 'PICARO'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Kazuki Arata';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 2 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'pared_de_tiza' AND st.potencia = 35 AND st.tipo = 'DEFENSA' AND st.estilo = 'POTENTE'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Kazuki Arata';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 3 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'curva_traviesa' AND st.potencia = 50 AND st.tipo = 'REGATE' AND st.estilo = 'PICARO'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Kazuki Arata';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 4 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'rastro_de_chispa' AND st.potencia = 30 AND st.tipo = 'REGATE' AND st.estilo = 'AGIL'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Kazuki Arata';

-- === Souta Hoshikawa ===
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 1 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'bisagra_firme' AND st.potencia = 70 AND st.tipo = 'DEFENSA' AND st.estilo = 'PRECISO'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Souta Hoshikawa';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 2 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'placa_menuda' AND st.potencia = 50 AND st.tipo = 'DEFENSA' AND st.estilo = 'POTENTE'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Souta Hoshikawa';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 3 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'pared_de_tiza' AND st.potencia = 35 AND st.tipo = 'DEFENSA' AND st.estilo = 'POTENTE'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Souta Hoshikawa';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 4 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'rastro_de_chispa' AND st.potencia = 30 AND st.tipo = 'REGATE' AND st.estilo = 'AGIL'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Souta Hoshikawa';

-- === Kenta Morisaki ===
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 1 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'pared_de_tiza' AND st.potencia = 35 AND st.tipo = 'DEFENSA' AND st.estilo = 'POTENTE'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Kenta Morisaki';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 2 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'tropiezo_de_mochila' AND st.potencia = 20 AND st.tipo = 'DEFENSA' AND st.estilo = 'PICARO'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Kenta Morisaki';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 3 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'abrazo_del_tatami' AND st.potencia = 25 AND st.tipo = 'PARADA' AND st.estilo = 'VALIENTE'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Kenta Morisaki';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 4 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'bolsa_de_aire' AND st.potencia = 15 AND st.tipo = 'PARADA' AND st.estilo = 'AGIL'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Kenta Morisaki';

-- === Taiga Domon ===
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 1 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'tope_de_cantera' AND st.potencia = 60 AND st.tipo = 'DEFENSA' AND st.estilo = 'POTENTE'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Taiga Domon';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 2 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'codo_de_recreo' AND st.potencia = 45 AND st.tipo = 'DEFENSA' AND st.estilo = 'POTENTE'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Taiga Domon';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 3 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'pared_de_tiza' AND st.potencia = 35 AND st.tipo = 'DEFENSA' AND st.estilo = 'POTENTE'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Taiga Domon';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 4 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'tropiezo_de_mochila' AND st.potencia = 20 AND st.tipo = 'DEFENSA' AND st.estilo = 'PICARO'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Taiga Domon';

-- === Yuto Nakahara ===
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 1 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'escudo_saltarin' AND st.potencia = 70 AND st.tipo = 'DEFENSA' AND st.estilo = 'VALIENTE'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Yuto Nakahara';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 2 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'pared_de_tiza' AND st.potencia = 35 AND st.tipo = 'DEFENSA' AND st.estilo = 'POTENTE'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Yuto Nakahara';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 3 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'brinco_de_tambor' AND st.potencia = 55 AND st.tipo = 'REGATE' AND st.estilo = 'AGIL'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Yuto Nakahara';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 4 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'rastro_de_chispa' AND st.potencia = 30 AND st.tipo = 'REGATE' AND st.estilo = 'AGIL'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Yuto Nakahara';

-- === Ren Akabane ===
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 1 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'nudo_de_pizarra' AND st.potencia = 50 AND st.tipo = 'DEFENSA' AND st.estilo = 'PRECISO'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Ren Akabane';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 2 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'pared_de_tiza' AND st.potencia = 35 AND st.tipo = 'DEFENSA' AND st.estilo = 'POTENTE'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Ren Akabane';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 3 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'silbido_corto' AND st.potencia = 45 AND st.tipo = 'TIRO' AND st.estilo = 'PRECISO'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Ren Akabane';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 4 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'chut_de_bolsillo' AND st.potencia = 25 AND st.tipo = 'TIRO' AND st.estilo = 'PICARO'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Ren Akabane';

-- === Raito Kirishima ===
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 1 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'chispa_de_guardia' AND st.potencia = 70 AND st.tipo = 'DEFENSA' AND st.estilo = 'VALIENTE'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Raito Kirishima';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 2 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'pared_de_tiza' AND st.potencia = 35 AND st.tipo = 'DEFENSA' AND st.estilo = 'POTENTE'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Raito Kirishima';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 3 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'rastro_de_chispa' AND st.potencia = 30 AND st.tipo = 'REGATE' AND st.estilo = 'AGIL'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Raito Kirishima';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 4 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'chut_de_bolsillo' AND st.potencia = 25 AND st.tipo = 'TIRO' AND st.estilo = 'PICARO'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Raito Kirishima';

-- === Goro Matsunaga ===
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 1 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'cierre_de_campana' AND st.potencia = 60 AND st.tipo = 'DEFENSA' AND st.estilo = 'PRECISO'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Goro Matsunaga';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 2 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'barrera_de_mochi' AND st.potencia = 45 AND st.tipo = 'DEFENSA' AND st.estilo = 'POTENTE'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Goro Matsunaga';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 3 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'pared_de_tiza' AND st.potencia = 35 AND st.tipo = 'DEFENSA' AND st.estilo = 'POTENTE'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Goro Matsunaga';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 4 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'tropiezo_de_mochila' AND st.potencia = 20 AND st.tipo = 'DEFENSA' AND st.estilo = 'PICARO'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Goro Matsunaga';

-- === Itsuki Amamiya ===
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 1 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'bisel_sereno' AND st.potencia = 65 AND st.tipo = 'DEFENSA' AND st.estilo = 'PRECISO'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Itsuki Amamiya';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 2 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'pared_de_tiza' AND st.potencia = 35 AND st.tipo = 'DEFENSA' AND st.estilo = 'POTENTE'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Itsuki Amamiya';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 3 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'vuelta_de_cromo' AND st.potencia = 55 AND st.tipo = 'REGATE' AND st.estilo = 'AGIL'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Itsuki Amamiya';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 4 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'rastro_de_chispa' AND st.potencia = 30 AND st.tipo = 'REGATE' AND st.estilo = 'AGIL'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Itsuki Amamiya';

-- === Akito Shinose ===
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 1 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'eslalon_carmesi' AND st.potencia = 65 AND st.tipo = 'REGATE' AND st.estilo = 'AGIL'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Akito Shinose';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 2 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'rastro_de_chispa' AND st.potencia = 30 AND st.tipo = 'REGATE' AND st.estilo = 'AGIL'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Akito Shinose';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 3 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'cohete_de_merienda' AND st.potencia = 60 AND st.tipo = 'TIRO' AND st.estilo = 'POTENTE'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Akito Shinose';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 4 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'chut_de_bolsillo' AND st.potencia = 25 AND st.tipo = 'TIRO' AND st.estilo = 'PICARO'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Akito Shinose';

-- === Hayato Kurogane ===
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 1 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'nudo_de_pizarra' AND st.potencia = 50 AND st.tipo = 'DEFENSA' AND st.estilo = 'PRECISO'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Hayato Kurogane';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 2 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'pared_de_tiza' AND st.potencia = 35 AND st.tipo = 'DEFENSA' AND st.estilo = 'POTENTE'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Hayato Kurogane';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 3 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'silbido_corto' AND st.potencia = 45 AND st.tipo = 'TIRO' AND st.estilo = 'PRECISO'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Hayato Kurogane';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 4 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'chut_de_bolsillo' AND st.potencia = 25 AND st.tipo = 'TIRO' AND st.estilo = 'PICARO'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Hayato Kurogane';

-- === Shunpei Asakura ===
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 1 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'chicle_electrico' AND st.potencia = 60 AND st.tipo = 'REGATE' AND st.estilo = 'PICARO'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Shunpei Asakura';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 2 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'rastro_de_chispa' AND st.potencia = 30 AND st.tipo = 'REGATE' AND st.estilo = 'AGIL'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Shunpei Asakura';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 3 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'mordisco_del_poste' AND st.potencia = 55 AND st.tipo = 'TIRO' AND st.estilo = 'POTENTE'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Shunpei Asakura';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 4 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'chut_de_bolsillo' AND st.potencia = 25 AND st.tipo = 'TIRO' AND st.estilo = 'PICARO'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Shunpei Asakura';

-- === Naoya Kazehara ===
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 1 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'doble_guino' AND st.potencia = 80 AND st.tipo = 'REGATE' AND st.estilo = 'PICARO'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Naoya Kazehara';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 2 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'silueta_falsa' AND st.potencia = 50 AND st.tipo = 'REGATE' AND st.estilo = 'PICARO'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Naoya Kazehara';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 3 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'rastro_de_chispa' AND st.potencia = 30 AND st.tipo = 'REGATE' AND st.estilo = 'AGIL'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Naoya Kazehara';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 4 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'flechazo_breve' AND st.potencia = 60 AND st.tipo = 'TIRO' AND st.estilo = 'PRECISO'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Naoya Kazehara';

-- === Kaito Igarashi ===
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 1 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'peonza_de_feria' AND st.potencia = 65 AND st.tipo = 'REGATE' AND st.estilo = 'AGIL'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Kaito Igarashi';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 2 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'rastro_de_chispa' AND st.potencia = 30 AND st.tipo = 'REGATE' AND st.estilo = 'AGIL'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Kaito Igarashi';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 3 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'meteorito_burlon' AND st.potencia = 60 AND st.tipo = 'TIRO' AND st.estilo = 'POTENTE'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Kaito Igarashi';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 4 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'chut_de_bolsillo' AND st.potencia = 25 AND st.tipo = 'TIRO' AND st.estilo = 'PICARO'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Kaito Igarashi';

-- === Ryusei Hino ===
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 1 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'vuelta_del_yo_yo' AND st.potencia = 55 AND st.tipo = 'REGATE' AND st.estilo = 'AGIL'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Ryusei Hino';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 2 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'pared_de_tiza' AND st.potencia = 35 AND st.tipo = 'DEFENSA' AND st.estilo = 'POTENTE'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Ryusei Hino';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 3 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'centella_roja' AND st.potencia = 70 AND st.tipo = 'TIRO' AND st.estilo = 'POTENTE'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Ryusei Hino';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 4 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'chut_de_bolsillo' AND st.potencia = 25 AND st.tipo = 'TIRO' AND st.estilo = 'PICARO'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Ryusei Hino';

-- === Daigo Amakura ===
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 1 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'tambor_solar' AND st.potencia = 70 AND st.tipo = 'TIRO' AND st.estilo = 'VALIENTE'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Daigo Amakura';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 2 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'colmillo_de_naranja' AND st.potencia = 50 AND st.tipo = 'TIRO' AND st.estilo = 'POTENTE'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Daigo Amakura';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 3 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'chut_de_bolsillo' AND st.potencia = 25 AND st.tipo = 'TIRO' AND st.estilo = 'PICARO'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Daigo Amakura';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 4 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'rastro_de_chispa' AND st.potencia = 30 AND st.tipo = 'REGATE' AND st.estilo = 'AGIL'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Daigo Amakura';

-- === Kei Suganuma ===
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 1 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'aguijon_quieto' AND st.potencia = 60 AND st.tipo = 'TIRO' AND st.estilo = 'PRECISO'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Kei Suganuma';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 2 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'remate_de_origami' AND st.potencia = 45 AND st.tipo = 'TIRO' AND st.estilo = 'PRECISO'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Kei Suganuma';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 3 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'chut_de_bolsillo' AND st.potencia = 25 AND st.tipo = 'TIRO' AND st.estilo = 'PICARO'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Kei Suganuma';
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 4 FROM jugadores j JOIN equipos e ON e.id = j.id_equipo JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'rastro_de_chispa' AND st.potencia = 30 AND st.tipo = 'REGATE' AND st.estilo = 'AGIL'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Kei Suganuma';

-- Verificación
SELECT j.nombre, COUNT(js.id) AS num_st
FROM jugadores j
JOIN equipos e ON e.id = j.id_equipo
JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
LEFT JOIN jugador_supertecnica js ON js.id_jugador = j.id
WHERE et.nombre = 'Furia Menuda'
GROUP BY j.id, j.nombre
HAVING COUNT(js.id) <> 4;

SELECT COUNT(*) AS total_enlaces
FROM jugador_supertecnica js
JOIN jugadores j ON j.id = js.id_jugador
JOIN equipos e ON e.id = j.id_equipo
JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
WHERE et.nombre = 'Furia Menuda';
