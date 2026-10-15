# Estado actual — Eternal XI / Eternal Clash

Última actualización: 2026-10-15.

## Ahora: RUPTURA 0.2

- Tras la prueba del usuario se abandona la jugabilidad del prototipo 0.1: no resultaba divertida, el campo era pequeño y los duelos no identificaban bien al rival.
- Nuevo motor y nueva UI en `eternalclash_godot/`: Godot 4.7.2/GDScript, horizontal 1600×720, campo grande y acciones sobre compañeros elegidos tocando el campo. Los scripts del combate 0.1 se retiraron del proyecto activo y permanecen en Git.
- Mecánica: pases que dejan huellas, marcas que reaccionan al lugar anterior del balón, paredes que hacen avanzar y señuelos que desplazan a compañero y marcador. Previsualización del interceptor real; rutas libres sin dados.
- Ruptura exige tres identidades, amplitud y profundidad; habilita un remate combinado con mayor zona de acierto. No basta pasar hacia atrás.
- Duelos con nombres completos, retratos y técnicas de ambos; intención visible, enfoque y pulso manual. También se controla al portero ante un contraataque identificado. Sin RNG; seis pulsos por posesión y hasta seis rondas o tres goles.
- App **Eternal Clash Prueba**, paquete `es.eternalxi.clash.prototype`, versión `0.2.0` (2). APK debug ARM64 en `releases/eternal-clash-prototype-0.2.0.apk`, fuera de Git. Instalada en el ZTE A7050.
- Conservados catálogo/retratos de dos equipos, colección de 19 cartas Eternal XI, formación, entrenamiento, monedas y niveles. La partida 0.1 no se usa en el motor nuevo. Original Flutter y API Spring sin modificar.

## Verificado

- Importación, exportación y firma debug; 3159 comprobaciones de reglas, 120 partidos con distintos perfiles de acciones/pulso y cero fallos. Se comprueban rutas liberadas por señuelos, identidades, guardado/reanudación, límites y premio único.
- UI: Inicio, Equipo, Cartas, campo, selección, duelo y resultado; incluye texto largo y límites del viewport base, sin fallos.
- ZTE A7050: arranque horizontal, campo y previsualización; duelo de tiro Thiago–Magnus resuelto mediante input real, seguido de parada manual Hugo–Ralf. Se verificó reabrir manteniendo posiciones, posesión, marcador y perfil. No equivale a un partido completo humano de la versión nueva.
- Capturas reales de 0.2 en `docs/images/rupture_0_2/`: Inicio, campo, señuelo, duelo de tiro y defensa manual. Se deja seleccionada la previsualización del señuelo de Andrés, sin gastar el pulso; marcador de prueba 1–0 en la segunda posesión.
- Se conservan las pruebas previas de Android 0.1 (partidos completos y entrenamiento), pero no se presentan como validación de la nueva jugabilidad.
- Scripts: `scripts/build_clash_godot.ps1` y `scripts/export_clash_godot_content.ps1`; reglas/instrucciones en `eternalclash_godot/README.md`, diseño en `docs/CLASH_RUPTURE_DESIGN.md`.

## Siguiente objetivo

- Que el usuario pruebe RUPTURA y valore si crear huecos y resolver los duelos resulta interesante. No considerar la diversión validada por los tests.
- Observar legibilidad, dificultad, uso real de señuelos/paredes, ritmo y estrategias repetitivas; después ampliar escenarios y conductas rivales.
- Sin medición de FPS, batería ni QA en otros dispositivos. Aún sin campaña jugable, gacha, adquisición de cartas, PvP, API/economía autoritativa o cinemáticas finales. Sonidos breves y animaciones básicas incluidos.

## Límites del proyecto original

- Rama de trabajo: `codex/clash-godot-android-prototype`; la demo 0.1 es recuperable en `8d98626`. Cambios revisables en el PR de la rama, sin merge/deploy de producción.
- Auditoría inicial: `docs/CLASH_GODOT_REVIEW.md`; catálogo Flutter completo de 912 variantes/304 jugadores/16 equipos. Flutter sigue en `1.3.10+18`, independiente de Fantasy.
- Pruebas Flutter originales: 765 aprobadas y 121 fallidas con la resolución local de Flutter 3.44.5/Dart 3.12.2; lock restaurado. No se han vuelto a ejecutar porque no se ha cambiado ese cliente.
- El backend registra reclamaciones, pero todavía no concede recompensas autoritativas. No se ha desplegado ni modificado la API.
- No usar `EternalXI-play-publish` como origen ni copiar versión de Fantasy. APK, firmas, cachés y archivos privados quedan fuera de Git.
