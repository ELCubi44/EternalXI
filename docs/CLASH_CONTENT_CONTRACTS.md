# Contratos de contenido Clash (Fase 55)

Documento de referencia para IDs, assets locales y validación técnica antes de backend/sync.

## Convenciones de IDs

- **Formato:** `kebab-case` o `snake_case` según dominio (`exi-n-gk-001`, `event-arin-training`, `basic-training-manual`).
- **Unicidad:** cada `id` debe ser único dentro de su asset (`cards`, `rivals`, `missions`, etc.).
- **No vacíos:** strings críticos (`id`, `name`, `title`) no pueden estar vacíos.
- **Referencias:** `cardId`, `rivalTeamId`, `bannerId` deben existir en el catálogo correspondiente.

## Assets locales actuales

| Asset | Clave raíz | Uso |
|-------|------------|-----|
| `cards.json` | `cards` | Catálogo de cartas jugables |
| `exp_materials.json` | `materials` | Manuales de entrenamiento |
| `technique_books.json` | `books` | Libros de supertécnica |
| `evolution_materials.json` | `materials` | Insignias de evolución |
| `gacha_banners.json` | `banners` + `rates` | Banners y probabilidades |
| `gacha_tickets.json` | `tickets` | Tickets de invocación |
| `shop_products.json` | `products` | Tienda local |
| `daily_missions.json` | `missions` | Misiones diarias |
| `weekly_missions.json` | `missions` | Misiones semanales |
| `achievements.json` | `achievements` | Logros |
| `gifts.json` | `gifts` | Buzón de regalos |
| `news.json` | `news` | Noticias locales |
| `character_events.json` | `events` | Eventos de personaje |
| `rivals.json` | `rivals` | Equipos rivales 7v7 |
| `help_topics.json` | `topics` | Guía / ayuda |
| `story/sagas.json` | `sagas` | Sagas de historia |
| `story/chapter_01.json` | `chapter` | Capítulo y niveles |

Código compartido de IDs de recompensa: `lib/features/clash/shared/rewards/domain/clash_reward_ids.dart`.

## Reward IDs válidos (concedibles)

| Tipo | IDs |
|------|-----|
| Wallet | `coins`, `gems` (campos numéricos, no IDs) |
| EXP | `basic-training-manual`, `advanced-training-manual`, `master-training-manual` |
| Libros | `basic-technique-book`, `advanced-technique-book`, `master-technique-book` |
| Evolución | `insignia-r`, `insignia-sr` |
| Tickets | `starter-single-ticket` |
| Cartas | cualquier `id` presente en `cards.json` |
| Carta destacada | `featuredCardId` → carta existente |
| Roster inicial | `starterRosterKey`: `eternal_xi_starter_n` |

### Ítems narrativos de historia

Los `items` en recompensas de historia pueden ser **flavor** (no concedibles), p. ej. `training-cone`. Solo se validan como grant si están en `ClashRewardIds.storyItemToExpMaterial` (p. ej. `basic-book` → `basic-training-manual`).

## Referencias cruzadas

- **Eventos:** `featuredCardId` ∈ `cards.json`; stages `match` → `rivalTeamId` ∈ `rivals.json`.
- **Historia:** niveles `match` → `rivalTeamId` ∈ `rivals.json`; `starterRosterKey` conocido.
- **Gacha:** `poolCardIds` (si no vacío) ⊆ `cards.json`; tickets `compatibleBannerIds` ⊆ `gacha_banners.json`.
- **Tienda / misiones / logros / regalos:** grants/rewards usan solo IDs del contrato anterior.
- **Ayuda:** `relatedRoutes.path` ∈ `clashHelpKnownRoutes` (`clash_help_topic_screen.dart`).

## Contrato de cartas (`cards.json`)

- `rarity`: `n`, `r`, `sr`, `lr`, `xi`
- `position`: las 7 posiciones canónicas (`goalkeeper`, `centreBack`, `fullBack`, `defensiveMidfielder`, `attackingMidfielder`, `winger`, `striker`)
- `style`: `picaro`, `potente`, `agil`, `preciso`, `valiente`
- `stats`: `save`, `defense`, `pass`, `dribble`, `shot`, `techniquePoints`, `stamina` (≥ 0)
- `level` > 0
- `superTechniques`: `type` (`save`, `defense`, `dribble`, `shot`), `style` válido, `basePower` > 0, `ptCost` > 0, `level` de supertécnica válido

## Contrato de rivales (`rivals.json`)

- `lineup7v7`: exactamente **7** jugadores
- Las **7 posiciones oficiales** deben aparecer una vez cada una
- Mismas reglas de stats/nivel/estilo/rareza/supertécnicas que cartas

## Contrato de story / events

- IDs de nivel/stage únicos en su ámbito
- `firstClearRewards` / `repeatRewards` / `rewards` siguen contrato de rewards
- Objetivos de partido (`matchObjectives`) con `rewards` opcionales validadas igual

## Contrato de gacha

- `rates`: suma de porcentajes = **100**
- Costes `singleCost`, `multiCost`, `multiCount`, `dailyDiscountCost` > 0
- Pity: umbral por defecto en código (`ClashGachaPityState.defaultThreshold` = 30) > 0
- Multi garantiza SR en última carta (motor `ClashGachaEngine`)

## Contrato de shop / missions

- Productos: `costCoins` > 0, `grants` no vacío, `type` ∈ `expMaterial|techniqueBook|evolutionMaterial|ticket`
- Misiones/logros: `target` > 0, `reward` con cantidades > 0 cuando aplica

## Validación automatizada

```bash
cd eternalxi_front
flutter test test/features/clash/assets/clash_assets_validation_test.dart
```

Helpers: `test/features/clash/assets/clash_assets_validation_helpers.dart`.

Suite completa Clash (incluye esta validación):

```bash
flutter test test/features/clash/
```

## Pendiente (post-Fase 55)

- Sync server-side e idempotencia remota
- Validación en CI obligatoria
- Esquema versionado (`schemaVersion`) para migraciones — ver [`CLASH_LOCAL_STORAGE.md`](./CLASH_LOCAL_STORAGE.md)
- Editor/generador de contenido
