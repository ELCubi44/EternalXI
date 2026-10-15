# Estado actual — Eternal XI / Eternal Clash

Última actualización: 2026-10-15.

## Revisión artística posterior a 0.4: calidad rechazada

- El usuario ha visto la prueba 0.4 y rechaza el aspecto del personaje y las animaciones. Quiere conservar la identidad y el diseño artístico exacto de las ilustraciones y secuencias de calidad inspirada en su referencia de Inazuma Eleven GO Galaxy: `https://www.youtube.com/watch?v=sIJTPFxqYFI`.
- Las figuras rígidas de 0.4 demuestran reutilización técnica, pero **no cumplen** la dirección artística ni la calidad pedida. No seguir presentándolas como una aproximación suficiente al personaje original.
- Se han revisado fragmentos del vídeo en el navegador y generado, usando el retrato original como referencia, una hoja de Thiago de cuerpo completo y cuatro imágenes clave de Valestia. Archivos en `docs/art/thiago-v2/`, con prompts y límites. Son borradores visuales; no implican aprobación del usuario ni constituyen animación fluida o modelo 3D.
- Pendiente el modelo anime fiel con malla, pesos, esqueleto/expresiones y coreografía real. La herramienta de imágenes produce referencias raster; no convierte automáticamente una foto en un modelo riggeado de esa calidad. La APK no se modifica en esta revisión.

## Última demo instalada: RUPTURA 0.4, prueba técnica de personajes 3D

- Petición: personajes de cuerpo completo que ejecuten supertécnicas reutilizables según su apariencia, empezando por Thiago.
- Modelo 3D provisional de piezas articuladas por nodos y biblioteca `AnimationLibrary` compartida. Apariencias Thiago, Miguel y Hugo basadas en sus retratos; cara/pelo/ropa aproximados, no modelado orgánico final ni reconstrucción automática desde una foto.
- Disparo Valestia: concentración, preparación de la pierna, patada, balón/estela y recuperación; cámara de cara a cuerpo completo (5,2 s). Movimientos adicionales provisionales de giro para Eclipse (4,2 s) y brazos/barrera para Muro (4,4 s).
- Inicio → **Ver supertécnicas** permite repetir sin gastar PT y comparar la misma patada con Thiago/Miguel. La muestra no desbloquea Valestia para Miguel. El resto de jugadores conserva el retrato hasta disponer de apariencia propia.
- Integradas en la activación del partido, conservando reglas, PT y guardado. Escena aislada con ancho máximo de render 540 px. Paquete `es.eternalxi.clash.prototype`, 0.4.0 (4), APK local fuera de Git.
- Reglas: 3177 comprobaciones/120 partidos, cero fallos. Pruebas UI incluyendo visor sin cambios de perfil; prueba específica de animación, cambio de apariencia, biblioteca compartida, señal única y liberación. Capturas de escritorio con renderer real y pruebas visuales en ZTE A7050.
- Android: visor, Valestia con Thiago/Miguel y parada con Hugo; retorno al visor, sin errores en log filtrado. Primera apertura más lenta; pendiente medir FPS, arranque, memoria y batería. No dar por validada la fluidez por capturas.
- Detalle técnico y siguiente trabajo artístico: `docs/CLASH_CHARACTER_ANIMATION.md`. Código/recursos procedurales versionados; original Flutter/API conservado.

## Base anterior: RUPTURA 0.3 vertical

- El usuario considera interesante la nueva mecánica y pide juego vertical, más campo, líneas/círculos claros, interfaz mejorada y supertécnicas visibles.
- Godot 4.7.2/GDScript, diseño 720×1600 con ataque hacia arriba. Campo a todo el ancho y más del 70% de la altura; áreas/círculo central de alto contraste, retratos dentro de discos con shader, aros dobles por equipo y selección destacada. HUD compacto arriba y acciones/confirmación abajo.
- Menús, colección, formación, resultados y duelos adaptados a vertical. Sigue Ruptura: huellas, paredes, señuelos, rutas previsualizadas e intervención manual en ataque y portería.
- Botón morado **SÚPER** abre las técnicas reales del poseedor. Hay 60 PT iniciales, límite 100, y recarga por pases/paredes/señuelos, perfectos y nuevas rondas.
- Supertécnicas activables con coste, presentación animada propia y efecto: Regate del Eclipse (27 PT, duelo reforzado y avance al ganarlo), Disparo Valestia (30 PT, refuerzo de tiro) y Muro de Puños (24 PT, refuerzo de parada antes de elegir enfoque). La potencia del catálogo influye en la ventana de acierto.
- Una técnica activada se guarda antes de animar y no vuelve a cobrarse al reabrir. Las partidas 0.2 conservan posiciones, marcador, monedas y niveles y añaden 60 PT.
- App **Eternal Clash Prueba**, `es.eternalxi.clash.prototype`, versión `0.3.0` (3), APK debug ARM64 en `releases/eternal-clash-prototype-0.3.0.apk`, fuera de Git. Instalada en el ZTE A7050.

## Verificado en 0.3 (histórico)

- Importación/exportación/firma debug correctas. Pruebas de dominio: 3177 comprobaciones, 120 partidos, cero fallos. Incluyen activación/coste/efecto de las técnicas, PT insuficientes, recarga y reanudación sin cobro doble.
- UI: campo vertical dominante, 14 retratos circulares, controles en pantalla, textos largos, menú SÚPER, dos presentaciones animadas, duelos ofensivos/defensivos y resultados; sin fallos en el viewport base. Las pruebas UI usan perfil en memoria.
- Android real: campo vertical y menú SÚPER inspeccionados. Regate del Eclipse activado contra Till, coste 60→33 PT y avance real tras ganar. Muro de Puños activado por 24 PT y parada manual contra Ralf. Disparo Valestia activado por 30 PT y gol manual contra Magnus, cerrando la partida reanudada 3–0.
- Se comprobó cerrar/reabrir el supertiro pendiente: conservó técnica y PT, sin segundo cobro; premio final y saldo también conservados tras reabrir. Tres usos especiales registrados en esa prueba, saldo resultante 400 monedas.
- Se deja una partida nueva abierta en el campo, 0–0 y 60 PT, con monedas, formación y nivel 2 del portero conservados. Sin errores Godot/AndroidRuntime en el log filtrado de la comprobación.
- Capturas reales de 0.3 en `docs/images/rupture_0_3/`. Capturas 0.2 y 0.1 conservadas como histórico, no como evidencia del diseño actual.
- Build/instalación: `scripts/build_clash_godot.ps1`; instrucciones y costes en `eternalclash_godot/README.md`. Diseño en `docs/CLASH_RUPTURE_DESIGN.md`.

## Siguiente objetivo

- Probar en vertical: claridad de las rutas, tamaño de los círculos, comodidad de controles y uso de las técnicas. Afinar el ritmo con la respuesta del usuario.
- Las presentaciones 0.4 animan figuras 3D provisionales. Falta modelo base con malla/pesos/esqueleto definitivo, parecido facial, coreografías propias para más técnicas y acabado anime. También más disposiciones/conductas rivales, campaña, adquisición de cartas, PvP y API/economía autoritativa.
- Técnicas de defensa de jugadores de campo pendientes de una fase compatible; el menú informa cuando una técnica no se puede activar. Las técnicas de regate, tiro, pase y parada tienen soporte según su fase.
- Sin medición de FPS/batería ni QA en otros dispositivos. No se considera que pasar tests valide diversión.

## Límites del proyecto original

- Rama `codex/clash-godot-android-prototype`, PR de trabajo sin merge ni deploy de producción. La demo 0.1 es recuperable en `8d98626`; el rediseño 0.2 en `19f5236`.
- Cliente Flutter y API Spring originales sin modificar. Flutter sigue en `1.3.10+18`, independiente de Fantasy. No se ha desplegado la API.
- Auditoría original: `docs/CLASH_GODOT_REVIEW.md`; catálogo completo 912 variantes/304 jugadores/16 equipos. La demo usa 38 variantes N de dos equipos y 19 cartas propias iniciales con retratos locales.
- Pruebas Flutter originales: 765 aprobadas y 121 fallidas en la resolución local Flutter 3.44.5/Dart 3.12.2; lock restaurado. No se vuelven a ejecutar porque no se cambia ese cliente.
- Backend original registra reclamaciones sin conceder aún recompensas autoritativas. El guardado de la demo es local.
- No usar `EternalXI-play-publish` como origen ni copiar versión de Fantasy. APK, firmas, cachés y archivos privados fuera de Git; código, sonidos y recursos del prototipo versionados.
