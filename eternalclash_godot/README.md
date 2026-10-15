# Eternal Clash — RUPTURA 0.3

Prototipo Godot 4.7.2 / GDScript para probar una mecánica nueva de fútbol con cartas. El combate anterior de porcentajes se ha sustituido; el cliente Flutter y la API Spring originales no se modifican.

## Cómo jugar

La app **Eternal Clash Prueba** (`es.eternalxi.clash.prototype`) se juega en vertical y no necesita conexión ni cuenta.

1. Elige una carta: **Pase**, **Pared** o **Señuelo**.
2. Toca al compañero en el campo. La ruta y el nombre del posible interceptor se muestran antes de actuar.
3. Pulsa **Ejecutar**. Un pase libre llega sin sorteo; una ruta marcada abre un duelo contra el defensor señalado.
4. Para rematar, elige **Tiro**. Está disponible al avanzar suficientemente por el campo o al cargar una Ruptura.

Cada ataque tiene seis pulsos. Pase, Señuelo y Tiro consumen uno; Pared consume dos.

- **Pase:** cambia el poseedor. Las marcas reaccionan al lugar que acaba de abandonar el balón, no a una tirada de probabilidad.
- **Pared:** un compañero devuelve el balón mientras el pasador avanza. Cuesta más, pero permite ganar profundidad sin cambiar al poseedor final.
- **Señuelo:** el compañero corre hacia una banda y arrastra a su marcador. No cambia al poseedor. Las flechas de previsualización muestran ambos movimientos.
- **Ruptura:** conectar tres identidades distintas, abrir de una banda a otra y ganar profundidad permite un remate combinado desde la mitad ofensiva, con una ventana de pulso mayor. Pasar hacia atrás repetidamente no basta.

Ejemplo de aprendizaje en la posición inicial: elegir Señuelo y tocar a Andrés arrastra a Till y libera el pase hacia Alejandro. Esa apertura está comprobada en las pruebas de reglas.

## Duelos: leer y ejecutar

Se muestran ambos nombres completos, retratos, técnicas e intención rival. No hay dados.

Atacando: Potencia contra quien espera, Efecto contra quien cierra y Amago contra quien presiona. El enfoque correcto ensancha la zona verde; los atributos, nivel, capitán y enlaces también influyen en su tamaño. Después hay que pulsar cuando la aguja cruza la zona. El oro central es un pulso perfecto.

Defendiendo: controlas al portero contra un atacante identificado. Bloquear responde al tiro potente, Estirarse a la escuadra y Aguantar al amago. La resolución también es manual.

Hay siete segundos después de activar la aguja; agotarlos equivale a perder el duelo. Un gol o una posesión agotada dan paso al contraataque rival. Primero a tres goles o máximo seis rondas de ataque y defensa; entonces se compara el marcador.

## Supertécnicas activables

El botón morado **SÚPER**, abajo a la derecha, abre las técnicas reales del poseedor y explica coste y condiciones. Hay 60 PT al empezar, con máximo 100. Se recargan con Pase (+8), Pared (+12), Señuelo (+5), pulso perfecto (+5) y nueva ronda (+10).

- **Regate del Eclipse**, de Thiago: 27 PT y un pulso. Abre un duelo de regate reforzado; si se gana, avanza y deja atrás a la marca.
- **Disparo Valestia**, de Thiago: 30 PT y un pulso. Se puede lanzar al ganar terreno (o con Ruptura), con una zona de acierto mayor. También puede activarse en un duelo de tiro normal antes de elegir enfoque.
- **Muro de Puños**, de Hugo: 24 PT en el duelo defensivo, antes de elegir enfoque. Refuerza la parada sin gastar otro pulso de ataque.

Cada técnica tiene una presentación animada de dos segundos con su nombre y retrato: ecos y aura para regate, balón con estela para tiro y arco de escudo para parada. Después se resuelve el duelo manual; activar una técnica no garantiza acertar. La potencia del catálogo aumenta la ventana de acierto.

El coste general es `max(20, ptCost × 3)`. No se descuenta otra vez al reabrir ni se permite activar dos técnicas sobre un mismo duelo. Las técnicas no compatibles con la fase aparecen deshabilitadas con su motivo. Las técnicas de defensa de jugadores de campo aún no tienen una fase manual propia.

## Contenido y progreso

19 cartas iniciales de Eternal XI, 19 personajes de Bastion Adler en el catálogo rival, formación de siete editable entre partidos y mejoras locales. Todos los retratos están empaquetados.

100 monedas por victoria; 50 por empate/derrota. Las partidas 0.2 reciben 60 PT al cargarse y conservan posiciones, marcador, monedas y niveles. El capitán ensancha ligeramente su propia ventana de pulso; ya no existe el antiguo +6% global. El guardado incluye posiciones, huellas y duelos pendientes. Se conservan monedas, niveles y formación de la demo 0.1, pero su motor y su partida antigua no se usan en Ruptura.

## Compilar e instalar

Configurar Godot 4.7.2 estándar, export templates 4.7.2.stable, JDK 17 y SDK Android en Editor Settings → Export → Android. En la máquina de desarrollo ya están configurados.

Desde la raíz:

```powershell
./scripts/build_clash_godot.ps1
./scripts/build_clash_godot.ps1 -Install -DeviceId '<id de adb devices>'
```

APK debug ARM64: `releases/eternal-clash-prototype-0.3.0.apk`. Paquete separado de `es.eternalxi.app`; la instalación actualiza solo la demo. Añadir `-GodotPath` si el editor está en otra ubicación.

El script importa recursos y ejecuta ambos tests antes de exportar. Los APK, cachés y firmas quedan fuera de Git. Los datos y retratos están versionados; `scripts/export_clash_godot_content.ps1` permite reexportar el subconjunto del cliente original.

Pruebas por separado:

```powershell
& '<Godot_console.exe>' --headless --path eternalclash_godot --script tests/test_game.gd
& '<Godot_console.exe>' --headless --path eternalclash_godot --script tests/test_ui.gd
```

La primera valida 120 partidos con perfiles de decisiones/pulso distintos, rutas, señuelos, identidades de duelo, guardados y recompensa única. La segunda carga Inicio, Equipo, Cartas, campo, selección, duelo y resultado, incluyendo textos largos y límites de pantalla en 720×1600.

## Estado y límites

Prueba de jugabilidad, no juego final ni paridad con Flutter. Arte del catálogo reutilizado, animaciones de desplazamiento y sonidos breves; faltan animaciones de personajes con acabado final, contenido narrativo jugable, adquisición de cartas, enlaces entre personajes por categorías, gacha, PvP, API y economía de servidor.

El campo vertical ocupa más del 70% de la altura, con ataque hacia arriba, líneas contrastadas y retratos recortados dentro de círculos de equipo. Los controles quedan abajo. El campo es un tablero espacial de posesión: los jugadores no se mueven libremente en tiempo real. La intención de diseño es crear huecos y elegir rutas, con intervención manual en los momentos de choque. La diversión y dificultad necesitan la prueba del usuario; no se dan por demostradas por pasar tests. Sin medición de FPS o batería ni validación en otros teléfonos.

Ver `docs/CLASH_RUPTURE_DESIGN.md` y `docs/CURRENT_STATUS.md`. El primer prototipo 0.1 queda recuperable en Git (`8d98626`); su motor y UI se retiraron del proyecto activo.

Capturas históricas 0.2: [campo](../docs/images/rupture_0_2/field.png), [señuelo](../docs/images/rupture_0_2/preview.png), [Thiago contra Magnus](../docs/images/rupture_0_2/duel.png) y [Hugo contra Ralf](../docs/images/rupture_0_2/defense.png).

Capturas reales de 0.3: `docs/images/rupture_0_3/` (campo vertical, menú SÚPER, Regate del Eclipse, Disparo Valestia, Muro de Puños y resultado). Las capturas 0.2 enlazadas arriba son históricas del diseño horizontal.
