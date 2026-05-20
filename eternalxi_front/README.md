# Eternal XI

Frontend inicial en Flutter para autenticacion y perfil, conectado al backend Spring.

## Requisitos

- Flutter SDK instalado
- Backend Java Spring corriendo en `http://217.154.184.202:8080`

## Configuracion API

La base URL esta en `lib/core/constants/api_constants.dart`:

- URL actual: `http://217.154.184.202:8080/api/v1`

## Ejecutar local

1. Instalar dependencias:
   - `flutter pub get`
2. Analizar proyecto:
   - `flutter analyze`
3. Ejecutar app (emulador Android):
   - `flutter run`

## Flujos implementados

- Splash con restauracion de sesion (`flutter_secure_storage`)
- Login
- Verificacion de email (request + confirm)
- Registro final
- Recuperacion de contrasena (request + confirm)
- Home base con logout
- Perfil (GET usuario)
- Editar perfil (PATCH nickname/nivel)
- Borrar cuenta (DELETE + limpieza de sesion)
