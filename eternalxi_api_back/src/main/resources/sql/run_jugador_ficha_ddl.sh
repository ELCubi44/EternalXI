#!/bin/bash
set -e
DB=EternalXI
USER=userRoot
PASS='76767676miguelmM44gg44'

add_column_if_missing() {
  local col="$1"
  local ddl="$2"
  local cnt
  cnt=$(mysql -u "$USER" -p"$PASS" -N -e \
    "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='$DB' AND TABLE_NAME='jugadores' AND COLUMN_NAME='$col'")
  if [ "$cnt" -eq 0 ]; then
    mysql -u "$USER" -p"$PASS" "$DB" -e "$ddl"
    echo "Columna jugadores.$col creada"
  else
    echo "Columna jugadores.$col ya existe — omitido"
  fi
}

mysql -u "$USER" -p"$PASS" "$DB" -e "DROP TABLE IF EXISTS jugador_supertecnicas;"

add_column_if_missing pais "ALTER TABLE jugadores ADD COLUMN pais VARCHAR(64) NULL COMMENT 'País de origen' AFTER genero;"
add_column_if_missing altura "ALTER TABLE jugadores ADD COLUMN altura SMALLINT UNSIGNED NULL COMMENT 'Altura en cm' AFTER pais;"
add_column_if_missing estilo "ALTER TABLE jugadores ADD COLUMN estilo ENUM('PICARO', 'PRECISO', 'POTENTE') NULL COMMENT 'Estilo de juego' AFTER altura;"

mysql -u "$USER" -p"$PASS" "$DB" <<'SQL'
CREATE TABLE IF NOT EXISTS supertecnicas (
    id BIGINT NOT NULL AUTO_INCREMENT,
    nombre VARCHAR(128) NOT NULL,
    potencia TINYINT UNSIGNED NOT NULL,
    tipo ENUM('REGATE', 'DEFENSA', 'PARADA', 'TIRO') NOT NULL,
    estilo ENUM('PICARO', 'PRECISO', 'POTENTE') NOT NULL,
    creado_en TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id),
    UNIQUE KEY uk_supertecnica_def (nombre, potencia, tipo, estilo),
    KEY idx_supertecnicas_tipo (tipo)
);

CREATE TABLE IF NOT EXISTS jugador_supertecnica (
    id BIGINT NOT NULL AUTO_INCREMENT,
    id_jugador INT NOT NULL,
    id_supertecnica BIGINT NOT NULL,
    orden TINYINT UNSIGNED NOT NULL,
    creado_en TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id),
    UNIQUE KEY uk_jugador_supertecnica_orden (id_jugador, orden),
    UNIQUE KEY uk_jugador_supertecnica_par (id_jugador, id_supertecnica),
    KEY idx_jugador_supertecnica_supertecnica (id_supertecnica),
    CONSTRAINT fk_js_jugador FOREIGN KEY (id_jugador) REFERENCES jugadores (id) ON DELETE CASCADE,
    CONSTRAINT fk_js_supertecnica FOREIGN KEY (id_supertecnica) REFERENCES supertecnicas (id) ON DELETE RESTRICT
);
SQL

echo "OK — DDL ficha jugador aplicado"
mysql -u "$USER" -p"$PASS" "$DB" -e "DESCRIBE supertecnicas;"
mysql -u "$USER" -p"$PASS" "$DB" -e "DESCRIBE jugador_supertecnica;"
