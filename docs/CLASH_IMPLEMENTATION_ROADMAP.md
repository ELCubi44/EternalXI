# Eternal Clash — Roadmap de implementación

> **Estado:** planificación pre-código.  
> **Relacionado:** todos los documentos `CLASH_*.md` y `CLASH_INTEGRATION_ARCHITECTURE.md`

---

## 1. Principios del roadmap

| Principio | Aplicación |
|---|---|
| **Fantasy intacto** | Ninguna fase modifica `features/leagues/**` ni `features/rewards/**` sin autorización explícita |
| **Incremental** | Cada fase entrega algo demostrable en dispositivo |
| **Aislamiento** | Clash crece en `features/clash/`; selector en `features/mode/` |
| **Documentación primero** | Fase 0 completa antes de código de gameplay |
| **Backend al final del vertical slice** | Prototipo local/mock antes de API Clash real |
| **Sin dependencias nuevas** hasta fase que las requiera (evaluar PR aparte) |

---

## 2. Resumen de fases

| Fase | Nombre | Entregable clave |
|---|---|---|
| **0** | Documentación y diseño | Specs completas ✅ (este paquete de docs) |
| **1** | Selector de modo + shell vacío | Tras login → selector; Clash abre shell placeholder |
| **2** | Navegación inferior Clash | 4 tabs: Inicio, Equipo, Invocar, Tienda (stubs) |
| **3** | Modelos de cartas | DTOs Clash, rarezas, stats, supertécnicas (local) |
| **4** | Colección y equipo | Inventario, alineación 7vs7, cartas iniciales N |
| **5** | Alineaciones 7vs7 | Modelo, persistencia, pantalla equipo |
| **6** | Historia prólogo | Mapa, lector, 3 niveles story, roster N |
| **7** | Base match shell 7vs7 | Nivel 4 match, prepare, partido provisional, minicampo |
| **8** | Pase y avance | Motor de posesión y movimiento en minicampo |
| **9** | Duelos regate/defensa | Resolución interactiva con moneda |
| **10** | Tiro/parada | Cierre de jugada a portería |
| **11** | Supertécnicas / PT | Activación y coste en duelos |
| **12** | IA rival | Decisiones del oponente 7vs7 |
| **13** | Gacha | UI Invocar, single/multi, descuento diario (mock) |
| **14** | Tienda | Monedas, objetos, venta duplicados (stub) |
| **15** | 11vs11 simulado | Motor resumen + alineaciones desbloqueables |
| **16** | Backend Clash | API real, persistencia cuenta Clash |
| **17** | Recompensas cruzadas | Logros Fantasy → recursos Clash |

---

## 3. Fase 0 — Documentación y diseño ✅

### Objetivos

- Auditar integración (`CLASH_INTEGRATION_AUDIT.md`).
- Arquitectura técnica (`CLASH_INTEGRATION_ARCHITECTURE.md`).
- Diseño de producto (`CLASH_PRODUCT_DESIGN.md`).
- Sistemas: cartas, partido, historia, roadmap.

### Entregables

| Documento | Estado |
|---|---|
| `CLASH_INTEGRATION_AUDIT.md` | Existente |
| `CLASH_INTEGRATION_ARCHITECTURE.md` | Existente (nota: actualizar «recordar modo» → **siempre selector**) |
| `CLASH_PRODUCT_DESIGN.md` | Este paquete |
| `CLASH_CARD_SYSTEM.md` | Este paquete |
| `CLASH_MATCH_SYSTEM.md` | Este paquete |
| `CLASH_STORY_AND_EVENTS.md` | Este paquete |
| `CLASH_IMPLEMENTATION_ROADMAP.md` | Este documento |
| `CLASH_API.md` (contrato backend) | **Pendiente** fase 12–13 |

### Criterios de salida

- [x] Decisiones de producto documentadas.
- [ ] Revisión y confirmación del equipo.
- [ ] Alineación backend sobre namespace API.

---

## 4. Fase 1 — Selector de modo + shell vacío

### Alcance

- Ruta `/mode` con **Fantasy | Clash** (siempre tras login/splash con sesión).
- **No** recordar último modo automáticamente.
- Ruta `/clash` → `ClashShellScreen` placeholder («Próximamente» o tabs vacías).
- Cambios mínimos: `splash_screen`, `login_screen`, `router`, `routes`, `main` (GameModeController opcional).

### Archivos probables (futuro)

| Crear | Modificar |
|---|---|
| `features/mode/**` | `app/router.dart`, `app/routes.dart` |
| `features/clash/shell/clash_shell_screen.dart` | `splash_screen.dart`, `login_screen.dart` |
| | `main.dart` |

### No tocar

`features/leagues/**`, `features/rewards/**`, modelos league.

### Criterios de salida

- Login → selector → Fantasy funciona **igual** que hoy.
- Selector → Clash abre shell sin crash.
- `flutter analyze` limpio; sin imports cruzados.

---

## 5. Fase 2 — Navegación inferior Clash

### Alcance

Implementar `XiBottomNav` (o variante Clash) con:

| Tab | Contenido mínimo |
|---|---|
| Inicio | Stub cabecera recursos + botones Historia/Eventos/Desafíos/Noticias |
| Equipo | Placeholder |
| Invocar | **Fase 23:** gacha local MVP (ver sección 22 incremental) |
| Tienda | Placeholder |

Estado de tab en shell Clash; **independiente** de LeagueShell.

### Criterios de salida

- Navegación fluida entre 4 tabs.
- Botón «Cambiar modo» vuelve a `/mode`.

---

## 6. Fase 3 — Modelos de cartas

### Alcance

En `features/clash/data/models/`:

- `ClashRarity`, `ClashStyle`, `ClashSuperTechniqueType`
- `ClashCard`, `ClashCardStats`, `ClashSuperTechnique`
- Datos mock JSON local para desarrollo.

Reglas implementadas como validación (tests opcionales):

- Niveles máximos por rareza.
- Conteo supertécnicas por rareza.
- Evolución N→R→SR; LR/XI no evolucionan.

### Puente catálogo

- `CatalogPlayerBridge` en `core/cross_mode/` — snapshot por `playerId`.

### Criterios de salida

- Serialización JSON ida/vuelta.
- Sin referencias a `LeagueSquadPlayer`.

---

## 7. Fase 4 — Colección y equipo

### Alcance

- Pantalla **Equipo**: lista de cartas del usuario (mock).
- Otorgar **todas las N del Eternal XI** al primer launch Clash (local).
- Editor alineación **7vs7**: 7 posiciones no repetibles.
- Ficha carta: stats, técnicas, evolución (UI básica).
- Cálculo **potencia** jugador/equipo + warning vs recomendado.

### Fuera de alcance

- Gacha real, backend, árbol duplicados completo.

### Criterios de salida

- Usuario ve roster inicial y guarda alineación localmente.

---

## 8. Fase 5 — Historia y eventos (UI)

### Alcance

- **Inicio → Historia**: mapa/nodo de capítulos (mock 2–3 capítulos).
- Tipos de nivel: solo historia, jugable, mixto (badges).
- Visor **cómic** simple (imágenes + texto).
- **Eventos**: lista con evento de personaje de ejemplo (estructura misiones).
- **Desafíos** y **Noticias**: listas placeholder.
- Consumo de **energía** (contador local).

### Criterios de salida

- Flujo: Historia → elegir nivel → cómic → (enlace a partido fase 6).

---

## 9. Fase 6 — Prototipo 7vs7

### Alcance

- Pantalla partido mínima: marcador, posesión, acciones Pasar/Avanzar/Tirar (zona).
- Condición victoria: **3 goles**.
- Sorteo cara/cruz; saque inicial y tras gol.
- Fin de posesión: gol, robo, pérdida, parada, fuera, falta (stubs).
- **Resistencia y PT** decrementan; sin objetos aún.

### Criterios de salida

- Partido jugable end-to-end con datos mock, aunque IA sea trivial temporalmente.

---

## 10. Fase 7 — Minicampo

### Alcance

- Widget minicampo **fijo arriba** durante partido.
- Puntos por jugador, balón, zonas (defensa, medio, área).
- Sincronizado con acciones Pasar/Avanzar.

### Criterios de salida

- Usuario entiende visualmente por qué un pase es arriesgado (feedback básico).

---

## 11. Fase 8 — Duelos

### Alcance

- Duelos al **avanzar** (Regate vs Defensa).
- Duelos en **área** (Tiro vs Parada).
- Supertécnicas dentro de duelo con coste PT.
- Acciones normales sin PT.
- **Empate** → animación moneda (verde usuario / rojo rival).
- Modificador **estilos** (rueda).
- Sistema de **pases** probabilístico (factores documentados).

### Criterios de salida

- Duelos y pases funcionan según reglas de `CLASH_MATCH_SYSTEM.md`.

---

## 12. Fase 9 — IA

### Alcance

- `ClashAiController`: decisiones Pasar/Avanzar/Tirar.
- Uso inteligente de supertécnicas y PT.
- Rivales SR+ con árbol max simulado.
- Dificultad por stats del nivel.

### Criterios de salida

- IA no comete errores absurdos; partidas desafiantes en niveles altos.

---

## 13. Fase 10 — Gacha

### Alcance

- Tab **Invocar**: banners mock.
- Single 10 gemas, Multi 95 gemas, garantía SR+ en multi.
- **1 gema/día/banner** (contador diario local).
- Animación resultado (simple).
- Pity: **implementar cuando se decida** diseño.

### Criterios de salida

- Loop invocar → carta añadida a colección mock.

---

## 14. Fase 11 — Tienda

### Alcance

- Tab **Tienda**: compra objetos entrenamiento, PT/resistencia (fuera partido).
- Venta duplicados sobrantes (monedas) — reglas básicas.
- Gemas → energía / packs (mock).

### Criterios de salida

- Economía local coherente con diseño.

---

## 15. Fase 12 — 11vs11 simulado

### Alcance

- Desbloqueo alineaciones por progreso historia (mock).
- Pantalla simulación: preview potencias → resultado.
- Rivales 4-3-3 con variantes MC ofensivo/atrasado doble.
- Integración en niveles historia avanzados.

### Criterios de salida

- Nivel 11vs11 completable sin input mid-match.

---

## 16. Fase 13 — Backend Clash

### Alcance

- Documentar e implementar `CLASH_API.md`.
- Endpoints: perfil Clash, colección, energía, gacha, partido (sync), historia progress.
- Migrar persistencia local → servidor.
- Autenticación: mismo JWT Eternal XI.

### Dependencias

- Equipo backend disponible.
- Namespace acordado (propuesta: `/api/v1/clash/*`).

### Criterios de salida

- Progreso sobrevive reinstall.
- Gacha y energía server-authoritative.

---

## 17. Fase 14 — Recompensas cruzadas Fantasy

### Alcance

- `CrossRewardsCoordinator` + API hitos Fantasy.
- Logros listados en `CLASH_STORY_AND_EVENTS.md` §10.
- Inbox **Regalos** en Clash con origen Fantasy.
- **Cero imports** entre módulos.

### Criterios de salida

- Completar hito Fantasy → recompensa visible en Clash tras sync.

---

## 18. Cronograma orientativo

Estimaciones **muy aproximadas** (1 dev Flutter + backend parcial):

| Fase | Duración orientativa |
|---|---|
| 0 Documentación | ✅ Completada |
| 1 Selector + shell | 1 semana |
| 2 Nav inferior | 1 semana |
| 3 Modelos | 1–2 semanas |
| 4 Colección/equipo | 2–3 semanas |
| 5 Historia UI | 2 semanas |
| 6 Prototipo 7vs7 | 2–3 semanas |
| 7 Minicampo | 1–2 semanas |
| 8 Duelos + pases | 3–4 semanas |
| 9 IA | 2–3 semanas |
| 10 Gacha | 1–2 semanas |
| 11 Tienda | 1–2 semanas |
| 12 11vs11 | 2 semanas |
| 13 Backend | 4–6 semanas (paralelo posible desde fase 10) |
| 14 Cross-rewards | 2 semanas |

**Vertical slice jugable (fases 1–9):** ~3–4 meses.  
**Producto Clash completo con backend:** ~5–7 meses adicionales según contenido.

---

## 19. Riesgos por fase

| Fase | Riesgo | Mitigación |
|---|---|---|
| 1 | Romper flujo Fantasy post-login | Tests manuales regresión ligas; redirect Fantasy idéntico |
| 6–8 | Complejidad combate | Prototipo en isolates; datos mock; iterar IA después |
| 8 | Balance pases/duelos | Tablas en hoja de cálculo; telemetría futura |
| 10 | Pity indefinido | Ship sin pity; añadir cuando producto decida |
| 13 | Backend no listo | Mock/local hasta API estable |
| 14 | Acoplamiento Fantasy | Solo coordinator; revisión imports CI |

---

## 20. Checklist pre-código (gate fase 1)

- [ ] Confirmación producto de este paquete de diseño.
- [ ] Actualizar `CLASH_INTEGRATION_ARCHITECTURE.md` (selector siempre, sin auto-recordar).
- [ ] Lista inicial roster Eternal XI (cartas N iniciales).
- [ ] Acuerdo backend fase 13 (owner, timeline).
- [ ] Decisión pity gacha (puede posponerse hasta fase 10).

---

## 21. Documentos de referencia

| Documento | Contenido |
|---|---|
| `CLASH_PRODUCT_DESIGN.md` | UX, hub, economía, integración |
| `CLASH_CARD_SYSTEM.md` | Rareza, evolución, stats, árbol, gacha |
| `CLASH_MATCH_SYSTEM.md` | 7vs7, 11vs11, duelos, IA, minicampo |
| `CLASH_STORY_AND_EVENTS.md` | Historia, eventos, pachangas, logros |
| `CLASH_INTEGRATION_ARCHITECTURE.md` | Estructura código, rutas, aislamiento |
| `CLASH_INTEGRATION_AUDIT.md` | Estado actual Eternal XI Flutter |

---

## 22. Implementación incremental Flutter (post-roadmap)

| Fase | Entregable |
|---|---|
| **21** | Duplicados y árbol de habilidades lineal SR/LR/XI (`CLASH_CARD_SYSTEM.md`) |
| **22** | Pantalla central `/clash/inventory` — solo visualización |
| **23** | Invocar — gacha local MVP (banner, rates, gemas historia) |
| **24** | Historial local de invocaciones (`/clash/summon/history`) |
| **25** | Pity SR local cada 30 cartas por banner |
| **26** | Tickets locales de invocación |
| **27** | Tienda local con monedas |

### Fase 22 — Inventario Clash

- Pantalla **Inventario** accesible desde **Equipo** (`/clash/inventory`).
- Agrega sin duplicar almacenamiento:
  - materiales EXP (`clash_exp_material_inventory_v1`)
  - libros de técnica (`clash_technique_book_inventory_v1`)
  - materiales de evolución (`clash_evolution_material_inventory_v1`)
  - objetos de partido (kit provisional desde `match_items.json` / `defaultKit`)
- **Solo lectura:** los usos siguen en detalle de carta (EXP, libros, evolución) o descanso de partido (objetos).
- Objetos de partido: UI indica **«Kit provisional por partido»**; sin inventario global ni cambio de reglas de uso.

### Fase 23 — Invocar (gacha local)

- Tab **Invocar** funcional con simulación local (sin backend ni compras reales).
- Banner `starter-banner-001`, probabilidades provisionales, single/multi/daily discount.
- Gemas desde progreso de Historia (`walletGems`).
- Concesión de cartas vía `grantGachaCard` (nueva / duplicado / `evolvedRarity`).

**Pendiente:** backend gacha, banners reales, pity definitivo, animaciones, economía real y tienda.

### Fase 24 — Historial de invocaciones

- Cada tirada exitosa se guarda en `clash_gacha_history_v1` (máx. 50 entradas).
- Pantalla **Historial de invocaciones** en `/clash/summon/history`.
- Acceso desde Invocar y desde el sheet de resultado («Ver historial»).
- Muestra fecha, banner, tipo, gemas, cartas y estado (nueva / duplicado / mejora).

**Nota:** historial local provisional; no es backend ni auditoría legal.

**Pendiente:** pity definitivo, backend, banners reales, economía/legal final.

### Fase 25 — Pity SR local

- Pity SR cada **30 cartas** obtenidas por banner (`clash_gacha_pity_v1`).
- Cuenta por carta: single/daily +1, multi +10.
- Al llegar a 30 se fuerza SR pity y el contador vuelve a 0.
- **SR natural no reinicia pity**; solo el SR obtenido por pity reinicia.
- La garantía multi SR sigue activa; si el pity ya dio SR, no aplica garantía extra.
- UI: contador Pity SR, chips en resultado e historial.

**Pendiente:** backend pity, LR/XI, soft pity, economía/legal final.

### Fase 26 — Tickets locales

- Tickets de invocación locales (`clash_gacha_ticket_inventory_v1`).
- Ticket inicial: `starter-single-ticket` ×3 para banner inicial.
- Pull type `ticketSingle`: consume 1 ticket, no gasta gemas, genera 1 carta.
- **Los tickets cuentan para pity** (+1 al contador del banner).
- Inventario central: categoría Tickets con filtro dedicado.
- Adaptador de recompensas de historia preparado (`starter-single-ticket`).

**Pendiente:** backend tickets, compras reales, economía/legal final.

### Fase 27 — Tienda local con monedas

- Tienda local en pestaña **Tienda** (`shop_products.json`).
- Compra con `walletCoins` de historia Clash.
- Productos: EXP, libro técnica, insignia R, ticket inicial.
- Sin compras reales ni backend.
- Reembolso de monedas si falla la concesión de recompensas.

**Pendiente:** límites, tienda eventos, backend, economía final.

### Fase 28 — Misiones diarias locales

- Submódulo `lib/features/clash/missions/` con catálogo `daily_missions.json`.
- Persistencia local `clash_daily_missions_v1` con fecha `yyyy-MM-dd`.
- Reset automático al cambiar el día local (sin servidor).
- Progreso por eventos: partido, victoria, invocación, compra tienda, uso EXP, mejora supertécnica.
- Reclamación local de recompensas (monedas, gemas, materiales, libros).
- Pantalla `/clash/missions` y tarjeta resumen en Inicio Clash.

**Pendiente:** misiones semanales, logros globales, backend, sincronización, notificaciones, pase de batalla.

### Fase 29 — Logros locales permanentes

- Submódulo `lib/features/clash/achievements/` con catálogo `achievements.json`.
- Persistencia local `clash_achievements_v1` **sin reset diario** (a diferencia de misiones diarias).
- Progreso acumulado permanentemente; cada logro se reclama una sola vez.
- Eventos: partido, victoria, invocación (cartas por tirada: single/daily/ticket +1, multi +10), colección única, subida de nivel, mejora de técnica, evolución, nodo de árbol.
- Reclamación local vía `ClashShopGrantService` (monedas, gemas, materiales, tickets).
- Pantalla `/clash/achievements` y tarjeta resumen en Inicio Clash.

**Pendiente:** backend de logros, Google Play Games, logros secretos, logros de eventos reales, cinemáticas, notificaciones, pase de batalla.

### Fase 30 — Misiones semanales locales

- Submódulo semanal en `lib/features/clash/missions/` con catálogo `weekly_missions.json`.
- Persistencia local `clash_weekly_missions_v1` con `weekKey` (lunes local `yyyy-MM-dd`).
- Reset automático al cambiar de semana local (sin servidor).
- Objetivos más largos y recompensas mejores que las diarias.
- `ClashMissionProgressEventHub` distribuye eventos a diarias, semanales y logros.
- Pantalla `/clash/weekly-missions` y tarjeta resumen en Inicio Clash.

**Pendiente:** backend, calendario servidor, misiones mensuales, eventos temporales reales, pase de batalla, notificaciones.

---

## Fase 31 — Noticias / avisos locales

**Estado:** implementada (local).

- Catálogo en `assets/data/clash/news.json` (actualizaciones, eventos, banners, avisos).
- Sin backend, CMS ni push reales.
- Lectura persistida en `clash_news_read_v1` (`readNewsIds`, `lastOpenedAt` opcional).
- Pantalla `/clash/news` con filtros y expansión inline al pulsar.
- Tarjeta compacta “Noticias” en Inicio con contador de no leídas.

**Pendiente:** noticias remotas, panel admin, push notifications, imágenes remotas, deep links.

---

## Fase 32 — Buzón de regalos local

**Estado:** implementada (local).

- Catálogo en `assets/data/clash/gifts.json`.
- Sin backend, push ni regalos personalizados remotos.
- Reclamaciones persistidas en `clash_gifts_v1` (`claimedGiftIds`, `lastOpenedAt` opcional).
- Recompensas vía `ClashShopGrantService` + wallet historia (monedas/gemas).
- Pantalla `/clash/gifts` y tarjeta compacta en Inicio.

**Pendiente:** backend de regalos, push, gifts personalizados, expiración servidor, panel admin.

---

## Fase 33 — Eventos de personaje local (MVP)

**Estado:** implementada (local).

- Catálogo en `assets/data/clash/character_events.json` (evento inicial «Entrenamiento de Arin»).
- Sin backend, calendario servidor, tienda de evento ni cinemáticas reales.
- Progreso en `clash_character_events_v1` con `firstClear` / `repeatRewards`.
- Fases **story** (lectura) y **match** (7vs7 reutilizando motor existente).
- Rutas `/clash/events` y anidadas; tarjeta «Eventos» en Inicio.

**Pendiente:** eventos temporales con fecha servidor, tienda/moneda de evento, ranking, dificultades avanzadas, cinemáticas, backend.

---

## Fase 34 — Limpieza de warnings Clash

**Estado:** implementada.

- Reducción de warnings/info del analyzer en `lib/features/clash` y `test/features/clash`.
- Sin cambios de lógica ni nuevas features.

---

## Fase 35 — Hub visual Inicio Clash

**Estado:** implementada (local).

- Inicio Clash reorganizado como hub principal tipo Dokkan: cabecera con recursos, accesos destacados (Historia, Eventos, Equipo, Invocar), actividad diaria compacta, avisos/recompensas y evento destacado.
- Widgets: `ClashHomeHeader`, `ClashHomePrimaryActionGrid`, `ClashHomeSectionTitle`, `ClashHomeCompactCard`, `ClashHomeFeaturedEventCard`, `ClashShopHomeCard`.
- Sin cambios de rutas, progreso, grants ni backend.

**Pendiente:** arte final, banners animados, carousel remoto, backend remoto.

---

*Roadmap sujeto a revisión tras confirmación del equipo. No iniciar fase 1 sin aprobación explícita.*
