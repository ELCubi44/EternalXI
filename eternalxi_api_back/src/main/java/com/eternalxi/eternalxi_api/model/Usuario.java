package com.eternalxi.eternalxi_api.model;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;

public class Usuario {

    private int id;
    private String correo;
    private String contrasena;
    private String nickname;
    private int nivel;
    private String codigoReinicio;

    public Usuario() {
    }

    public Usuario(int id, String correo, String contrasena, String nickname, int nivel, String codigoReinicio) {
        this.id = id;
        this.correo = correo;
        this.contrasena = contrasena;
        this.nickname = nickname;
        this.nivel = nivel;
        this.codigoReinicio = codigoReinicio;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getCorreo() {
        return correo;
    }

    public void setCorreo(String correo) {
        this.correo = correo;
    }

    public String getContrasena() {
        return contrasena;
    }

    public void setContrasena(String contrasena) {
        this.contrasena = contrasena;
    }

    public String getNickname() {
        return nickname;
    }

    public void setNickname(String nickname) {
        this.nickname = nickname;
    }

    public int getNivel() {
        return nivel;
    }

    public void setNivel(int nivel) {
        this.nivel = nivel;
    }

    public String getCodigoReinicio() {
        return codigoReinicio;
    }

    public void setCodigoReinicio(String codigoReinicio) {
        this.codigoReinicio = codigoReinicio;
    }

    public static String encriptarContrasena(String contrasena) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] hash = md.digest(contrasena.getBytes(StandardCharsets.UTF_8));
            StringBuilder hexString = new StringBuilder();

            for (byte b : hash) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) {
                    hexString.append('0');
                }
                hexString.append(hex);
            }

            return hexString.toString();

        } catch (Exception e) {
            throw new RuntimeException("Error encriptando contraseña", e);
        }
    }
}