# Estado actual — Eternal XI / Eternal Clash

Última actualización: 2026-10-15.

## Ahora

- Prototipo separado `eternalclash_godot/`, Godot 4.7.2 estándar / GDScript, renderer Compatibility y orientación vertical. Flutter y API originales conservados.
- Rama de trabajo: `codex/clash-godot-android-prototype`, basada en `main` / `8cad6f7`.
- App **Eternal Clash Prueba**, paquete `es.eternalxi.clash.prototype`, versión `0.1.0`. APK debug ARM64 en `releases/eternal-clash-prototype-0.1.0.apk` (ignorada por Git), instalada en el ZTE A7050 conectado.
- 38 cartas N exportadas de dos equipos conservando playerId e IDs originales. Colección inicial de 19 jugadores Eternal XI, formación editable de siete y capitán. Los 38 retratos están optimizados y empaquetados para jugar sin red.
- Partido de demo: circulación de balón por los seis jugadores de campo, pase/regate/tiro/supertécnica, energía, enlace de jugada, portero/defensa automáticos y acción de repliegue. Primero a tres goles o límite de 18 acciones.
- Recompensa, mejora de cartas y guardado local independiente con backup y reanudación. Portero/defensas influyen en el riesgo rival; atributos del poseedor y capitán en las probabilidades. No es paridad con el motor Dart original.
- Verificado: importación, exportación y firma debug; 3269 comprobaciones de dominio con 200 partidos simulados y 0 fallos; 5 pantallas más selector de formación comprobados sin fallos en el viewport base.
- En Android real se verificaron arranque, partido completo (primera prueba 3–0), recompensa de 100, reanudación de partida y entrenamiento del portero (nivel 2, coste 50), conservado tras reabrir. El prototipo no solicita permiso de Internet.
- Segunda prueba con la APK final: partido 3–2, recompensa correcta y reapertura sin duplicarla. Se deja Inicio abierto, 300 monedas y portero nivel 2 como resultado de las pruebas. Capturas reales en `docs/images/clash_godot/`; sin errores Godot/AndroidRuntime en el log filtrado de la comprobación.
- Build/instalación reproducibles: `scripts/build_clash_godot.ps1`; exportación de contenido: `scripts/export_clash_godot_content.ps1`; instrucciones en `eternalclash_godot/README.md`.

## Límites y próximos pasos

- Recoger sensaciones en el teléfono: ritmo, controles, claridad, tamaño de cartas y dificultad. No hay todavía medición de FPS, consumo ni QA en otros móviles.
- Prototipo sin sonido, cinemáticas finales, defensa manual, historia jugable, gacha, nuevas cartas desbloqueables, enlaces entre personajes, pagos, PvP ni sync/API.
- Afinar reglas y presentación a partir de la prueba antes de migrar más sistemas o equipos. Las reglas actuales son propias y simplificadas; no asumir equivalencia con Flutter.
- Reparar por separado el cliente Flutter original: pruebas de Clash ejecutadas con Flutter 3.44.5 / Dart 3.12.2 dieron 765 aprobadas y 121 fallidas, incluyendo compilación/carga. La ejecución resolvió dependencias distintas; se restauró su lock. No se ha probado sesión completa Android del original ni servidor remoto.
- El servidor original registra reclamaciones idempotentes, pero aún no concede recompensas de forma autoritativa. No usar el guardado de demo como economía segura.
- Mantener pendiente TestFlight del cliente original; versión Flutter leída `1.3.10+18`, independiente de Fantasy.

## Referencias y límites de proyecto

- Auditoría inicial: `docs/CLASH_GODOT_REVIEW.md`. Catálogo Flutter completo: 912 variantes, 304 jugadores, 16 equipos; retratos de red.
- No usar `EternalXI-play-publish` como origen ni copiar números de versión de Eternal Fantasy.
- La demo no reemplaza la app `es.eternalxi.app` ni importa sus partidas. No se ha desplegado ni modificado la API.
- APK, firma debug y archivos privados fuera de Git; datos, código y recursos del prototipo se versionan en su rama.
