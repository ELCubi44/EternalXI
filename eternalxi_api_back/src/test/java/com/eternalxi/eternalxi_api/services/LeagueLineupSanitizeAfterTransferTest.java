package com.eternalxi.eternalxi_api.services;

import org.junit.jupiter.api.Test;

import java.lang.reflect.Constructor;
import java.lang.reflect.Method;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;
import java.util.Objects;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

/**
 * Pruebas de saneado de alineación tras perder un jugador (cláusula, venta, etc.).
 */
class LeagueLineupSanitizeAfterTransferTest {

    @Test
    void snapshotContainsDetectsTitularReservaAndCapitan() throws Exception {
        LeagueLineupService service = new LeagueLineupService();

        Object inXi = snapshot(
                List.of(entry(10L, "POR", 1L)),
                List.of(entry(20L, "DEF", 2L)),
                30L
        );
        assertTrue(invokeSnapshotContains(service, inXi, 10L));
        assertTrue(invokeSnapshotContains(service, inXi, 20L));
        assertTrue(invokeSnapshotContains(service, inXi, 30L));
        assertFalse(invokeSnapshotContains(service, inXi, 99L));
    }

    @Test
    void integrationRemovePlayerFromOpenSavedLineupsOnLigaTest() throws Exception {
        assumeTrue(
                Boolean.getBoolean("eternalxi.integration.db"),
                "Activa con -Deternalxi.integration.db=true y MySQL EternalXI accesible"
        );

        try (Connection conn = DriverManager.getConnection(
                System.getProperty("eternalxi.jdbc.url", "jdbc:mysql://127.0.0.1:3306/EternalXI"),
                System.getProperty("eternalxi.jdbc.user", "userRoot"),
                System.getProperty("eternalxi.jdbc.password", "76767676miguelmM44gg44")
        )) {
            Scenario scenario = findOpenLineupScenario(conn, 7L);
            assumeTrue(scenario != null, "No hay jugador en alineación abierta en liga 7");

            long idLj = scenario.idLigaJugador();
            long sellerId = scenario.sellerUserId();
            long buyerId = scenario.buyerUserId();
            long idJornada = scenario.idJornada();
            long idLp = scenario.sellerParticipantId();

            assertTrue(lineupContainsPlayer(conn, idLp, idJornada, idLj));

            conn.setAutoCommit(false);
            try {
                transferOwnership(conn, idLj, sellerId, buyerId);

                LeagueLineupService lineupService = new LeagueLineupService();
                lineupService.removePlayerFromOpenSavedLineups(conn, 7L, sellerId, idLj);

                assertFalse(
                        lineupContainsPlayer(conn, idLp, idJornada, idLj),
                        "El jugador transferido no debe seguir en la alineación guardada abierta"
                );
            } finally {
                conn.rollback();
                conn.setAutoCommit(true);
            }
        }
    }

    @Test
    void integrationClauseTransactionRemovesPlayerFromOpenLineup() throws Exception {
        assumeTrue(Boolean.getBoolean("eternalxi.integration.db"));

        try (Connection conn = DriverManager.getConnection(
                System.getProperty("eternalxi.jdbc.url", "jdbc:mysql://127.0.0.1:3306/EternalXI"),
                System.getProperty("eternalxi.jdbc.user", "userRoot"),
                System.getProperty("eternalxi.jdbc.password", "76767676miguelmM44gg44")
        )) {
            Scenario scenario = findOpenLineupScenarioWithBuyerMoney(conn, 7L);
            assumeTrue(scenario != null, "No hay escenario de cláusula viable en liga 7");

            long idLj = scenario.idLigaJugador();
            long sellerId = scenario.sellerUserId();
            long buyerId = scenario.buyerUserId();
            long idJornada = scenario.idJornada();
            long idLp = scenario.sellerParticipantId();

            conn.setAutoCommit(false);
            try {
                LeagueLineupService lineupService = new LeagueLineupService();
                LeaguePlayerMarketValueService marketValueService = new LeaguePlayerMarketValueService();
                LeagueTradeService tradeService = new LeagueTradeService(
                        lineupService,
                        null,
                        null,
                        null,
                        null,
                        marketValueService,
                        null
                );

                tradeService.executeDirectClauseWithinTransaction(
                        conn,
                        7L,
                        idLj,
                        buyerId,
                        1.0d,
                        1.0d,
                        null
                );

                assertFalse(lineupContainsPlayer(conn, idLp, idJornada, idLj));
            } finally {
                conn.rollback();
                conn.setAutoCommit(true);
            }
        }
    }

    private static void transferOwnership(
            Connection conn,
            long idLigaJugador,
            long fromUser,
            long toUser
    ) throws SQLException {
        String sql = """
                UPDATE liga_jugadores
                SET id_usuario_dueno = ?
                WHERE id = ?
                  AND id_usuario_dueno = ?
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, toUser);
            ps.setLong(2, idLigaJugador);
            ps.setLong(3, fromUser);
            int n = ps.executeUpdate();
            if (n != 1) {
                throw new SQLException("No se pudo simular la transferencia del jugador " + idLigaJugador);
            }
        }
    }

    private static Scenario findOpenLineupScenario(Connection conn, long idLiga) throws SQLException {
        return queryScenario(conn, idLiga, false);
    }

    private static Scenario findOpenLineupScenarioWithBuyerMoney(Connection conn, long idLiga) throws SQLException {
        return queryScenario(conn, idLiga, true);
    }

    private static Scenario queryScenario(Connection conn, long idLiga, boolean requireBuyerFunds) throws SQLException {
        String sql = """
                SELECT lj.id AS id_lj,
                       lj.id_usuario_dueno AS seller_id,
                       lp_v.id AS seller_lp,
                       buyer_lp.id_usuario AS buyer_id,
                       ajp.id_jornada AS id_jornada
                FROM liga_jugadores lj
                INNER JOIN liga_participantes lp_v
                  ON lp_v.id_liga = lj.id_liga AND lp_v.id_usuario = lj.id_usuario_dueno
                INNER JOIN liga_participantes buyer_lp
                  ON buyer_lp.id_liga = lj.id_liga AND buyer_lp.id_usuario <> lj.id_usuario_dueno
                INNER JOIN alineacion_jornada_participante ajp
                  ON ajp.id_liga_participante = lp_v.id AND ajp.id_liga_jugador = lj.id
                INNER JOIN jornadas j ON j.id = ajp.id_jornada AND j.id_liga = lj.id_liga
                WHERE lj.id_liga = ?
                  AND lj.id_usuario_dueno NOT IN (1)
                  AND j.estado NOT IN ('EN_CURSO', 'FINALIZADA')
                  AND NOT EXISTS (
                      SELECT 1 FROM partidos_jornada pj
                      WHERE pj.id_jornada = j.id
                        AND pj.estado IN ('EN_JUEGO', 'FINALIZADO')
                  )
                  AND COALESCE((
                      SELECT MIN(pj2.inicio_en) FROM partidos_jornada pj2 WHERE pj2.id_jornada = j.id
                  ), '9999-12-31') > NOW()
                """ + (requireBuyerFunds ? """
                  AND buyer_lp.dinero >= lj.valor
                """ : "") + """
                ORDER BY j.numero ASC
                LIMIT 1
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                return new Scenario(
                        rs.getLong("id_lj"),
                        rs.getLong("seller_id"),
                        rs.getLong("seller_lp"),
                        rs.getLong("buyer_id"),
                        rs.getLong("id_jornada")
                );
            }
        }
    }

    private static boolean lineupContainsPlayer(
            Connection conn,
            long idLigaParticipante,
            long idJornada,
            long idLigaJugador
    ) throws SQLException {
        String sql = """
                SELECT COUNT(*) AS c
                FROM alineacion_jornada_participante ajp
                WHERE ajp.id_liga_participante = ?
                  AND ajp.id_jornada = ?
                  AND ajp.id_liga_jugador = ?
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLigaParticipante);
            ps.setLong(2, idJornada);
            ps.setLong(3, idLigaJugador);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt("c") > 0;
            }
        }
    }

    private record Scenario(
            long idLigaJugador,
            long sellerUserId,
            long sellerParticipantId,
            long buyerUserId,
            long idJornada
    ) {
    }

    private static boolean invokeSnapshotContains(LeagueLineupService service, Object snapshot, long idLj)
            throws Exception {
        Method m = LeagueLineupService.class.getDeclaredMethod(
                "snapshotContainsLeaguePlayer",
                Class.forName("com.eternalxi.eternalxi_api.services.LeagueLineupService$LineupSnapshot"),
                Long.class
        );
        m.setAccessible(true);
        return (boolean) m.invoke(service, snapshot, idLj);
    }

    private static Object entry(long id, String pos, long valor) throws Exception {
        Class<?> cls = Class.forName("com.eternalxi.eternalxi_api.services.LeagueLineupService$LineupEntry");
        Constructor<?> ctor = cls.getDeclaredConstructors()[0];
        ctor.setAccessible(true);
        return ctor.newInstance(id, pos, valor);
    }

    private static Object snapshot(List<Object> titulares, List<Object> reservas, Long capitan) throws Exception {
        Class<?> cls = Class.forName("com.eternalxi.eternalxi_api.services.LeagueLineupService$LineupSnapshot");
        Constructor<?> ctor = cls.getDeclaredConstructors()[0];
        ctor.setAccessible(true);
        return ctor.newInstance(titulares, reservas, capitan);
    }
}
