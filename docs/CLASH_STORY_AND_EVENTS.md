# Eternal Clash — Historia, eventos y contenido

> **Estado:** diseño pre-implementación.  
> **Relacionado:** `CLASH_PRODUCT_DESIGN.md`, `CLASH_MATCH_SYSTEM.md`, `CLASH_CARD_SYSTEM.md`

---

## 1. Historia como eje principal

La **Historia** es el **modo central de progresión** en Eternal Clash. Todos los demás sistemas (equipo, gacha, tienda, desafíos) orbitan alrededor del avance narrativo y de la potencia que la historia exige.

### 1.1 Estructura macro

Organización propuesta (contenido concreto pendiente):

```
Saga / Arco
 └── Capítulo (equipo rival o trama)
      └── Nivel (unidad jugable o narrativa)
           ├── Pre-cómic (opcional)
           ├── Gameplay (7vs7, 11vs11 o mixto)
           ├── Mid-cómic (opcional, pausa partido)
           └── Post-cómic (opcional)
```

- Cada **equipo importante** de la trama puede:
  - Entregar **drops** de cartas N de sus jugadores.
  - Desbloquear una **alineación 11vs11** al completar su arco.
- Al **terminar la historia completa**, el usuario tiene **todas las alineaciones 11vs11** desbloqueadas.

---

## 2. Tipos de nivel

| Tipo | Gameplay | Recompensa |
|---|---|---|
| **Solo historia** | Sin partido; escenas cómic + diálogo | **Equivalente a un nivel normal** (misma tabla de recompensas base) |
| **Jugable** | Partido 7vs7 o 11vs11 | Recompensas estándar + primera clear |
| **Mixto** | Cómic + partido + cómic | Suma de ambos; puede incluir pausas narrativas mid-match |

### 2.1 Partidos importantes multi-nivel

Los encuentros clave (finales de arco, clásicos narrativos) pueden **dividirse en varios niveles** consecutivos:

- Nivel 1: intro cómic + primer tiempo / primer duelo.
- Nivel 2: continuación o segundo acto.
- Nivel 3: resolución + post-cómic.

Permite picos de dificultad y storytelling sin partidas excesivamente largas en una sola sesión.

### 2.2 Consumo de energía

**Todos** los tipos de nivel consumen **energía** (incluidos solo historia y narrativos puros), salvo excepciones de tutorial inicial (pendiente).

### 2.3 Requisitos narrativos de plantilla y cartas invitadas

Algunas fases de **Historia** pueden exigir **jugadores concretos en posiciones concretas**. Estas restricciones existen para mantener coherencia narrativa y activar cinemáticas.

| Regla | Detalle |
|---|---|
| Obligatoriedad | El diseño de la fase puede requerir un personaje concreto en una posición concreta |
| Sin carta en colección | Si el usuario **no posee** la carta obligatoria, la fase puede **prestar una carta invitada temporal** |
| Alcance de la invitada | Solo sirve para **esa fase**; no se añade a la colección permanente |
| Coherencia | Las cinemáticas y escenas cómic asociadas pueden depender de esa presencia en el campo |

### 2.4 Activación de escenas y cinemáticas (fases futuras)

Las escenas podrán activarse en distintos momentos del flujo narrativo o de partido. **No implementado en partidos en la fase actual**; el modelo de datos ya contempla `trigger` en escenas y requisitos de plantilla para prepararlo.

| Momento / condición | Uso previsto |
|---|---|
| Antes del partido | Contexto, presentación rival |
| Durante el partido | Pausa por eventos narrativos |
| Tras gol | Reacción o giro de trama |
| Por marcador | Escena condicionada al resultado parcial |
| Al usar jugador concreto | Coherencia con `requiredPlayers` / `guestCards` |
| Al usar supertécnica concreta | Destacar momento clave |
| Después del partido | Consecuencias y desbloqueos |

Si el jugador no tiene la carta requerida, la fase puede prestar una **guestCard** temporal (no persistente en colección).

---

## 3. Escenas cómic

### 3.1 Ubicación

| Momento | Uso |
|---|---|
| **Antes del partido** | Contexto, motivación, presentación rival |
| **Durante el partido** | Pausa por eventos (gol narrativo, lesión ficticia, giro trama) |
| **Después del partido** | Consecuencias, desbloqueos, cliffhanger |

### 3.2 Formato

- Secuencias **tipo cómic** (paneles + diálogos).
- Personajes usando retratos/arte de cartas cuando aplique.
- Skip opcional para repetibles (pendiente UX).

### 3.3 Pausa mid-match

El motor de partido **congela estado** (marcador, PT, resistencia, posiciones minicampo), muestra cómic, y **reanuda** exactamente donde pausó.

---

## 4. Recompensas de historia

### 4.1 Primera completación

| Tipo | Ejemplos |
|---|---|
| Experiencia | Para cartas usadas |
| Monedas | Economía blanda |
| Gemas | Escasas en historia; más en hitos |
| Objetos | Entrenamiento, PT/resistencia (fuera de partido) |
| Cartas N | Drops del equipo rival |
| Desbloqueos | Alineaciones 11vs11, capítulos, dificultad superior |

### 4.2 Repetición

Niveles repetibles (pendiente por nivel):

- Posible modo **farm** con recompensas reducidas.
- Drops N de jugadores rivales.

### 4.3 Drops de cartas

Al enfrentar un equipo en historia:

- Pool de cartas **N** de **cualquier jugador** de ese roster rival.
- Permite completar colección F2P con tiempo.

---

## 5. Objetivos de pachanga (desafíos en partido)

Las **pachangas** y muchos niveles jugables incluyen **objetivos secundarios** además de ganar.

### 5.1 Objetivos fijos (siempre presentes)

| Objetivo | Condición |
|---|---|
| **Ganar el partido** | Obligatorio para cualquier recompensa de objetivos |
| **Ganar sin recibir gol** | Clean sheet |

### 5.2 Objetivos variables (rotativos por nivel)

Ejemplos de objetivos coherentes con el sistema:

| Objetivo |
|---|
| Ganar un duelo de **Regate** con un **estilo concreto** |
| Marcar con **supertécnica de Tiro** |
| Ganar un duelo defensivo con **supertécnica de Defensa** |
| **Parar** con supertécnica de Parada |
| Marcar con **ventaja de estilo** (rueda) |
| Marcar con técnica del **mismo estilo** que el jugador |
| *(Otros objetivos coherentes con duelos, PT y estilos)* |

### 5.3 Regla de recompensa

```
SI no se gana el partido:
  → NO se entrega NINGUNA recompensa de objetivos (ni fijos secundarios ni variables)
SI se gana el partido:
  → Recompensa base del nivel
  → + bonus por objetivos cumplidos (clean sheet, variables, etc.)
```

### 5.4 Implementación Fase 16 (Flutter)

Los niveles match pueden declarar objetivos en `matchObjectives` del JSON de historia:

| Categoría | Ejemplos |
|---|---|
| **Obligatorios** | `winMatch` — gate de todas las recompensas |
| **Fijos secundarios** | `cleanSheet` — ganar sin recibir goles |
| **Variables** | `scoreWithShotTechnique`, duelos por estilo, etc. |

Los objetivos futuros podrán depender de **jugadores obligatorios**, **técnicas**, **estilos** y **cinemáticas**; el modelo ya contempla `requiredPlayerId`, `requiredStyle` y `requiredTechniqueType`.

El **Nivel 4** (`chapter_01_level_04`) incluye los tres objetivos iniciales de la Fase 16.

---

## 6. Eventos

Acceso desde hub **Inicio → Eventos**.

### 6.1 Tipos generales

| Tipo | Descripción |
|---|---|
| **Evento de personaje** | Enfoque en un jugador gratuito/maximizable |
| **Evento de recursos** | Monedas, objetos, XP |
| **Evento de invocación** | Banner temporal en pestaña Invocar |
| **Evento reto** | Pachangas con reglas especiales |

Calendario y duración: contenido live-ops (pendiente).

### 6.2 Eventos de personaje (detalle)

Diseñados para que el jugador **consiga y maximice** un personaje **sin gacha**:

| Fase | Contenido |
|---|---|
| **Primera misión** | Entrega la **carta básica** (típicamente N del jugador) |
| **Resto del evento** | Misiones extensas que entregan: |
| | — **Duplicados** para árbol SR |
| | — **Libros** (subida nivel técnica / stat — pendiente tipología) |
| | — **Materiales** de evolución |
| | — **Objetos** necesarios para maximizar la carta |

**Características:**

- Eventos **extensos** (múltiples días de contenido activo).
- Progresión lineal o ramificada con dificultad creciente.
- Repetición parcial posible para farm de duplicados (pendiente).

### 6.3 Relación con gacha

Los eventos de personaje **no sustituyen** LR/XI de gacha; permiten camino F2P hacia **SR maximizado** de personajes concretos.

### 6.4 Implementación Fase 33 (Flutter, local)

MVP local de eventos de personaje sin backend ni calendario servidor:

| Elemento | Detalle |
|---|---|
| **Catálogo** | `assets/data/clash/character_events.json` |
| **Persistencia** | `clash_character_events_v1` (`completedStageIds`, `claimedFirstClearRewardKeys`, `clearCounts`, `lastPlayedAt`) |
| **Recompensas** | `firstClearRewards` solo en el primer clear; `repeatRewards` en victorias posteriores (match) |
| **Carta destacada** | `featuredCardId`: primera vez → owned; si ya poseída o `featuredCardAsDuplicate` → `duplicateCopies +1` |
| **Fases story** | Pantalla de lectura + botón Completar |
| **Fases match** | Preparación 7vs7 + motor existente; `cardXpReward` a la alineación activa al ganar |
| **Rutas** | `/clash/events`, detalle, stage, prepare, match |
| **Inicio** | Tarjeta compacta “Eventos” |

Evento inicial: **Entrenamiento de Arin** (`event-arin-training`).

**Pendiente:** calendario servidor, tienda de evento, moneda de evento, ranking, cinemáticas con imágenes, drops aleatorios complejos, LR/XI, backend.

---

## 7. Desafíos

Acceso: **Inicio → Desafíos**.

Contenido repetible distinto de la historia lineal:

| Ejemplo | Mecánica |
|---|---|
| Pachangas diarias | Objetivos variables |
| Retos de potencia | Nivel recomendado alto |
| Prueba de posición | Solo extremos, etc. (pendiente) |
| Boss semanal | Rival único con reglas especiales |

Recompensas: monedas, objetos, gemas ocasionales, XP.

---

## 8. Noticias

Acceso: **Inicio → Noticias**.

| Contenido |
|---|
| Anuncios de mantenimiento |
| Banners de gacha activos |
| Inicio/fin de eventos |
| Patch notes Clash |
| Enlaces a regalos/misiones |

Fuente: remota (API) vs bundle local — **pendiente**.

---

## 9. Misiones (cabecera hub)

Sistema paralelo a logros:

| Tipo | Ejemplos |
|---|---|
| Diarias | Jugar 3 partidos, ganar 1 pachanga sin encajar |
| Semanales | Completar capítulo, usar 5 supertécnicas de Tiro |
| De evento | Completar misión 3 del evento de personaje |
| De historia | Clear capítulo X |

Recompensas entregadas vía **Regalos** (inbox).

---

## 10. Logros y conexión Fantasy

### 10.1 Logros Clash puros

Ejemplos:

- Completar capítulo de historia.
- Maximizar árbol de una carta SR.
- Ganar 100 partidos 7vs7.
- Invocar multi 10 veces.

### 10.2 Logros cruzados Fantasy → Clash

El jugador realiza acciones en **modo Fantasy**; al volver a Clash (o en background vía API), recibe recompensas Clash.

| Hito Fantasy (ejemplo) | Recompensa Clash (ejemplo) |
|---|---|
| Jugar en una liga | Monedas |
| Completar una liga | Gemas + objeto |
| Ganar una liga | Gemas premium |
| Alcanzar nivel X de cuenta Fantasy | Carta material / ticket evento |
| *(Otros hitos)* | Recursos Clash |

### 10.3 Reglas de implementación

- **Sin imports** Fantasy ↔ Clash en frontend.
- Backend o capa `CrossRewardsCoordinator` valida hitos Fantasy y encola recompensas Clash.
- UI en Clash: sección en **Regalos** o **Misiones** con origen «Eternal Fantasy».

Lista cerrada de hitos: **pendiente** acuerdo producto/backend.

---

## 11. Progresión F2P (historia + eventos)

Camino diseñado para jugador sin gasto:

1. Recibe **todas las N** del Eternal XI al inicio.
2. Avanza **historia** → evoluciona core a R/SR, drops rivales N.
3. **Eventos de personaje** → maximiza SR objetivo.
4. Cualquier jugador gratis puede llegar a **SR + árbol max** con dedicación.
5. LR/XI reservados a gacha/especial.

---

## 12. Mapa de contenido (placeholder)

| Arco | Equipo rival | Drop pool | Alineación 11vs11 | Notas |
|---|---|---|---|---|
| Tutorial | — | — | — | Cartas N iniciales |
| Arco 1 | TBD | Jugadores equipo 1 | Formación A | |
| Arco 2 | TBD | Jugadores equipo 2 | Formación B | |
| … | … | … | … | |
| Final | TBD | — | Todas desbloqueadas | |

Contenido narrativo concreto: **pendiente** de guion.

---

## Fase 49 — Mapa y detalle de historia (UI)

| Incluido | Pendiente |
|---|---|
| Progreso X/Y y capítulo actual en mapa | Mapa con nodos animados |
| Tarjetas de nivel con tipo, estado y first clear | Cinemáticas con imágenes |
| Detalle story con narrativa y rewards | Editor de historia |
| Preparación match con rival, objetivos y CTAs | Energía/stamina de entrada |

**Sin cambios** en progresión, recompensas ni desbloqueos.

---

## 13. Decisiones pendientes

| Tema | Estado |
|---|---|
| Guion y roster por arco | Pendiente |
| Tabla energía por tipo de nivel | Pendiente |
| Repetibilidad y coste farm | Pendiente |
| Tipología exacta de «libros» en eventos | Pendiente |
| Calendario live-ops eventos | Pendiente |
| Lista cerrada logros cruzados Fantasy | Pendiente |
| Skip cómic en repetición | Pendiente |
| Tutorial energía/gacha | Pendiente |
