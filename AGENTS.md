# Eternal XI (historia / Clash)

## Qué es

Cliente Flutter + API Spring del **juego de historia / Clash**. GitHub: `ELCubi44/EternalXI`. Package: `es.eternalxi.app`. El fantasy está en `EternalFantasy`.

## Arquitectura

- Flutter: `eternalxi_front/` (versión leída: `1.3.10+18`).
- API compartida: `eternalxi_api_back/` (Spring Boot, MySQL, `miapi.service` en el VPS).
- Docs de Clash, QA y contratos en `docs/` (varios `CLASH_*.md`).
- Scripts: `scripts/run-mobile.ps1`, `scripts/deploy-server.ps1`, publicación Play en `scripts/build_play_release.ps1` y afines.

## Instalar, ejecutar y probar

Ver `docs/DEVELOPMENT.md` y `eternalxi_front/README.md`.

## Restricciones importantes

- Versión iOS = versión Android **de este** `pubspec.yaml`, nunca la de Fantasy.
- Assets visuales nuevos deben ir a GitHub.
- Tras login, el flujo documentado entra al hub de historia; Clash puede estar bloqueado en UI según el código/docs.
- No leer secretos ni `application.properties`.

## Flujo Git

`/actualizar-proyecto` al empezar. `/cerrar-trabajo` al terminar. Nunca force-push.

## Secretos (nunca subir)

`.env`, `.local/`, keystores, Fastlane JSON, `application-prod.properties`, `eternalxi_api_back/src/main/resources/application.properties`.

## Contexto duradero

Actualiza `docs/CURRENT_STATUS.md` al finalizar trabajo relevante.
