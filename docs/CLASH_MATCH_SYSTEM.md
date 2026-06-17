# Eternal Clash — Sistema de partido y combate

> **Estado:** diseño + **Fase 7 implementada** (shell base 7vs7, flujo provisional).  
> **Relacionado:** `CLASH_CARD_SYSTEM.md`, `CLASH_STORY_AND_EVENTS.md`

---

## Implementación Fase 7 (Flutter)

La **Fase 7** entrega solo la **base del partido** y el flujo tutorial del primer nivel match (`chapter_01_level_04`):

| Incluido | Pendiente (fases posteriores) |
|---|---|
| Pantalla de preparación (`/clash/story/level/:id/prepare`) | Motor real de pases y avance |
| Pantalla de partido (`/clash/match/:id`) | Duelos regate/defensa |
| Sorteo cara/cruz y saque inicial | Tiro/parada |
| Marcador primero a 3 goles | Supertécnicas y PT |
| Minicampo abstracto `ClashMiniPitch` | IA completa del rival |
| Botones **provisional tutorial/dev** «Gol Eternal XI» / «Gol Rival» | Gameplay definitivo completo |
| Duelos Regate vs Defensa al avanzar (Fase 9) | |

Los botones de gol simulado existen únicamente para validar victoria/derrota, recompensas y progresión. **No** representan el gameplay final.

---

## Implementación Fase 8 (Flutter)

La **Fase 8** añade el primer sistema **real de posesión** en el 7vs7:

| Incluido | Pendiente (fases posteriores) |
|---|---|
| Zonas lógicas del balón (`ownDefense` … `rivalArea`) | Tiro y parada |
| Acciones **Pasar** y **Avanzar** (duelo si hay defensor) | Supertécnicas y PT en duelos |
| Resistencia actual por jugador en partido | IA rival completa |
| Presión y riesgo de posesión | Objetos de descanso |
| Historial breve de eventos | Física real del minicampo |
| IA rival **provisional** (simular acción) | |
| Duelos Regate vs Defensa (Fase 9) | |

Fórmulas de pase/avance son **provisionales** y se afinarán cuando existan duelos. Los botones de gol dev siguen en sección plegable separada.

---

## Implementación Fase 9 (Flutter)

La **Fase 9** sustituye el avance directo por probabilidad por **duelos normales Regate vs Defensa** cuando hay un defensor rival cercano:

| Incluido | Pendiente (fases posteriores) |
|---|---|
| Dominio `ClashDuelState`, participantes y resolución | Supertécnicas y consumo de PT |
| Avanzar → defensor rival → duelo pendiente → «Regate normal» | Tiro y parada |
| Fórmula Regate vs Defensa con ventaja de estilo (+8) | IA rival completa |
| Empate exacto resuelto por moneda (verde=usuario, rojo=rival) | Objetos de descanso, faltas, rechaces |
| Panel de duelo en `ClashMatchScreen` | Gacha/tienda/evolución/árbol |
| Minicampo destaca atacante/defensor y enlace visual | |
| Fallback de avance libre sin defensor (zonas propias) | |
| Resistencia efectiva en stats de duelo | |

**Avanzar** ya no calcula probabilidad directa cuando hay defensor: crea un duelo pendiente. Las supertécnicas y el gasto de PT llegarán en fases posteriores. El rival provisional sigue usando avance directo en `executeRivalTurn`.

---

## Implementación Fase 10 (Flutter)

La **Fase 10** cierra el **ciclo básico del partido** con duelos **Tiro vs Parada** en zona de remate:

| Incluido | Pendiente (fases posteriores) |
|---|---|
| `ClashDuelType.shotVsSave` reutilizando dominio de duelo | Supertécnicas y consumo de PT |
| Acción **Tirar** en `rivalArea` (usuario) | Rechaces y córners |
| Duelo pendiente → «Tiro normal» → GOL o PARADA | Objetos de descanso, faltas |
| Fórmula Tiro vs Parada (+8 estilo, +4 área, presión) | IA rival completa |
| Gol suma marcador; saque al equipo que encajó | Gacha/tienda/evolución |
| Parada cede posesión al portero | |
| Primero a 3 goles finaliza partido (victoria/recompensas existentes) | |
| Rival provisional puede disparar en `ownDefense` | |
| Minicampo destaca tirador/portero y línea a portería | |

El ciclo **posesión → pasar → avanzar → regate/defensa → tirar → gol/parada** ya permite marcar sin botones dev. Los botones de gol en la sección plegable son **temporales** y se eliminarán en fases posteriores.

---

## 1. Visión general

Clash tiene **dos modalidades de partido**:

| Modo | Jugadores | Interacción | Uso principal |
|---|---|---|---|
| **7vs7 interactivo** | 7 por equipo | Usuario decide en duelos clave | Historia temprana, eventos, desafíos, pachangas |
| **11vs11 simulado** | 11 por equipo | Sin intervención directa | Historia avanzada, partidos épicos |

Ambos comparten stats, estilos, supertécnicas, resistencia, PT y potencia, pero solo el 7vs7 expone la capa de decisión táctica descrita aquí.

---

## 2. Formaciones y posiciones

### 2.1 Posiciones válidas (7vs7 y 11vs11)

Solo existen estas **7 posiciones**, cada una **obligatoria y no repetible** en una alineación de 7:

| Posición |
|---|
| Portero |
| Defensa central |
| Lateral |
| Mediocentro atrasado |
| Mediocentro ofensivo |
| Extremo |
| Delantero centro |

**No hay restricción de estilos** en ninguna formación.

### 2.2 Equipo 7vs7

- El usuario configura **exactamente 7 cartas**, una por posición.
- Es el modo de combate **interactivo** principal.
- Gana el primero en llegar a **3 goles**.

### 2.3 Equipo 11vs11

| Aspecto | Regla |
|---|---|
| Jugadores en campo | 11 (portero + 10 de campo según alineación) |
| Posiciones usadas | Subconjunto de las 7 posiciones base, repetidas según formación |
| Alineaciones | **Varias desbloqueables** (4-3-3 y variantes) |
| Desbloqueo | Al avanzar en **historia**; cada **equipo importante** entrega una alineación |
| Final historia | **Todas** las alineaciones desbloqueadas |
| Rivales | Variantes de **4-3-3**; algunos con **2 mediocentros ofensivos**, otros con **2 mediocentros atrasados** |
| Simulación | **Sin intervención** del usuario; resultado calculado por motor |

Detalle de stats efectivas en 11vs11 (¿misma carta, mismos valores?): se asume misma carta del usuario; cálculo agregado por líneas — pendiente de fórmula.

---

## 3. Flujo del partido 7vs7

### 3.1 Condición de victoria

**Primero en marcar 3 goles** gana. No hay prórroga en diseño inicial.

### 3.2 Sorteo inicial

Antes del partido:

1. Usuario elige **cara o cruz**.
2. Si **gana** el sorteo → **saca su equipo**.
3. Si **pierde** → **saca el rival**.

### 3.3 Saque tras gol

Después de cada gol, **saca el equipo que recibió el gol** (regla tipo baloncesto/futsal adaptada).

### 3.4 Posesión continua

**No existen jugadas predefinidas.** La posesión fluye hasta que ocurre un evento terminal:

| Evento | Efecto |
|---|---|
| **Gol** | +1 marcador; saque equipo encajado |
| **Robo** | Cambio de posesión |
| **Pérdida** | Cambio de posesión |
| **Parada** | Cambio de posesión (portero) |
| **Fuera** | Cambio de posesión (saque rival) |
| **Falta** | Cambio de posesión o situación según zona (detalle: pendiente) |

Entre eventos terminales, el usuario (y la IA) elige acciones con balón o se resuelven duelos.

### 3.5 Descansos

Entre periodos (cantidad de periodos: pendiente — propuesta: 2 partes o 4 cuartos):

- Pausa de gameplay interactivo.
- **Único momento** para usar **objetos de partido** (PT, resistencia).
- Posible inserción de **escena cómic** narrativa (ver `CLASH_STORY_AND_EVENTS.md`).

---

## 4. Minicampo

### 4.1 Requisitos de UI

Durante todo el 7vs7 interactivo, **arriba de la pantalla**:

| Elemento | Función |
|---|---|
| Campo reducido | Orientación espacial |
| Puntos por jugador | Posición actual |
| Balón | Ubicación del balón |
| Movimientos | Feedback de avances y pases |

### 4.2 Propósito

- Entender **pases** (distancia, líneas).
- Ver **avances** y acercamiento de defensas.
- Identificar **entrada al área** de finalización.
- Leer **presión** e intercepciones rivales.

Representación abstracta (no simulación física completa). Estilo visual: pendiente.

---

## 5. Acciones con balón

### 5.1 Acciones disponibles

| Acción | Cuándo |
|---|---|
| **Pasar** | Siempre con balón (salvo estados especiales) |
| **Avanzar** | Con balón; puede provocar duelo defensivo |
| **Tirar** | **Solo** al llegar a **zona de finalización** (área) |

### 5.2 Supertécnicas vs acciones

- Las supertécnicas **no son acciones libres** en el menú principal.
- Solo aparecen **dentro de duelos** (avance o área).
- Las acciones **normales** (pase, regate normal, tiro normal, parada/defensa normal) **no consumen PT**.

---

## 6. Resolución al avanzar

### 6.1 Acercamiento defensor

Al elegir **Avanzar**:

1. Puede **acercarse un defensor rival** (según posición, IA, minicampo).
2. Comienza **duelo**.

### 6.2 Duelo ofensivo vs defensivo

| Rol | Opciones |
|---|---|
| **Atacante** | Regate normal **o** supertécnica de **Regate** (si PT suficientes) |
| **Defensor** | Defensa normal **o** supertécnica de **Defensa** (si PT suficientes) |

Si no hay defensor inmediato, el avance actualiza posiciones en minicampo sin duelo (hasta encontrar presión o área).

---

## 7. Resolución en el área (finalización)

Al entrar en **zona de finalización**:

| Rol | Opciones |
|---|---|
| **Atacante** | Tiro normal **o** supertécnica de **Tiro** |
| **Portero** | Parada normal **o** supertécnica de **Parada** |

Resultado posible: **gol** (evento terminal) o **parada** / **fuera** (cambio de posesión).

---

## 8. Sistema de duelos

### 8.1 Resolución básica

1. Cada lado elige acción (normal o supertécnica).
2. Ambos generan una **puntuación** derivada de:
   - Stat relevante (Regate, Defensa, Tiro, Parada).
   - Potencia de supertécnica (si aplica).
   - Modificador de **estilo** (ventaja en rueda).
   - **Resistencia actual** del jugador.
   - Otros modificadores de contexto (pendiente).
3. **Gana el mayor.** No hay rechaces ni resultados intermedios en diseño inicial.

### 8.2 Empate exacto

Si las puntuaciones son **idénticas**:

1. Animación de **moneda**.
2. **Cara verde** → gana el **usuario**.
3. **Cara roja** → gana el **rival**.

(Esto favorece ligeramente al jugador humano en empates perfectos.)

### 8.3 Acciones normales

Dependen de la **estadística correspondiente** del jugador:

| Acción normal | Stat base |
|---|---|
| Regate normal | Regate |
| Defensa normal | Defensa |
| Tiro normal | Tiro |
| Parada normal | Parada |

**No consumen PT.**

---

## 9. Sistema de pases

El pase **no es un duelo 1v1**; es una **probabilidad de éxito** calculada.

### 9.1 Factores de la probabilidad

| Factor | Influencia |
|---|---|
| **Pase efectivo** del pasador | Stat Pase × resistencia actual |
| **Calidad del receptor** | Stats relevantes del destinatario |
| **Distancia** | Mayor distancia → más difícil |
| **Zona del campo** | Zonas peligrosas / congestionadas penalizan |
| **Líneas rivales atravesadas** | Más líneas → más difícil |
| **Presión e intercepción** | Todos los rivales relevantes en trayectoria |
| **Potencia global** | Comparativa de equipos |
| **Resistencia actual** | Pasador y receptor |
| **Posición en minicampo** | Geometría del pase |

### 9.2 Regla de diseño clave

Un **pase directo de defensa a delantero** debe ser **difícil** salvo **gran superioridad** (potencia/stats/resistencia).

### 9.3 Resultados de pase

| Resultado | Efecto |
|---|---|
| Éxito | Balón al receptor; puede continuar acción |
| Interceptado | Robo / pérdida |
| Fallo | Pérdida o duelo secundario (pendiente: solo pérdida en v1) |

No hay supertécnica de pase.

---

## 10. Resistencia y PT en partido

### 10.1 Resistencia

| Regla | Detalle |
|---|---|
| Inicio | Valor base de carta (~100 mínimo, ~130 XI) |
| Durante partido | **Disminuye** con acciones y tiempo |
| ≥ 100 | Sin penalización a stats |
| < 100 | Penaliza Pase, Regate, Tiro, Defensa, Parada efectivos |
| Tras gol | **No** se recupera |
| Descanso | Objetos de resistencia |

Curva exacta de penalización: pendiente (propuesta: lineal o escalonada suave).

### 10.2 PT

| Regla | Detalle |
|---|---|
| Inicio | PT máximos de cada jugador |
| Uso | Solo supertécnicas |
| Recuperación automática | **No** |
| Descanso | Objetos de PT |

---

## 11. Objetos de partido (descanso)

**Solo utilizables en el descanso.**

| Tipo | Efecto |
|---|---|
| PT — un jugador | Recupera PT de un jugador |
| PT — tres jugadores | Recupera PT de tres jugadores |
| PT — equipo (poco) | Recupera pocos PT de todo el equipo |
| Resistencia — un jugador | Recupera resistencia de un jugador |
| Resistencia — varios | Recupera resistencia de varios jugadores |
| Resistencia — equipo (poco) | Recupera poca resistencia de todo el equipo |

Cantidades exactas y límites de inventario en partido: pendiente.

---

## 12. Partido 11vs11 simulado

### 12.1 Flujo

1. Usuario selecciona alineación 11vs11 desbloqueada.
2. Pantalla de preview: potencias, formación rival.
3. Simulación automática (animación resumen opcional).
4. Resultado: marcador, goleadores abstractos, recompensas.

### 12.2 Motor (orientación)

Inputs propuestos:

- Potencia por línea (DEF, MID, ATT).
- Stats agregadas por zona.
- Rareza media y niveles del XI rival.
- Ventaja local / narrativa del nivel.

**Sin** elección de acciones del usuario.

### 12.3 Rivales

- Formaciones tipo **4-3-3** con variaciones:
  - 2 mediocentros ofensivos.
  - 2 mediocentros atrasados.
- Stats y rarezas definidas por diseño de nivel.

---

## 13. Inteligencia artificial

### 13.1 Principios

| Principio | Regla |
|---|---|
| Calidad | La IA **siempre será inteligente** — no habrá IA deliberadamente mala |
| Dificultad | Escala por nivel de cartas rivales, rareza, stats, nivel de supertécnicas, composición |
| Cartas altas | Si la IA usa SR, LR o XI → **árbol completamente desbloqueado** |
| Recursos | La IA **administra PT** y elige supertécnicas con lógica |
| Estilos | Considera ventajas de estilo en duelos |

### 13.2 Comportamientos mínimos

- Pasar vs avanzar según presión y distancia a área.
- Activar supertécnica cuando PT lo permita y el duelo sea crítico.
- Conservar PT en ventaja amplia (opcional, pendiente tuning).
- Defensor correcto según minicampo.
- No spamear pases imposibles defensa→delantero sin ventaja.

### 13.3 Implementación futura

Capa `ClashAiController` en `features/clash/` — sin acoplar a Fantasy.

---

## 14. Potencia en contexto de partido

Fuera de partido (ver `CLASH_CARD_SYSTEM.md`):

- Potencia recomendada del nivel vs potencia del equipo del usuario.
- **Advertencia** si ratio bajo; **nunca bloqueo**.

En partido:

- La potencia global modifica **probabilidad de pase** y puede actuar como tie-breaker suave en duelos (pendiente de confirmar magnitud).

---

## 15. Integración narrativa en partido

- El partido puede **pausarse** para escenas cómic activadas por eventos narrativos (gol, tarjeta, trama).
- Tras escena, se reanuda el estado de partido.

Detalle: `CLASH_STORY_AND_EVENTS.md`.

---

## 16. Estados de partido (modelo conceptual)

```
MatchState
├── score (home, away)
├── possession (team, ballCarrier, fieldZone)
├── players[] (position, resistanceCurrent, ptCurrent, onField)
├── period
├── kickoffTeam
└── narrativeFlags
```

Persistencia de partido pausado (mid-match exit): pendiente (recomendado para móvil).

---

## 17. Decisiones pendientes

| Tema | Estado |
|---|---|
| Número de periodos / duración simbólica | Pendiente |
| Reglas exactas de falta y saques | Pendiente |
| Fórmula numérica de duelos | Pendiente |
| Fórmula probabilidad de pase | Pendiente |
| Penalización resistencia < 100 (%) | Pendiente |
| Animaciones y tiempos de feedback | Pendiente |
| Fórmula simulación 11vs11 | Pendiente |
| ¿Empate en pase fallido vs interceptado? | Pendiente |
| Persistencia partido en curso | Pendiente |
