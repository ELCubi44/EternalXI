# Eternal Clash — Sistema de cartas

> **Estado:** diseño pre-implementación.  
> **Relacionado:** `CLASH_PRODUCT_DESIGN.md`, `CLASH_MATCH_SYSTEM.md`

---

## 1. Identidad de carta

Cada carta Clash representa un **jugador real** del catálogo Eternal XI, identificado por **`playerId`** (= `idJugador` del backend compartido). La carta Clash es una **instancia de juego** independiente del jugador Fantasy en liga (`LeagueSquadPlayer`).

Campos conceptuales de una carta:

| Campo | Descripción |
|---|---|
| `id` | Identificador único de instancia Clash |
| `playerId` | Referencia al jugador real del catálogo |
| `rarity` | N, R, SR, LR, XI |
| `level` | Nivel actual (máx. según rareza) |
| `experience` | XP acumulada |
| `evolutionStage` | Etapa dentro de la cadena N→R→SR |
| `superTechniques` | Lista de supertécnicas desbloqueadas |
| `treeProgress` | Nodo del árbol (solo SR/LR/XI cuando aplique) |
| `stats` | Estadísticas actuales (calculadas por nivel, árbol, resistencia en partido) |

---

## 2. Rareza

| Código | Nombre | Nivel máximo |
|---|---|---|
| **N** | Normal | 60 |
| **R** | Raro | 80 |
| **SR** | Super Raro | 100 |
| **LR** | Legendario | 120 |
| **XI** | Eterno | 120 |

### 2.1 Obtención por rareza

| Rareza | Vías principales |
|---|---|
| N | Inicial (equipo Eternal XI), drops de historia, eventos |
| R | Evolución desde N, drops, eventos |
| SR | Evolución desde N/R, gacha, eventos de personaje, juego prolongado |
| LR | **Exclusivo:** gacha, recompensas especiales, métodos especiales — **no evolución** |
| XI | **Exclusivo:** gacha, recompensas especiales, métodos especiales — **no evolución** |

---

## 3. Evolución

### 3.1 Cadenas permitidas

```
N ──→ R ──→ SR
N ──→ SR   (salto directo permitido desde N)
R ──→ SR
```

| Desde | Puede evolucionar a |
|---|---|
| N | R, SR |
| R | SR |
| SR | *(máximo por evolución)* |
| LR | *(no evoluciona)* |
| XI | *(no evoluciona)* |

### 3.2 Reglas

- **SR** es el **máximo alcanzable por evolución**.
- **LR** y **XI** solo se obtienen por gacha, recompensas o métodos especiales.
- Al evolucionar, la carta mantiene nivel relativo según reglas de conversión (tabla exacta: pendiente de balance); el árbol de duplicados, si aplica, se abre en la **versión SR resultante**.

---

## 4. Arte de cartas

| Rareza | Tipo de arte |
|---|---|
| N, R, SR | Retrato **básico pecho hacia arriba** |
| LR, XI | **Arte especial cuerpo completo** |

### 4.1 Presentación en UI

- Estadísticas en **panel lateral** o zona claramente visible (no ocultas tras flip obligatorio).
- Diseño visual definitivo de marco, bordes y efectos: **pendiente**.
- Misma identidad de jugador (`playerId`) puede tener distintos artes según rareza.

---

## 5. Estadísticas de carta

### 5.1 Stats base (fuera de partido / al máximo de nivel)

| Stat | Uso principal |
|---|---|
| **Parada** | Duelos portero vs tiro |
| **Defensa** | Duelos defensivos, intercepciones |
| **Pase** | Probabilidad y calidad de pases |
| **Regate** | Duelos ofensivos al avanzar |
| **Tiro** | Duelos de finalización |
| **PT** | Reserva máxima de Puntos de Técnica |
| **Resistencia** | Umbral de penalización en partido |

### 5.2 Potencia

```
Potencia jugador = Parada + Defensa + Pase + Regate + Tiro + PT + Resistencia
                 (valores al máximo de nivel, fuera de penalizaciones de partido)
```

```
Potencia equipo = Σ potencia de cada jugador en alineación activa
```

Usos: comparación, recomendación, advertencia. **Nunca bloquea** acceso al nivel.

### 5.3 Resistencia — diseño

| Aspecto | Regla |
|---|---|
| Mínimo general | ~**100** para todas las cartas |
| Máximo XI | ~**130** |
| Diferencia entre rarezas | **No exagerada** |
| En partido | La resistencia **actual** baja con el juego |
| Sin penalización | Mientras resistencia ≥ **100**, stats efectivas intactas |
| Con penalización | Por debajo de 100, reduce stats efectivas: Pase, Regate, Tiro, Defensa, Parada |
| Ventaja XI | Más resistencia base → tardan más en penalizar |
| Efecto en gameplay | Afecta % de pase y puntuaciones de duelo |
| Recuperación | **No** tras cada gol; **solo** en descanso con objetos |

Valores exactos de curva de penalización: pendiente de balance en `CLASH_MATCH_SYSTEM.md`.

**Implementación Fase 3 (provisional):** `deficit = 100 - resistenciaActual`, `penalty = deficit × 0.003`, multiplicador mínimo **0.70**. Solo afecta Parada, Defensa, Pase, Regate y Tiro; **PT no se reduce** por cansancio.

---

## 6. Puntos de Técnica (PT)

| Regla | Detalle |
|---|---|
| Definición | Recurso por jugador para activar supertécnicas |
| Máximo | Stat **PT** de la carta al nivel actual |
| Actual en partido | Comienza al máximo; baja al usar técnicas |
| Coste | Cada supertécnica tiene **coste de PT** fijo por nivel de técnica |
| Reutilización | Misma técnica usable varias veces si hay PT suficientes |
| Recuperación automática | **No** |
| Recuperación en partido | **Solo** en descanso mediante objetos |

Mejorar el **nivel de supertécnica** aumenta potencia pero **no reduce** coste de PT.

---

## 7. Supertécnicas

### 7.1 Tipos válidos

| Tipo | Contexto de uso |
|---|---|
| **Parada** | Duelo portero vs tiro |
| **Defensa** | Duelo defensivo al avanzar |
| **Regate** | Duelo ofensivo al avanzar |
| **Tiro** | Duelo de finalización en el área |

**No existen** supertécnicas de **Pase**. El pase usa solo la stat Pase y el sistema de probabilidad.

### 7.2 Cantidad por rareza

| Rareza | Supertécnicas |
|---|---|
| N | 1 |
| R | 2 |
| SR | 3 |
| LR | 4 |
| XI | 4 + **1 pasiva** |

La pasiva XI es permanente en partido (efecto por definir en balance; no consume PT salvo que se especifique lo contrario en diseño de pasiva concreta).

### 7.3 Estructura de cada supertécnica

| Campo | Descripción |
|---|---|
| `nombre` | Nombre visible |
| `tipo` | Parada / Defensa / Regate / Tiro |
| `estilo` | Uno de los 5 estilos (ver §8) |
| `potencia` | Fuerza base del duelo |
| `costePT` | PT consumidos al activar |
| `nivel` | Normal, I, V, X, XI |

### 7.4 Niveles de supertécnica

| Nivel | Efecto al subir |
|---|---|
| Normal | Base |
| I | +potencia |
| V | +potencia |
| X | +potencia |
| XI | +potencia |

**Solo aumenta potencia.** El coste PT **no baja**.

**Implementación Fase 3 (provisional):** multiplicadores Normal 1.00, I 1.05, V 1.10, X 1.15, XI 1.20 sobre `basePower`.

---

## 8. Estilos

### 8.1 Lista de estilos

- **Pícaro**
- **Potente**
- **Ágil**
- **Preciso**
- **Valiente**

### 8.2 Rueda de ventaja (duelos)

```
Pícaro   → supera a → Potente
Potente  → supera a → Valiente
Valiente → supera a → Preciso
Preciso  → supera a → Ágil
Ágil     → supera a → Pícaro
```

En duelo, si estilos están en relación ventaja/desventaja, se aplica modificador a la puntuación (magnitud: pendiente de balance).

### 8.3 Restricciones de equipo

- Los estilos **pueden repetirse** libremente en una alineación.
- **No condicionan** la construcción del equipo (sin bonus de "solo un estilo" ni penalización por duplicados).

---

## 9. Duplicados y árbol de progresión

### 9.1 Quién tiene árbol

| Rareza | Árbol de duplicados |
|---|---|
| N | **No** — solo sube de nivel |
| R | **No** — solo sube de nivel |
| SR | **Sí** (cuando corresponda) |
| LR | **Sí** |
| XI | **Sí** |

### 9.2 Coste de maximizar árbol

Para maximizar un árbol:

- 1 carta inicial
- **5 duplicados** de la misma carta (misma rareza y mismo jugador)
- **Total: 6 copias**

### 9.3 Evolución y árbol

- Si una carta evoluciona a **SR**, el árbol se abre con **duplicados de su versión SR** (no cuenta duplicados de la etapa N/R previa hacia nodos SR).
- Detalle de nodos del árbol (stats, técnicas, pasivas): pendiente de diseño por personaje.

### 9.4 Duplicados sobrantes

Tras completar árbol o sin carta compatible:

| Uso | Disponibilidad |
|---|---|
| Material de experiencia | Sí (desde fase de colección) |
| Venta en tienda | Sí (**fase posterior**) |

---

## 10. Subida de nivel

### 10.0 Implementación Fase 17 (Flutter)

La **Fase 17** implementa EXP y subida de nivel por victorias en partidos match:

| Incluido | Pendiente |
|---|---|
| `ClashCardXpTable`, `ClashCardXpService`, persistencia v2 | Objetos de entrenamiento |
| EXP por nivel (`cardXpReward` en JSON de historia) | Cartas como material |
| UI barra XP + resumen en fin de partido | Backend |
| Escalado provisional stats/potencia por nivel | Evolución / árbol |

**Curva provisional:** `xpToNextLevel(level, rarity) = base + level × factor`.

| Rareza | Base | Factor |
|---|---|---|
| N | 40 | 10 |
| R | 60 | 14 |
| SR | 90 | 20 |
| LR | 130 | 28 |
| XI | 160 | 34 |

**Límites:** N 60, R 80, SR 100, LR/XI 120.

**Farm:** la EXP de partido se puede obtener repetidamente al rejugar niveles; las recompensas base del nivel no se duplican.

### 10.1 Fuentes de experiencia

| Fuente | Descripción |
|---|---|
| Jugar partidos | XP base por resultado y objetivos (**Fase 17:** `cardXpReward` solo si gana) |
| Objetos de entrenamiento | Consumibles que otorgan XP |
| Cartas como material | Duplicados u otras cartas sacrificadas |

### 10.2 Límites

El nivel no supera el máximo de la rareza (§2).

Fórmulas de XP por nivel: ver §10.0 (curva provisional Fase 17).

---

## 11. Cartas iniciales

Al **primer acceso a Clash**, el usuario recibe **todas las cartas N** del **equipo protagonista Eternal XI** (roster narrativo principal).

Implicaciones:
- Plantilla 7vs7 completable de inmediato (7 posiciones + banquillo según diseño de squad).
- Base para evolucionar el core team sin gacha.

Lista exacta de jugadores del roster inicial: pendiente de contenido narrativo.

---

## 12. Drops de historia

Al jugar contra **otros equipos** en la historia:

- Pueden caer cartas **N** de **cualquier jugador** de ese equipo rival.
- **Regla de progresión F2P:** cualquier jugador obtenible gratis (drops + eventos) puede llegar hasta **SR** y **maximizarse** (evolución + árbol SR) con suficiente dedicación.

No se garantiza drop por partido; tasas por equipo/nivel: pendiente de balance.

---

## 13. Gacha (referencia cruzada)

| Tipo | Coste | Contenido |
|---|---|---|
| Single | 10 gemas | 1 carta |
| Multi | 95 gemas | 10 cartas; **≥1 SR o superior** |
| Diario | 1 gema | 1 single por banner por día |

Pity: **pendiente**. Ver `CLASH_PRODUCT_DESIGN.md`.

---

## 14. Objetos de partido (referencia)

Usables **solo en el descanso** entre periodos del 7vs7:

| Tipo previsto |
|---|
| Recuperar PT de **un** jugador |
| Recuperar PT de **tres** jugadores |
| Recuperar **pocos** PT de **todo** el equipo |
| Recuperar resistencia de **un** jugador |
| Recuperar resistencia de **varios** jugadores |
| Recuperar **poca** resistencia de **todo** el equipo |

Detalle de efectos numéricos: `CLASH_MATCH_SYSTEM.md`.

---

## 15. Modelo de datos (orientación implementación futura)

```
ClashCard              — definición estática (rareza, stats, técnicas, playerId)
ClashCardProgress      — progreso del usuario (nivel, XP, árbol, niveles de técnica)
ClashSuperTechnique
ClashStyle (enum)
ClashRarity (enum)
ClashCardStats
ClashTreeNode
ClashDuplicateMaterial
```

**Separación Fase 3:** `ClashCard` describe la carta; `ClashCardProgress` guarda el estado del jugador (nivel, experiencia, nodos de duplicados, niveles de supertécnicas) sin mezclar ambos en un solo modelo.

**Ubicación:** `features/clash/cards/domain/` — **no** en `data/models/league_*`.

**Vínculo catálogo:** `playerId` → `CatalogPlayerBridge` (solo lectura).

---

## 16. Decisiones pendientes

| Tema | Estado |
|---|---|
| Tabla XP por nivel y rareza | Pendiente |
| Nodos concretos del árbol SR/LR/XI | Pendiente |
| Efecto exacto pasiva XI | Pendiente |
| Tasas de drop N por equipo | Pendiente |
| Conversión de nivel al evolucionar N→R→SR | Pendiente |
| Coste de subir nivel de supertécnica | Pendiente |
| Curva penalización resistencia < 100 | Pendiente |
