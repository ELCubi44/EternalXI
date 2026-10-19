extends SceneTree
const Rules = preload("res://scripts/rupture_engine.gd")
const Profile = preload("res://scripts/profile.gd")
var checks = 0
var failures = 0
var cards: Dictionary = {}
var lineup: Array = [435, 437, 438, 440, 434, 443, 444]

func check(condition: bool, message: String) -> void:
 checks += 1
 if not condition:
  failures += 1
  push_error(message)

func _initialize() -> void:
 call_deferred("_run")

func fresh():
 var game = Rules.new()
 game.begin(lineup, {}, 434, cards)
 return game

func _run() -> void:
 var catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/cards.json"))
 for card in catalog.cards:
  cards[int(card.playerId)] = card
  check(ResourceLoader.exists("res://art/portraits/%s.png" % int(card.playerId)), "Falta retrato")
 var g = fresh()
 check(not g.preview("shot").legal, "No hay tiro temprano sin Ruptura")
 check(not g.preview("pass", 4).legal, "No pasar al poseedor")
 check(not g.preview("pass", 0).legal, "No pasar al portero")
 check(not g.preview("unknown", 5).legal, "Acción desconocida rechazada")
 var safe = fresh()
 for i in range(1, 7):
  safe.state.away[i] = [.97, .98]
 safe.execute("pass", 1)
 safe.execute("pass", 2)
 check(safe.state.chain.size() == 3 and not safe.rupture_ready(), "Pasar hacia atrás no carga Ruptura sin profundidad")
 var old = g.state.duplicate(true)
 check(not g.execute("pass", 4).accepted and g.state == old, "Acción ilegal sin efectos")
 var space = fresh()
 check(space.preview("pass", 3).duel, "Till amenaza el pase central al principio")
 space.execute("decoy", 1)
 check(not space.preview("pass", 3).duel, "El señuelo de Andrés abre una ruta realmente libre")
 var p = g.preview("decoy", 5)
 var marker = int(p.defender)
 var marker_before = g.away_position(marker)
 var ball_before = g.home_position(4)
 g.execute("decoy", 5)
 check(g.away_position(marker).distance_to(marker_before) > .1, "El señuelo mueve físicamente al rival")
 check(g.home_position(4) == ball_before and int(g.state.holder) == 4, "El señuelo no mueve el balón")
 check(int(g.state.beats) == 5, "El señuelo cuesta un pulso")
 g = fresh()
 for i in range(1, 7):
  g.state.away[i] = [.97, .98]
 var old_x = g.home_position(4).x
 g.execute("wall", 3)
 check(g.state.pending.is_empty(), "Pared por ruta libre sin dados")
 check(int(g.state.holder) == 4 and g.home_position(4).x > old_x, "Pared devuelve al corredor que avanza")
 check(int(g.state.beats) == 4 and g.state.chain.size() == 2, "Pared cuesta dos y enlaza dos identidades")
 g.execute("pass", 5)
 check(g.rupture_ready(), "Tres identidades cargan Ruptura")
 check(g.preview("shot").legal, "Ruptura permite remate incluso desde fuera del área")
 g.execute("shot")
 check(g.state.pending.right == 624 and g.state.pending.left == 443, "Duelo identifica tirador y portero reales")
 var counter = Rules.COUNTERS[int(g.state.pending.stance)]
 check(g.duel_width(counter) > g.duel_width((counter + 1) % 3), "Leer intención ensancha ventana")
 var resumed = Rules.new()
 check(resumed.restore(JSON.parse_string(JSON.stringify(g.state)), cards), "Se reanuda un duelo pendiente")
 check(equivalent(resumed.state, g.state), "Estado exacto tras JSON")
 var result = g.resolve_duel(.5, counter)
 var copied = resumed.resolve_duel(.5, counter)
 check(result == copied and equivalent(g.state, resumed.state), "Mismo gesto, mismo resultado; sin azar")
 check(int(g.state.score) == 1 and g.state.pending.kind == "defend", "Gol y contraataque manual")
 g.resolve_duel(.5, 0)
 check(int(g.state.round) == 2 and int(g.state.rival_score) == 0, "Parada manual da siguiente posesión")
 g = fresh()
 for i in range(6):
  g.execute("decoy", 5)
 check(g.state.pending.kind == "defend" and int(g.state.beats) == 0, "Los pulsos evitan posesión infinita")
 g.resolve_duel(0.0, 0, true)
 check(int(g.state.rival_score) == 1, "Fallar o agotar duelo defensivo concede gol")
 # Prueba desenlaces distintos con decisiones y gestos controlados, no semillas.
 var outcomes: Dictionary = {}
 for scenario in range(120):
  g = fresh()
  var operations = 0
  while not g.state.finished and operations < 120:
   if not g.state.pending.is_empty():
    var defense = g.state.pending.kind == "defend"
    var hit = scenario % 3 == 0 or (scenario % 3 == 1 and not defense)
    g.resolve_duel(.5 if hit else 0.0, Rules.COUNTERS[int(g.state.pending.stance)])
   elif g.preview("shot").legal:
    g.execute("shot")
   else:
    var target = 1 + ((int(g.state.holder) + 1 + scenario % 4) % 6)
    if target == int(g.state.holder):
     target = 1 + target % 6
    g.execute("pass", target)
   operations += 1
   check(int(g.state.beats) >= 0 and int(g.state.beats) <= 6, "Pulsos válidos")
  check(g.state.finished and operations < 120, "El partido termina con cualquier perfil probado")
  outcomes[g.outcome()] = true
  var profile = Profile.new()
  profile.data = profile.defaults()
  var balance = int(profile.data.coins)
  var reward = profile.settle(g.state, g.outcome())
  check(reward in [50,100] and int(profile.data.coins) == balance + reward, "Recompensa correcta")
  check(profile.settle(g.state, g.outcome()) == 0, "Recompensa no duplicada")
  check(not g.execute("decoy", 5).accepted, "No actuar tras acabar")
 check(outcomes.has("victory") and outcomes.has("defeat"), "Las decisiones y el pulso cambian el desenlace")
 var bad = fresh().state.duplicate(true)
 bad.home[0] = "error"
 check(not Rules.new().restore(bad, cards), "Guardado malformado se rechaza")
 bad = fresh().state.duplicate(true)
 bad.pending = {"kind": "shot"}
 check(not Rules.new().restore(bad, cards), "Duelo incompleto se rechaza sin romper el arranque")
 var special = fresh()
 var dribble = "eternal-xi-n-wg-010-st1"
 var shot = "eternal-xi-n-wg-010-st2"
 check(special.preview_super(dribble).legal, "El regate especial está disponible al inicio")
 check(not special.preview_super(shot).legal, "El tiro especial exige ganar terreno")
 var x_before = special.home_position(4).x
 var activated = special.execute_super(dribble)
 check(activated.accepted and int(special.state.technique_points)==33, "Regate del Eclipse cuesta 27 PT")
 check(special.state.pending.kind=="dribble" and special.state.pending.technique.name=="Regate del Eclipse", "La técnica real se incorpora al duelo")
 check(not special.execute_super(dribble).accepted, "No activar otra técnica sobre el duelo pendiente")
 var stored = Rules.new()
 check(stored.restore(JSON.parse_string(JSON.stringify(special.state)),cards), "Reanuda un duelo especial sin volver a cobrar")
 check(int(stored.state.technique_points)==33, "PT conservados al reabrir")
 special.resolve_duel(.5,Rules.COUNTERS[int(special.state.pending.stance)])
 check(special.home_position(4).x > x_before+.15, "El regate especial gana terreno real")
 check(special.preview_super(shot).legal, "El avance habilita Disparo Valestia")
 var normal = fresh()
 normal.state.home[4] = [.70,.17]
 normal.execute("shot")
 var width_before = normal.duel_width(1)
 var pt_before = int(normal.state.technique_points)
 check(normal.activate_duel_technique(shot).accepted, "Activar supertiro durante duelo")
 check(normal.duel_width(1)>width_before, "Supertécnica mejora la ventana de acierto")
 check(int(normal.state.technique_points)==pt_before-30, "Disparo Valestia cuesta 30 PT")
 check(not normal.activate_duel_technique(shot).accepted, "No cobrar técnica dos veces en un duelo")
 normal.resolve_duel(.5,1)
 normal.state.technique_points = 60
 var save_technique = "eternal-xi-n-gk-001-st1"
 check(normal.activate_duel_technique(save_technique).accepted, "Muro de Puños activable como superparada")
 check(normal.state.pending.technique.name=="Muro de Puños", "Nombre real de superparada")
 var empty = fresh()
 empty.state.technique_points = 0
 var snapshot = empty.state.duplicate(true)
 check(not empty.execute_super(dribble).accepted and empty.state==snapshot, "Sin PT, no hay cargo ni movimiento")
 var legacy = fresh().state.duplicate(true)
 legacy.erase("technique_points")
 legacy.erase("super_uses")
 var migrated = Rules.new()
 check(migrated.restore(legacy,cards) and int(migrated.state.technique_points)==60, "La partida 0.2 añade PT sin perder posiciones")
 var charge = fresh()
 charge.state.technique_points = 99
 charge.execute("decoy",1)
 check(int(charge.state.technique_points)==100, "La recarga se limita a cien PT")
 var profile = Profile.new()
 profile.data = profile.defaults()
 check(profile.train(435) and int(profile.data.levels["435"]) == 2, "Entrenamiento conservado")
 var path = "user://rupture_test_profile.json"
 check(profile.save(path), "Guardado nuevo")
 var loaded = Profile.new()
 loaded.load_profile(path)
 check(equivalent(loaded.data, profile.data), "Reapertura conserva perfil")
 for suffix in ["", ".bak", ".tmp"]:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
 print("RUPTURE_TESTS: %s checks, %s failures; 120 complete matches" % [checks, failures])
 quit(0 if failures == 0 else 1)

func equivalent(a, b) -> bool:
 if (a is int or a is float) and (b is int or b is float):
  return absf(float(a) - float(b)) < 0.000000001
 if a is Array and b is Array:
  if a.size() != b.size():
   return false
  for i in range(a.size()):
   if not equivalent(a[i], b[i]):
    return false
  return true
 if a is Dictionary and b is Dictionary:
  if a.size() != b.size():
   return false
  for key in a:
   if not b.has(key) or not equivalent(a[key], b[key]):
    return false
  return true
 return a == b
