# Estado actual — Eternal XI / Eternal Clash

Última actualización: 2026-10-15.

## Ahora: RUPTURA 0.3 vertical

- El usuario considera interesante la nueva mecánica y pide juego vertical, más campo, líneas/círculos claros, interfaz mejorada y supertécnicas visibles.
- Godot 4.7.2/GDScript, diseño 720×1600 con ataque hacia arriba. Campo a todo el ancho y más del 70% de la altura; áreas/círculo central de alto contraste, retratos dentro de discos con shader, aros dobles por equipo y selección destacada. HUD compacto arriba y acciones/confirmación abajo.
- Menús, colección, formación, resultados y duelos adaptados a vertical. Sigue Ruptura: huellas, paredes, señuelos, rutas previsualizadas e intervención manual en ataque y portería.
- Botón morado **SÚPER** abre las técnicas reales del poseedor. Hay 60 PT iniciales, límite 100, y recarga por pases/paredes/señuelos, perfectos y nuevas rondas.
- Supertécnicas activables con coste, presentación animada propia y efecto: Regate del Eclipse (27 PT, duelo reforzado y avance al ganarlo), Disparo Valestia (30 PT, refuerzo de tiro) y Muro de Puños (24 PT, refuerzo de parada antes de elegir enfoque). La potencia del catálogo influye en la ventana de acierto.
- Una técnica activada se guarda antes de animar y no vuelve a cobrarse al reabrir. Las partidas 0.2 conservan posiciones, marcador, monedas y niveles y añaden 60 PT.
- App **Eternal Clash Prueba**, `es.eternalxi.clash.prototype`, versión `0.3.0` (3), APK debug ARM64 en `releases/eternal-clash-prototype-0.3.0.apk`, fuera de Git. Instalada en el ZTE A7050.

## Verificado

- Importación/exportación/firma debug correctas. Pruebas de dominio: 3177 comprobaciones, 120 partidos, cero fallos. Incluyen activación/coste/efecto de las técnicas, PT insuficientes, recarga y reanudación sin cobro doble.
- UI: campo vertical dominante, 14 retratos circulares, controles en pantalla, textos largos, menú SÚPER, dos presentaciones animadas, duelos ofensivos/defensivos y resultados; sin fallos en el viewport base. Las pruebas UI usan perfil en memoria.
- Android real: campo vertical y menú SÚPER inspeccionados. Regate del Eclipse activado contra Till, coste 60→33 PT y avance real tras ganar. Muro de Puños activado por 24 PT y parada manual contra Ralf. Disparo Valestia activado por 30 PT y gol manual contra Magnus, cerrando la partida reanudada 3–0.
- Se comprobó cerrar/reabrir el supertiro pendiente: conservó técnica y PT, sin segundo cobro; premio final y saldo también conservados tras reabrir. Tres usos especiales registrados en esa prueba, saldo resultante 400 monedas.
- Se deja una partida nueva abierta en el campo, 0–0 y 60 PT, con monedas, formación y nivel 2 del portero conservados. Sin errores Godot/AndroidRuntime en el log filtrado de la comprobación.
- Capturas reales de 0.3 en `docs/images/rupture_0_3/`. Capturas 0.2 y 0.1 conservadas como histórico, no como evidencia del diseño actual.
- Build/instalación: `scripts/build_clash_godot.ps1`; instrucciones y costes en `eternalclash_godot/README.md`. Diseño en `docs/CLASH_RUPTURE_DESIGN.md`.

## Siguiente objetivo

- Probar en vertical: claridad de las rutas, tamaño de los círculos, comodidad de controles y uso de las técnicas. Afinar el ritmo con la respuesta del usuario.
- Las presentaciones de supertécnica son efectos 2D provisionales, no animaciones dibujadas de acciones futbolísticas. Faltan más disposiciones/conductas rivales, campaña, adquisición de cartas, PvP, API/economía autoritativa y acabado audiovisual final.
- Técnicas de defensa de jugadores de campo pendientes de una fase compatible; el menú informa cuando una técnica no se puede activar. Las técnicas de regate, tiro, pase y parada tienen soporte según su fase.
- Sin medición de FPS/batería ni QA en otros dispositivos. No se considera que pasar tests valide diversión.

## Límites del proyecto original

- Rama `codex/clash-godot-android-prototype`, PR de trabajo sin merge ni deploy de producción. La demo 0.1 es recuperable en `8d98626`; el rediseño 0.2 en `19f5236`.
- Cliente Flutter y API Spring originales sin modificar. Flutter sigue en `1.3.10+18`, independiente de Fantasy. No se ha desplegado la API.
- Auditoría original: `docs/CLASH_GODOT_REVIEW.md`; catálogo completo 912 variantes/304 jugadores/16 equipos. La demo usa 38 variantes N de dos equipos y 19 cartas propias iniciales con retratos locales.
- Pruebas Flutter originales: 765 aprobadas y 121 fallidas en la resolución local Flutter 3.44.5/Dart 3.12.2; lock restaurado. No se vuelven a ejecutar porque no se cambia ese cliente.
- Backend original registra reclamaciones sin conceder aún recompensas autoritativas. El guardado de la demo es local.
- No usar `EternalXI-play-publish` como origen ni copiar versión de Fantasy. APK, firmas, cachés y archivos privados fuera de Git; código, sonidos y recursos del prototipo versionados.
