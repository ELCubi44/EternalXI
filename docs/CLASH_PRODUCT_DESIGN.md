# Eternal Clash — Diseño de producto inicial

> **Estado:** diseño pre-implementación (fase 0).  
> **Alcance:** documentación de producto y UX. Sin código.  
> **Relacionado:** `CLASH_INTEGRATION_AUDIT.md`, `CLASH_INTEGRATION_ARCHITECTURE.md`

---

## 1. Visión general

**Eternal Clash** es un segundo modo de juego dentro de la app móvil **Eternal XI**. Combina colección de cartas de jugadores reales, progresión, gacha, historia y batallas de fútbol inspiradas en la experiencia de *Dragon Ball Dokkan Battle*, **sin copiar** recursos, diseños protegidos ni código de terceros.

El modo Fantasy (ligas, mercado, alineaciones) y el modo Clash deben permanecer **separados internamente**: distintos módulos, modelos, servicios, navegación y estado. Solo comparten infraestructura explícita (autenticación, usuario, cliente API, catálogo base de jugadores, recompensas cruzadas).

---

## 2. Integración en Eternal XI

### 2.1 Flujo post-autenticación

Tras **login** o **restaurar sesión**, el usuario **siempre** pasa por un **selector de modo**:

| Opción | Destino |
|---|---|
| **Fantasy** | Flujo actual (`/leagues`, `MyLeaguesScreen`) |
| **Clash** | Shell del modo Clash (`/clash`) |

**Regla explícita:** no recordar automáticamente el último modo. Cada entrada autenticada muestra el selector, salvo que el usuario esté ya navegando dentro de un modo y vuelva al selector manualmente.

### 2.2 Separación interna

| Compartido | Aislado (Clash) | Aislado (Fantasy) |
|---|---|---|
| Auth, perfil cuenta, legal | `features/clash/**` | `features/leagues/**`, `features/rewards/**` |
| `ApiClient`, JWT, storage | Modelos, controllers, rutas Clash | Modelos, controllers, rutas Fantasy |
| Catálogo jugador (`idJugador`) vía bridge | Economía Clash (gemas, energía) | Fichas, ligas, mercado |
| Logros/recompensas cruzadas (capa explícita) | Gacha, batallas, historia Clash | — |

**Prohibición:** imports directos entre lógica Fantasy y lógica Clash.

### 2.3 Referencia de experiencia (Dokkan Battle)

Inspiración en patrones de UX reconocibles por jugadores de gacha/colección:

- Hub principal con recursos visibles en cabecera.
- Navegación inferior persistente entre secciones core.
- Historia como eje de progresión.
- Eventos temporales con recompensas de personaje.
- Invocación (gacha) con single/multi y descuento diario.
- Partidas consumiendo energía recuperable.

**No se replica:** arte, UI pixel-a-pixel, nombres propios, mecánicas con copyright, código del prototipo ni de Dokkan.

---

## 3. Navegación inferior de Clash

Barra inferior fija con **cuatro pestañas**:

| Pestaña | Función principal |
|---|---|
| **Inicio** | Hub: recursos, equipo protagonista, accesos a Historia, Eventos, Desafíos, Noticias |
| **Equipo** | Gestión de colección, alineaciones 7vs7 y 11vs11, evolución, árbol de duplicados |
| **Invocar** | Gacha / banners de invocación |
| **Tienda** | Compras con monedas/gemas, venta de duplicados sobrantes (fase posterior) |

Cada pestaña tiene su propio stack de navegación interna dentro del shell Clash, independiente de GoRouter Fantasy.

---

## 4. Pantalla de Inicio (hub Clash)

### 4.1 Cabecera de recursos

Siempre visible en la pestaña **Inicio** (y referenciada en otras pantallas cuando aplique):

| Recurso | Uso |
|---|---|
| **Cuenta / perfil** | Acceso a ajustes Clash y enlace a perfil global Eternal XI |
| **Energía** | Coste de niveles (historia, narrativos, eventos) |
| **Monedas** | Economía blanda (objetos, mejoras, tienda) |
| **Gemas** | Economía premium (gacha, recuperar energía, etc.) |
| **Misiones** | Misiones diarias/semanales y progreso |
| **Regalos** | Inbox de recompensas pendientes |

### 4.2 Composición visual del equipo protagonista

Zona central destacada con la **formación visual del equipo Eternal XI** (equipo protagonista de la historia). Muestra las cartas principales del usuario en pose de presentación, no necesariamente la alineación activa de combate.

Funciones:
- Refuerzo de identidad narrativa.
- Acceso rápido a editar alineación 7vs7.
- Feedback visual de progresión (rareza, nivel, evolución).

### 4.3 Accesos principales

Desde el hub **Inicio**, cuatro entradas prominentes:

| Acceso | Descripción |
|---|---|
| **Historia** | Campaña principal; eje de progresión de Clash |
| **Eventos** | Eventos temporales; incluye **eventos de personaje** para conseguir y maximizar personajes gratuitos |
| **Desafíos** | Contenido repetible / retos con objetivos variables |
| **Noticias** | Anuncios, mantenimiento, banners activos, calendario |

---

## 5. Economía y recursos

### 5.1 Gemas

| Concepto | Valor / regla |
|---|---|
| Single gacha | 1 carta — **10 gemas** |
| Multi gacha | 10 cartas — **95 gemas**; **garantiza SR o superior** en al menos una carta |
| Descuento diario | **1 single por banner por día a 1 gema** |
| Pity | **Pendiente de decidir** |

### 5.2 Energía

Todos los niveles consumen energía:

- Historia (todos los tipos de nivel).
- Niveles narrativos.
- Eventos.

**Recuperación:**

- Regeneración con el tiempo.
- Ver anuncios (cantidad y límites por definir en balance).
- Gastar gemas.
- Posibles objetos futuros (no diseñados aún).

### 5.3 Monedas

Moneda blanda para tienda, objetos de entrenamiento y venta de duplicados. Detalle de precios: pendiente de balance.

---

## 6. Cartas iniciales y onboarding Clash

Al **comenzar Clash por primera vez**, el usuario recibe **todas las cartas N del equipo protagonista Eternal XI**.

Esto garantiza:
- Equipo jugable inmediato en 7vs7.
- Base para evolucionar hacia R y SR sin gacha.
- Identificación con el roster narrativo principal.

Detalle de cartas, evolución y árbol: ver `CLASH_CARD_SYSTEM.md`.

---

## 7. Potencia (resumen de producto)

| Concepto | Definición |
|---|---|
| **Potencia del jugador** | Suma de todas sus estadísticas al máximo de nivel |
| **Potencia del equipo** | Suma de la potencia de sus jugadores en alineación |

**Usos en UI:**

- Comparar equipo propio vs. rival recomendado.
- Mostrar potencia recomendada del nivel.
- Advertir si el equipo parece insuficiente (warning, no bloqueo).

**Regla:** la potencia **nunca impide** entrar a un nivel. El jugador siempre puede intentarlo.

Detalle de estadísticas, resistencia y PT: ver `CLASH_CARD_SYSTEM.md` y `CLASH_MATCH_SYSTEM.md`.

---

## 8. Modos de partido (resumen)

| Modo | Interacción | Objetivo típico |
|---|---|---|
| **7vs7 interactivo** | Usuario toma decisiones en duelos; posesión continua | Primer equipo en **3 goles** |
| **11vs11 simulado** | Sin intervención directa del usuario | Resultado calculado; usado en historia avanzada |

Detalle completo: `CLASH_MATCH_SYSTEM.md`.

---

## 9. Historia, eventos y desafíos (resumen)

- **Historia** = eje principal de Clash.
- Tipos de nivel: solo historia, jugables, mixtos.
- Escenas cómic antes/durante/después; pausa mid-match para narrativa.
- **Eventos de personaje:** misión inicial entrega carta básica; evento completo entrega duplicados y materiales para maximizar.
- **Desafíos / pachangas:** objetivos fijos (ganar, clean sheet) + variables (duelos, supertécnicas, estilos).

Detalle: `CLASH_STORY_AND_EVENTS.md`.

---

## 10. Logros y conexión con Fantasy

Clash incluirá:

- Logros generales de progresión Clash.
- Misiones ligadas a eventos.
- **Logros cruzados con Fantasy**, por ejemplo:
  - Jugar ligas Fantasy.
  - Completar ligas.
  - Ganar una liga.
  - Alcanzar cierto nivel Fantasy.
  - Otros hitos coherentes.

**Recompensa de logros Fantasy → recursos Clash** (gemas, monedas, objetos, etc.).

**Implementación:** sistema explícito de logros/recompensas cruzadas (`CrossRewardsCoordinator` en arquitectura). **Sin imports** directos entre controllers Fantasy y Clash.

---

## 11. Identidad visual (directrices, no definitivas)

- Paleta y tipografía base: heredar tokens Eternal XI (`Lumiare`, `XiColors`) con variantes propias Clash si se requiere diferenciación.
- Cartas N/R/SR: retratos pecho arriba.
- Cartas LR/XI: arte cuerpo completo especial.
- Panel de estadísticas lateral o zona claramente visible en ficha de carta.
- Minicampo durante partido 7vs7 siempre arriba.
- **Diseño visual definitivo de cartas y UI de combate: pendiente.**

---

## 12. Decisiones pendientes de producto

| Tema | Estado |
|---|---|
| Sistema de pity gacha | Pendiente |
| Cantidades exactas de regeneración de energía | Pendiente |
| Límites de anuncios por día | Pendiente |
| Precios tienda y venta de duplicados | Pendiente |
| Diseño visual final de cartas y combate | Pendiente |
| Lista exacta de logros cruzados Fantasy | Pendiente de listado con backend |
| Contenido Noticias (¿remoto o local?) | Pendiente |

---

## 13. Glosario rápido

| Término | Significado |
|---|---|
| **PT** | Puntos de Técnica; recurso por jugador para supertécnicas |
| **Resistencia** | Stat que decae en partido; por debajo de 100 penaliza stats efectivas |
| **Pachanga** | Partido con objetivos secundarios además de ganar |
| **Árbol** | Progresión de duplicados en SR/LR/XI (6 copias totales para max) |
| **Eternal XI (equipo)** | Equipo protagonista de la historia Clash |
