# Eternal Clash — RUPTURA 0.2

Prototipo Godot 4.7.2 / GDScript para probar una mecánica nueva de fútbol con cartas. El combate anterior de porcentajes se ha sustituido; el cliente Flutter y la API Spring originales no se modifican.

## Cómo jugar

La app **Eternal Clash Prueba** (`es.eternalxi.clash.prototype`) se juega en horizontal y no necesita conexión ni cuenta.

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

## Contenido y progreso

19 cartas iniciales de Eternal XI, 19 personajes de Bastion Adler en el catálogo rival, formación de siete editable entre partidos y mejoras locales. Todos los retratos están empaquetados.

100 monedas por victoria; 50 por empate/derrota. El capitán ensancha ligeramente su propia ventana de pulso; ya no existe el antiguo +6% global. El guardado incluye posiciones, huellas y duelos pendientes. Se conservan monedas, niveles y formación de la demo 0.1, pero su motor y su partida antigua no se usan en Ruptura.

## Compilar e instalar

Configurar Godot 4.7.2 estándar, export templates 4.7.2.stable, JDK 17 y SDK Android en Editor Settings → Export → Android. En la máquina de desarrollo ya están configurados.

Desde la raíz:

```powershell
./scripts/build_clash_godot.ps1
./scripts/build_clash_godot.ps1 -Install -DeviceId '<id de adb devices>'
```

APK debug ARM64: `releases/eternal-clash-prototype-0.2.0.apk`. Paquete separado de `es.eternalxi.app`; la instalación actualiza solo la demo. Añadir `-GodotPath` si el editor está en otra ubicación.

El script importa recursos y ejecuta ambos tests antes de exportar. Los APK, cachés y firmas quedan fuera de Git. Los datos y retratos están versionados; `scripts/export_clash_godot_content.ps1` permite reexportar el subconjunto del cliente original.

Pruebas por separado:

```powershell
& '<Godot_console.exe>' --headless --path eternalclash_godot --script tests/test_game.gd
& '<Godot_console.exe>' --headless --path eternalclash_godot --script tests/test_ui.gd
```

La primera valida 120 partidos con perfiles de decisiones/pulso distintos, rutas, señuelos, identidades de duelo, guardados y recompensa única. La segunda carga Inicio, Equipo, Cartas, campo, selección, duelo y resultado, incluyendo textos largos y límites de pantalla en 1600×720.

## Estado y límites

Prueba de jugabilidad, no juego final ni paridad con Flutter. Arte del catálogo reutilizado, animaciones de desplazamiento y sonidos breves; faltan cinemáticas, contenido narrativo jugable, adquisición de cartas, enlaces entre personajes por categorías, gacha, PvP, API y economía de servidor.

El campo es un tablero espacial de posesión: los jugadores no se mueven libremente en tiempo real. La intención de diseño es crear huecos y elegir rutas, con intervención manual en los momentos de choque. La diversión y dificultad necesitan la prueba del usuario; no se dan por demostradas por pasar tests. Sin medición de FPS o batería ni validación en otros teléfonos.

Ver `docs/CLASH_RUPTURE_DESIGN.md` y `docs/CURRENT_STATUS.md`. El primer prototipo 0.1 queda recuperable en Git (`8d98626`); su motor y UI se retiraron del proyecto activo.

Capturas reales: [campo](../docs/images/rupture_0_2/field.png), [señuelo](../docs/images/rupture_0_2/preview.png), [Thiago contra Magnus](../docs/images/rupture_0_2/duel.png) y [Hugo contra Ralf](../docs/images/rupture_0_2/defense.png).
