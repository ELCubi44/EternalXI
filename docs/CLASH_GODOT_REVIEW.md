# Revisión de Clash y propuesta Godot

Fecha: 2026-10-15. Base: `8cad6f7`, Flutter `1.3.10+18`.

**Revisión inicial, anterior a la implementación.** Después se creó y se instaló el primer prototipo. Su estado vigente está en `eternalclash_godot/README.md` y `docs/CURRENT_STATUS.md`; esta revisión describe el punto de partida.

## Conclusión

Hay una base amplia de juego de cartas y fútbol táctico. Recomendación: conservar Flutter y la API, y validar un prototipo 2D independiente en Godot 4 con GDScript antes de decidir una migración completa. Cambiar de motor facilita animación y escenas, pero no resuelve por sí solo el equilibrio ni la diversión.

Esta revisión no crea todavía el proyecto Godot ni una APK. No se ha probado el juego en un dispositivo ni el servidor remoto. No se han leído secretos ni application.properties.

## Evidencia actual

- `assets/data/clash/cards.json`: 912 variantes de carta, 304 playerId distintos, 16 equipos; 304 cartas de cada rareza N, R y SR. No son 912 personajes diferentes.
- 451 archivos Dart en `lib/features/clash` y 83 archivos de pruebas `*test.dart`.
- Catálogos JSON para historia, rivales, eventos, tienda, invocaciones, objetos, misiones y logros.
- Partido 7v7: posesión, pase, avance, regate contra defensa, tiro contra parada, defensa manual, IA rival, resistencia, puntos de técnica, descanso y objetivos. `MatchScore.winTarget` es 3: se termina al alcanzar tres goles.
- Colección, XP, escalado de atributos, árbol de habilidades y evolución N → R → SR. La tabla de evolución se declara provisional.
- El cálculo agregado de potencia suma cartas sin bonificación de formación ni estilos (`clash_team_power.dart`). La búsqueda en los dominios de equipo/cartas no encuentra un sistema de líder/enlaces comparable al objetivo propuesto: requiere diseño e implementación específicos.
- Guardado local, construcción/validación/aplicación de snapshots, cliente HTTP y servicios Spring de guardado y reclamaciones. La comprobación automática opcional descarga; no aplica ni sube automáticamente la partida.
- `ClashClaimService` registra reclamaciones idempotentes, pero declara explícitamente que no concede recompensas ni modifica la partida. No confundir con economía autoritativa completa.
- `ClashHomeHubGates.eventsUnlocked = false`: los eventos siguen bloqueados en el hub. Esto no demuestra un bloqueo global de Clash.

## Qué se ha comprobado funcionando

Se ejecutó `C:\src\flutter\bin\flutter.bat test test/features/clash/ --reporter compact` con Flutter 3.44.5 / Dart 3.12.2. Resumen del ejecutor: **765 aprobadas, 121 fallidas**; entre los fallos hay carga/compilación. No equivale a 121 fallos independientes de producto.

Ejemplos: `skip` textual donde `testWidgets` espera `bool?` en achievements; import de una pantalla de selección de modo inexistente en `clash_shell_test.dart`; expectativas de textos/jugadores que ya no coinciden con la UI o catálogo. No se ha clasificado ni corregido cada fallo. Las pruebas aprobadas verifican partes de la lógica y widgets, no una sesión completa Android ni el backend desplegado.

Flutter resolvió cinco dependencias transitivas diferentes al ejecutar las pruebas. Se revirtió exclusivamente ese cambio generado de `pubspec.lock` para conservar el original. El resultado corresponde a esa resolución local, no a una reproducción exacta del lock versionado. Log de ejecución: `%TEMP%\eternalxi-clash-tests-20261015.log`.

## Reutilización

1. **Directa, con validación:** identidades de jugador/carta, equipos, estadísticas, técnicas, textos, JSON, iconos, marcos, escudos, fondos y viñetas que estén completos y versionados. Preservar IDs para evitar romper relaciones y partidas.
2. **Como especificación:** fórmulas Dart, reglas de partido, progresión, probabilidades y pruebas. Reescribir en GDScript y comparar resultados con casos conocidos usando azar controlado.
3. **Con adaptación:** API Spring, autenticación y contratos JSON. Se conservan como servicio externo; su integración no es necesaria para validar el primer partido local.
4. **Rehacer:** widgets Flutter, Provider, navegación, almacenamiento SharedPreferences, integración Firebase y pantallas/animaciones. Godot no ejecuta directamente el cliente Dart.
5. **Partidas anteriores:** requieren exportador/adaptador versionado; Godot no hereda SharedPreferences automáticamente. Nunca sobrescribir la partida Flutter durante el prototipo.

## Arte: qué existe y qué falta

Hay 68 archivos en las subcarpetas epic: marcos, rarezas, posiciones, iconos, escudos, fondos y auras. Además existe el fondo del instituto y 62 imágenes en ep01–ep04, más referencias. La existencia de ficheros no certifica coherencia artística o que todo se use.

Las 912 cartas declaran `basicPortraitPath: network`; el widget resuelve retratos por playerId. El manifiesto estima 501.600.000 bytes de retratos: es una estimación del catálogo, no una descarga medida. Solo se localizaron cuatro imágenes bajo `equipos/`. No asumir que todos los retratos estén guardados localmente.

Se abrieron `04_clash_home.png`, `10_clash_inicio.png` y `11_clash_equipo.png` de mobile_reference_screenshots: muestran el launcher Android, no el juego. No sirven como prueba visual. Faltan capturas actuales fiables del hub, cartas y partido.

Dirección propuesta: fútbol anime 2D con identidad propia, retrato protagonista en carta, rareza legible, menos estadísticas simultáneas y colores consistentes por función. Campo táctico claro y animaciones cortas de pase, choque, tiro y parada; reservar efectos intensos para supertécnicas. Revisar recortes, transparencias, resolución y memoria antes de reutilizar cada imagen. Empezar con dos equipos y recursos locales; ampliar tras aprobar su apariencia en móvil.

## Jugabilidad propuesta (aún no implementada)

Conservar formación 7v7 y turnos tácticos. Bucle: formar equipo → elegir enfrentamiento → decidir pase/regate/tiro → resolver técnica con presentación visual → ganar materiales/XP → mejorar cartas → afrontar un rival distinto.

- Capitán con bonificación de equipo/categoría y enlaces entre jugadores compatibles. Mostrar qué activa cada bonificación.
- Posición, estilo, resistencia y técnica deben cambiar decisiones, no solo aumentar un número de potencia.
- Presentar coste, ventaja y riesgo antes de confirmar una acción; separar el resultado de la animación.
- Dos o tres acciones viables por turno, IA legible y contrajuego defensivo. Objetivo de diseño inicial: partidos de 3–5 minutos, a validar jugando.
- Progresión determinista suficiente para la demo: desbloquear una carta y mejorarla mediante victorias. Invocaciones con moneda de prueba en una fase posterior; sin pagos en la primera APK.
- Probar primero sinergias y ritmo; posponer PvP, eventos recurrentes y el catálogo completo. La referencia Dokkan orienta colección/progresión, no impone copiar sus pantallas o combate.

## Estructura Godot recomendada

Proyecto separado propuesto: `eternalclash_godot/`, sin mover ni sustituir `eternalxi_front/` o `eternalxi_api_back/`. Aún no creado.

- `data/`: subconjunto exportado de JSON y un manifiesto de contenido.
- `domain/`: reglas GDScript independientes de nodos visuales; RNG con semilla y casos de referencia.
- `services/`: catálogo, guardado local versionado y, más adelante, adaptador HTTP a Spring.
- `scenes/`: hub, colección, formación, preparación, partido y recompensas.
- `ui/`: carta y componentes compartidos; `art/` y `audio/` para recursos.

Usar escenas Control para interfaz, Node2D para campo y AnimationPlayer/Tween para acciones. Elegir inicialmente Compatibility para un prototipo 2D sencillo y medirlo en el Android objetivo antes de optar por efectos más exigentes. Mantener el guardado fuera de la presentación y escribirlo de forma segura con versión de esquema.

La migración debe ser incremental por sistemas, aunque ambos clientes permanezcan separados. No integrar Flutter dentro de Godot para la demo: añade dos navegaciones y dos ciclos de vida sin demostrar primero el partido.

## Camino a Android y criterios de avance

1. **Referencia reproducible:** clasificar fallos Flutter, conservar el original y obtener capturas auténticas. Validar IDs y referencias de contenido/arte.
2. **Prototipo Godot de partido:** dos equipos de siete, pase/regate/tiro/defensa, técnicas y victoria/derrota. Aceptación: partido completo con decisiones comprensibles y repetición determinista del mismo escenario.
3. **Bucle de progresión:** colección reducida, formación, recompensa, una mejora y guardado local. Aceptación: cerrar/reabrir conserva equipo y progreso, sin duplicar premios.
4. **Presentación:** una carta y una supertécnica terminadas como referencia, después extender el estilo. Aceptación: botones táctiles legibles, sin recortes en distintas proporciones y recursos sin conexión.
5. **APK de depuración:** instalar y jugar en Android real, medir arranque, memoria y fluidez; comprobar pausa/reanudación y modo avión. Objetivo inicial: 30 FPS estables en el teléfono elegido; registrar medición real. Entregar APK y pasos de instalación. No es todavía una publicación en Play.
6. **Solo después:** decidir migración completa, adaptar snapshots/API y convertir economía/probabilidades relevantes a autoridad de servidor si se añaden competición o compras.

No dar una fecha fiable de migración antes de medir el prototipo de partido y la preparación de los retratos.

Entorno comprobado: Flutter en `C:\src\flutter`, JDK 17 disponible y adb en el SDK Android del usuario. Godot no encontrado en PATH; no se ha descartado una instalación fuera de PATH. Export templates y paquetes SDK concretos pendientes de verificar para la versión de Godot elegida. Usar un applicationId de prototipo distinto, por ejemplo `es.eternalxi.clash.prototype`, para coexistir con la app original. Instalar Godot no produce por sí solo una APK.

Fuentes oficiales consultadas:
- https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html
- https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html
- https://docs.godotengine.org/en/stable/getting_started/first_2d_game/
