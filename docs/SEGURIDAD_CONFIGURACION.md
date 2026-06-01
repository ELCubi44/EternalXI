# Seguridad Eternal XI — qué se ha hecho y qué debes guardar

## Resumen

| Capa | Medida |
|------|--------|
| **API** | Spring Security + JWT obligatorio (salvo login, registro, reset, imágenes) |
| **Contraseñas** | BCrypt (las antiguas SHA-256 se migran al iniciar sesión) |
| **Suplantación** | No puedes usar `idUsuario` de otro en la URL si el token es tuyo |
| **Abuso login** | Límite de intentos por IP en `/api/v1/auth/*` |
| **Cabeceras** | HSTS, anti-clickjacking, sin stack traces al cliente |
| **Secretos** | Fuera del código: variables de entorno en el VPS |
| **App** | Token en almacenamiento seguro + envío `Authorization: Bearer` |

---

## Lo que TÚ debes guardar (y no subir a Git)

Crea un bloc de notas privado o gestor de contraseñas con:

### 1. Servidor VPS (`/etc/systemd/system/miapi.service.d/override.conf`)

```ini
[Service]
Environment=ETERNALXI_JWT_SECRET=PON_AQUI_UN_SECRETO_LARGO
Environment=ETERNALXI_DB_URL=jdbc:mysql://localhost:3306/EternalXI
Environment=ETERNALXI_DB_USER=userRoot
Environment=ETERNALXI_DB_PASSWORD=TU_PASSWORD_MYSQL
```

**Generar JWT secret (en tu PC):**

```powershell
[Convert]::ToBase64String((1..48 | ForEach-Object { Get-Random -Maximum 256 }))
```

Mínimo **32 bytes** aleatorios. **Nunca** el mismo que en el ejemplo.

### 2. Tras desplegar

```bash
sudo systemctl daemon-reload
sudo systemctl restart miapi
```

### 3. App móvil

Los usuarios deben **volver a iniciar sesión** una vez (el token falso `token-temporal` ya no vale).

---

## Qué ya no está en el código

- La contraseña de MySQL **ya no** va hardcodeada en `DBConnection.java`.
- El login **ya no** devuelve `token-temporal`.

---

## HTTPS

La app debe usar `https://api.eternalxi.com`. Ver `docs/GUIA_HTTPS_DOMINIO_Y_WEB.md`.

---

## Pendiente / recomendaciones futuras

- **Certificado pinning** en Flutter (más fricción al renovar Let's Encrypt).
- **WAF / fail2ban** en el VPS frente a escaneos.
- **Backups cifrados** de la base de datos.
- Revisar que **Firebase** y **correo SMTP** también usen credenciales solo en el servidor.

---

## Si algo deja de funcionar

1. ¿`ETERNALXI_DB_PASSWORD` está en el servicio `miapi`?
2. ¿`ETERNALXI_JWT_SECRET` definido y reiniciado el servicio?
3. ¿La app tiene sesión nueva (login otra vez)?
4. Logs: `journalctl -u miapi -n 80 --no-pager`
