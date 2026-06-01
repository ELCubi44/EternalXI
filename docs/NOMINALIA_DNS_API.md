# Nominalia — qué hacer para `api.eternalxi.com` (solo 5 minutos)

Ya está instalado el “portero” HTTPS (Caddy) en tu VPS. **Falta solo que el dominio apunte al servidor.**

No necesitas comprar otro dominio. Usas **eternalxi.com** (el que ya tienes).

---

## Lo único obligatorio para la app

Crear **una línea DNS** para que **`api.eternalxi.com`** vaya a tu VPS:

| Campo en Nominalia | Valor |
|--------------------|--------|
| **Tipo** | `A` |
| **Nombre / host** | `api` |
| **Destino / IP** | `217.154.184.202` |
| **TTL** | Por defecto (o 300 si te deja elegir) |

> **No** pongas `api.eternalxi.com` entero en “nombre”: solo **`api`**. El panel añade solo `.eternalxi.com`.

---

## Pasos en Nominalia (pantalla a pantalla)

1. Entra en **https://www.nominalia.com** e inicia sesión.
2. Menú **Dominios** → elige **eternalxi.com**.
3. Busca algo como:
   - **“Zona DNS”**, o
   - **“Gestión DNS”**, o
   - **“DNS / Registros”**.
4. Pulsa **Añadir registro** (o **Nuevo registro**).
5. Rellena la tabla de arriba (`A`, `api`, `217.154.184.202`).
6. **Guardar**.

Espera **15–60 minutos** (a veces hasta 2 horas).

---

## Cómo saber si ya está bien

En tu PC, abre PowerShell:

```powershell
nslookup api.eternalxi.com
```

Debe aparecer la IP **`217.154.184.202`**.

Luego abre en el navegador:

**https://api.eternalxi.com/api/v1/**

Si carga algo (aunque sea un mensaje de error de la API), **HTTPS está listo** y la app nueva funcionará.

---

## Sobre `www` y la web

Ahora **eternalxi.com** y **www** apuntan a los servidores de Nominalia (`81.88.48.71`), no a tu VPS. Eso está bien para una web alojada en Nominalia.

- **La app** usará solo **`api.eternalxi.com`** (tu VPS).
- Si más adelante quieres la web en el mismo VPS, habrá que cambiar también los registros de `@` y `www` a `217.154.184.202`. Lo vemos cuando quieras.

---

## Cuando termines en Nominalia

Escribe en Cursor: **“Ya he puesto el DNS de api”** y comprobamos el certificado y la app.
