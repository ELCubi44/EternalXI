package com.eternalxi.eternalxi_api.config;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DBConnection {

    private static final String URL = "jdbc:mysql://localhost:3306/EternalXI";
    private static final String USER = "userRoot";
    private static final String PASSWORD = "76767676miguelmM44gg44";

    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(URL, USER, PASSWORD);
    }
}
