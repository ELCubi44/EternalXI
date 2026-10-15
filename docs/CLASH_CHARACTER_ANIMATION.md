# Personajes y supertécnicas reutilizables — prueba 0.4

2026-10-15. Objetivo: probar un personaje de cuerpo completo y una técnica reutilizable como base del futuro acabado anime.

## Construido

- `football_actor.gd`: figura 3D de geometría sencilla articulada mediante una jerarquía estable de nodos: cadera, torso, cabeza, hombros, codos, piernas y rodillas. Volúmenes para cara, ojos, pelo, equipación y botas. Las referencias son los retratos existentes, no un escaneado automático de una foto.
- Apariencias provisionales de Thiago (434: castaño, azul y brazalete), Miguel (444: pelo oscuro/mechón gris y azul) y Hugo (435: pelo verde, cinta/equipación roja y guantes).
- `super_motion.gd`: una `AnimationLibrary` compartida con pistas de rotación y poses clave. Las rutas son iguales para todas las apariencias. Disparo Valestia tiene concentración, preparación, patada y recuperación. Hay además movimientos provisionales de giro para regate y brazos para parada.
- `super_cinematic.gd`: mundo aislado en `SubViewport`, cámara, balón, estadio sencillo, anillos y estelas. Resolución máxima de 540 px de ancho, proporcional al formato vertical. Duraciones: tiro 5,2 s; regate 4,2 s; parada 4,4 s.
- La escena recibe personaje y técnica. Quien aún no tiene apariencia propia conserva la presentación anterior de retrato; no se le asigna el cuerpo de Thiago.
- Inicio → **Ver supertécnicas** permite comparar Valestia con Thiago/Miguel y repetir Eclipse/Muro. No gasta PT ni modifica partida, técnicas aprendidas o progreso. Miguel muestra Valestia solo como demostración, no lo aprende en el juego.
- El partido usa las mismas escenas al activar una técnica compatible. Se mantienen descuento/guardado previo y duelo manual posterior; la presentación no determina el resultado.

## Alcance y siguiente paso

Se demuestra la separación entre apariencia y movimiento con dos personajes que usan las mismas pistas. Son figuras de prueba: el parecido facial y el acabado anime son limitados. No están modelados los 304 jugadores ni existe una coreografía individual para cada técnica del catálogo.

El rig actual articula piezas rígidas con nodos; todavía no es una malla orgánica con pesos y `Skeleton3D`. Para producción habrá que preparar un modelo base más trabajado en una herramienta 3D, con articulaciones/deformación correctas, personalizar cabeza/pelo/ropa y exportar a GLB. Se conserva el contrato «técnica + personaje», adaptando las pistas al esqueleto definitivo. Pendientes expresiones, manos/pies, contacto preciso del balón, efectos, cámaras y sonido por fases.

Las variaciones de altura/complexión requieren adaptar las animaciones. Un modelo externo no es compatible automáticamente: se pueden definir familias de cuerpos compatibles. No se usan vídeos distintos por jugador ni servicios de IA durante la partida.

## Validación

El build ejecuta `test_game.gd`, `test_ui.gd` y `test_cinematic.gd`. Esta última comprueba la patada con dos apariencias, articulaciones, salida del balón, resolución acotada, regate/parada, señal de fin única y liberación. La UI comprueba también que el visor no modifica el perfil.

Para capturar fotogramas con el renderer real de escritorio, crear antes la carpeta destino:

```powershell
& '<Godot_console.exe>' --path eternalclash_godot --script tests/test_cinematic.gd -- --capture='C:/ruta/capturas'
```

Android ZTE A7050: visor, Valestia con ambas apariencias y presentación defensiva, con retorno al visor. La primera apertura tarda más que las siguientes. Pendiente medir FPS, arranque, memoria y batería; las capturas no miden fluidez. Flutter y API originales conservados.
