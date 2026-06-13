package com.eternalxi.eternalxi_api.util;

import com.eternalxi.eternalxi_api.dto.user.UserResponse;

import java.sql.Date;
import java.sql.ResultSet;
import java.sql.SQLException;

public final class UserMapper {

    private UserMapper() {}

    public static UserResponse fromResultSet(ResultSet rs) throws SQLException {
        return fromResultSet(rs, rs.getLong("id"));
    }

    public static UserResponse fromResultSet(ResultSet rs, long id) throws SQLException {
        Date birth = readBirthDate(rs);
        return new UserResponse(
                id,
                rs.getString("correo"),
                rs.getString("nickname"),
                rs.getInt("nivel"),
                LeagueAssetUrls.userPhotoIfStored(id, rs.getString("foto")),
                birth == null
        );
    }

    private static Date readBirthDate(ResultSet rs) {
        try {
            return rs.getDate("fecha_nacimiento");
        } catch (SQLException e) {
            return null;
        }
    }

    public static UserResponse withoutBirthCheck(
            long id,
            String correo,
            String nickname,
            int nivel,
            String foto
    ) {
        return new UserResponse(id, correo, nickname, nivel, foto, false);
    }
}
