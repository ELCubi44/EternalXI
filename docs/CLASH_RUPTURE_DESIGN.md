# RUPTURA — rediseño de la jugabilidad

Fecha: 2026-10-15. Estado: implementado como prototipo Android 0.2, pendiente de valoración del usuario.

## Problema que motivó el cambio

El usuario probó la demo 0.1 y la encontró poco divertida: campo pequeño, duelos sin rival claro y acciones demasiado parecidas a pulsar un botón y esperar. Se abandona ese combate, no se intenta justificarlo ni maquillarlo.

## Identidad de la propuesta

**Engañar a una defensa mediante la huella que deja el balón.** El equipo es una red de opciones espaciales, no una suma de estadísticas. El usuario elige a quién pasa, quién devuelve una pared y quién arrastra a su marcador. El campo muestra las rutas y quién puede cortarlas antes de confirmar.

No se afirma exclusividad respecto a otros juegos. Es la dirección de diseño propia que se quiere validar para Eternal Clash.

## Una posesión

1. Se ven siete jugadores de cada equipo en un campo horizontal grande. El poseedor y el receptor seleccionado se destacan. Las flechas anuncian el compromiso de las marcas tras el pase.
2. El usuario selecciona una carta de acción y toca al compañero. Pase cambia al poseedor; Pared devuelve y hace avanzar al pasador; Señuelo desplaza al compañero y a su marcador, dejando el balón donde estaba.
3. La previsualización identifica al interceptor real. Si la ruta está libre, el pase llega sin azar. Si está marcada, se abre un duelo contra ese defensor.
4. Las rutas anteriores permanecen dibujadas. Tres identidades enlazadas, amplitud y profundidad cargan una Ruptura. No basta repetir un pase fácil hacia atrás.
5. Un tiro abre un duelo contra Magnus. Una Ruptura permite rematar desde la mitad ofensiva y amplía la zona de acierto.
6. El rival contraataca y el usuario controla al portero: se identifica al tirador y su intención, se elige la respuesta y se interviene en el pulso.

Seis pulsos limitan cada posesión. Pared cuesta dos; las otras acciones uno. Máximo seis rondas completas, con final anticipado al alcanzar tres goles.

## Por qué tomar una decisión

- Pasar al jugador de mejor tiro puede exponer una ruta interceptada.
- Un señuelo consume tiempo, pero transforma una ruta disputada en una libre. Caso de referencia: Andrés atrae a Till y libera a Alejandro.
- Una pared gana profundidad y conserva al buen regateador/rematador, a cambio de dos pulsos.
- Cambiar de banda y enlazar identidades prepara un remate más fácil de ejecutar, pero exige construir una jugada.
- Rematar antes evita agotar la posesión, con una ventana de acierto menor que una Ruptura.
- El usuario puede superar una mala ruta en un duelo de habilidad; no se oculta el choque detrás de un porcentaje.

## Duelos legibles

Retrato, nombre y técnica de ambos personajes; intención anunciada y reglas de respuesta visibles.

Atacando: Potencia rompe la espera, Efecto rodea el cierre y Amago castiga la presión. Defendiendo: Bloquear ante potencia, Estirarse ante escuadra y Aguantar ante amago. La lectura correcta aumenta la zona verde, pero todavía hay que ejecutar el gesto. La aguja cambia de velocidad por ronda/intención y tiene un límite de siete segundos.

No hay números aleatorios en el motor. Mismo estado, enfoque y precisión producen el mismo resultado. Se persisten también los duelos pendientes; reabrir devuelve a la selección del enfoque para no penalizar una interrupción del móvil.

## Implementación

- `rupture_engine.gd`: geometría, huellas, consumo de pulsos, señuelos, cadenas, fases y resolución de duelos.
- `rupture_pitch.gd`: campo, jugadores identificados, rutas, intenciones y animación entre posiciones.
- `rupture_app.gd`: cartas de acción, selección táctil, rivales visibles, duelos y navegación horizontal.
- `pulse_gauge.gd`: intervención temporal del usuario.
- `profile.gd`: progreso local, guardado con backup y serialización de precisión completa.

Se han retirado los scripts activos del combate 0.1. Se conservan su historial Git, el catálogo, retratos, fondos, formación, monedas y niveles. Flutter y Spring permanecen separados y sin cambios.

## Qué medir al probar

La prioridad es observar si el usuario ve una apertura, entiende a quién está arrastrando y quiere probar una segunda ruta. Después: legibilidad, tamaño de blancos táctiles, velocidad de duelos y repetición de la estrategia dominante.

Todavía faltan variedad de disposiciones rivales, más conductas de defensa, mejores transiciones de gol y evaluación de dificultad. Las posiciones base alternan de banda entre rondas; no son todavía una campaña de escenarios. La lectura y el pulso necesitan pruebas humanas: los tests no prueban diversión.
