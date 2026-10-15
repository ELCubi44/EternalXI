extends RefCounted
## RUPTURA: posesiones espaciales, defensores que siguen la huella y duelos sin dados.

const MODE = "rupture_v1"
const ENEMIES = [624, 626, 629, 632, 638, 635, 641]
const HOME_START = [[0.07, 0.50], [0.23, 0.22], [0.23, 0.78], [0.39, 0.50], [0.48, 0.17], [0.53, 0.83], [0.74, 0.50]]
const AWAY_START = [[0.95, 0.50], [0.73, 0.21], [0.75, 0.80], [0.65, 0.49], [0.43, 0.34], [0.46, 0.71], [0.84, 0.52]]
const STANCES = ["Cierra el centro", "Sale a presionar", "Espera el contacto"]
const SHOT_INTENTS = ["Busca la escuadra", "Amaga el disparo", "Carga un tiro potente"]
const COUNTERS = [1, 2, 0]
var state: Dictionary = {}
var catalog: Dictionary = {}

func begin(lineup: Array, levels: Dictionary, captain: int, cards: Dictionary) -> void:
	catalog = cards
	state = {"mode": MODE, "lineup": lineup.duplicate(), "levels": levels.duplicate(), "captain": captain,
		"score": 0, "rival_score": 0, "round": 1, "finished": false, "rewarded": false,
		"total_actions": 0, "pending": {}, "momentum": 0, "last_event": "start",
		"technique_points": 60, "super_uses": 0}
	_reset_possession()
	state.log = "Prueba un SEÑUELO con Andrés: arrastra a Till y abre el pase a Alejandro."

func restore(snapshot: Dictionary, cards: Dictionary) -> bool:
	if not valid(snapshot, cards):
		return false
	catalog = cards
	state = snapshot.duplicate(true)
	state.technique_points = clampi(int(state.get("technique_points", 60)), 0, 100)
	state.super_uses = int(state.get("super_uses", 0))
	return true

func valid(s: Dictionary, cards: Dictionary) -> bool:
	if not s.has_all(["mode", "lineup", "levels", "captain", "score", "rival_score", "round", "finished", "rewarded", "total_actions", "pending", "momentum", "last_event", "home", "away", "holder", "beats", "chain", "trail", "log"]):
		return false
	if s.mode != MODE or not s.lineup is Array or s.lineup.size() != 7 or not s.home is Array or not s.away is Array or s.home.size() != 7 or s.away.size() != 7:
		return false
	if not s.pending is Dictionary or not s.chain is Array or not s.trail is Array or not s.levels is Dictionary or s.trail.is_empty():
		return false
	if int(s.score) < 0 or int(s.score) > 3 or int(s.rival_score) < 0 or int(s.rival_score) > 3 or int(s.round) < 1 or int(s.round) > 6 or int(s.beats) > 6:
		return false
	for id in s.lineup:
		if not cards.has(int(id)):
			return false
	for pos in s.home + s.away + s.trail:
		if not pos is Array or pos.size() != 2 or not pos[0] is float and not pos[0] is int or not pos[1] is float and not pos[1] is int:
			return false
		if pos[0] < 0 or pos[0] > 1 or pos[1] < 0 or pos[1] > 1:
			return false
	if not s.pending.is_empty():
		if not s.pending.has_all(["kind", "target", "defender", "stance", "left", "right", "rupture"]):
			return false
		if s.pending.kind not in ["pass", "wall", "shot", "defend", "dribble"] or int(s.pending.stance) < 0 or int(s.pending.stance) > 2 or not cards.has(int(s.pending.left)) or not cards.has(int(s.pending.right)):
			return false
		if s.pending.kind in ["pass", "wall"] and (int(s.pending.target) < 1 or int(s.pending.target) > 6):
			return false
		if s.pending.get("super", false) or s.pending.kind == "dribble":
			if not s.pending.get("technique") is Dictionary or not s.pending.technique.has_all(["id", "name", "type", "basePower", "ptCost"]):
				return false
	return int(s.holder) >= 1 and int(s.holder) <= 6 and int(s.beats) >= 0

func _reset_possession() -> void:
	state.home = HOME_START.duplicate(true)
	state.away = AWAY_START.duplicate(true)
	# Alterna el ala de salida para que cambie la geometría de cada posesión.
	if int(state.round) % 2 == 0:
		for pos in state.home + state.away:
			pos[1] = 1.0 - float(pos[1])
	state.holder = 4
	state.beats = 6
	state.chain = [int(state.lineup[4])]
	state.trail = [state.home[4].duplicate()]
	state.pending = {}
	state.momentum = 0

func home_position(index: int) -> Vector2:
	return Vector2(float(state.home[index][0]), float(state.home[index][1]))

func away_position(index: int) -> Vector2:
	return Vector2(float(state.away[index][0]), float(state.away[index][1]))

func rupture_ready() -> bool:
	if state.chain.size() < 3 or home_position(int(state.holder)).x < 0.50:
		return false
	var min_y = 1.0
	var max_y = 0.0
	var max_x = 0.0
	for pos in state.trail:
		min_y = minf(min_y, float(pos[1]))
		max_y = maxf(max_y, float(pos[1]))
		max_x = maxf(max_x, float(pos[0]))
	return max_y - min_y >= 0.35 and max_x - float(state.trail[0][0]) >= 0.12

func cost(action: String) -> int:
	return 2 if action == "wall" else 1

func nearest_marker(point: Vector2) -> int:
	var best = 1
	var distance = INF
	for i in range(1, 7):
		var d = away_position(i).distance_to(point)
		if d < distance:
			distance = d
			best = i
	return best

func marker_intent(index: int) -> Vector2:
	return away_position(index).move_toward(home_position(int(state.holder)), 0.065)

func preview(action: String, target: int = -1) -> Dictionary:
	var result = {"legal": false, "action": action, "target": target, "defender": -1, "duel": false, "reason": "", "cost": cost(action)}
	if state.is_empty() or state.finished or not state.pending.is_empty():
		result.reason = "Resuelve el duelo actual."
		return result
	if int(state.beats) < cost(action):
		result.reason = "No quedan pulsos suficientes."
		return result
	if action == "shot":
		if home_position(int(state.holder)).x < 0.60 and not rupture_ready():
			result.reason = "Llega al área o enlaza 3 jugadores, abre dos bandas y gana profundidad."
			return result
		result.legal = true
		result.duel = true
		result.defender = 0
		result.reason = "Ruptura contra Magnus" if rupture_ready() else "Tiro contra Magnus"
		return result
	if action not in ["pass", "wall", "decoy"] or target < 1 or target > 6 or target == int(state.holder):
		result.reason = "Toca otro compañero en el campo."
		return result
	result.legal = true
	var start = home_position(int(state.holder))
	var end = home_position(target)
	if action == "decoy":
		result.defender = nearest_marker(end)
		var wide_y = 0.08 if end.y < 0.35 else 0.92 if end.y > 0.65 else 0.82 if start.y < 0.5 else 0.18
		var run_to = Vector2(clampf(end.x - 0.10, 0.14, 0.86), wide_y)
		result.destination = [run_to.x, run_to.y]
		result.reason = "%s se abre y arrastra a %s" % [_short(int(state.lineup[target])), _short(ENEMIES[result.defender])]
		return result
	var nearest = INF
	for i in range(1, 7):
		var position = away_position(i)
		var closest = Geometry2D.get_closest_point_to_segment(position, start, end)
		var t = (closest - start).length() / maxf(start.distance_to(end), 0.001)
		var distance = closest.distance_to(position)
		if distance < 0.075 and t > 0.12 and distance < nearest:
			nearest = distance
			result.defender = i
	result.duel = int(result.defender) >= 0
	result.reason = "Intercepta %s: tendrás un duelo" % _short(ENEMIES[result.defender]) if result.duel else "Ruta libre. Sin sorteo: el pase llegará."
	return result

func execute(action: String, target: int = -1) -> Dictionary:
	var p = preview(action, target)
	if not p.legal:
		return {"accepted": false, "text": p.reason}
	state.beats -= int(p.cost)
	state.total_actions += 1
	if action == "decoy":
		var defender = int(p.defender)
		var destination = Vector2(p.destination[0], p.destination[1])
		state.home[target] = p.destination.duplicate()
		var moved = away_position(defender).move_toward(destination, 0.27)
		state.away[defender] = [moved.x, moved.y]
		state.log = p.reason + ". La marca deja un hueco."
		state.last_event = "decoy"
		_gain_points(5)
		_after_action()
	elif p.duel:
		_open_duel(action, target, int(p.defender))
	else:
		_complete_pass(action, target)
	return {"accepted": true, "text": state.log, "event": state.last_event}

func _complete_pass(action: String, target: int) -> void:
	_gain_points(12 if action == "wall" else 8)
	var old_holder = int(state.holder)
	var old_position = home_position(old_holder)
	var receiver = int(state.lineup[target])
	_add_chain(receiver)
	state.trail.append(state.home[target].duplicate())
	if action == "wall":
		var runner = old_position + Vector2(0.16, 0.0)
		runner.x = minf(runner.x, 0.86)
		state.home[old_holder] = [runner.x, runner.y]
		state.trail.append([runner.x, runner.y])
		state.log = "¡Pared! %s devuelve a %s, que rompe hacia el área." % [_short(receiver), _short(int(state.lineup[old_holder]))]
	else:
		state.holder = target
		state.log = "%s recibe. Las marcas siguen la huella de %s." % [_short(receiver), _short(int(state.lineup[old_holder]))]
	# Las defensas se comprometen con el lugar que acaba de abandonar el balón.
	for i in range(1, 7):
		var pos = away_position(i).move_toward(old_position, 0.065)
		state.away[i] = [pos.x, pos.y]
	if rupture_ready():
		state.log += " ¡RUPTURA lista: has conectado a tres jugadores!"
	state.last_event = action
	_after_action()

func _add_chain(id: int) -> void:
	if id not in state.chain:
		state.chain.append(id)

func _open_duel(action: String, target: int, defender: int) -> void:
	var stance = (int(state.round) + defender + state.chain.size()) % 3
	state.pending = {"kind": action, "target": target, "defender": defender, "stance": stance,
		"left": int(state.lineup[int(state.holder)]), "right": ENEMIES[defender], "rupture": rupture_ready()}
	state.last_event = "duel"
	state.log = "%s contra %s. %s." % [_short(state.pending.left), _short(state.pending.right), STANCES[stance]]

func duel_width(approach: int) -> float:
	if state.pending.is_empty():
		return 0.0
	var duel = state.pending
	var left = catalog[int(duel.left)]
	var right = catalog[int(duel.right)]
	var stat = "save" if duel.kind == "defend" else "shot" if duel.kind == "shot" else "dribble" if duel.kind == "dribble" else "pass"
	var other_stat = "shot" if duel.kind == "defend" else "save" if duel.kind == "shot" else "defense"
	var level = int(state.levels.get(str(int(duel.left)), 1))
	var width = 0.23 + (float(left.stats[stat]) + (level - 1) * 2 - float(right.stats[other_stat])) * 0.003
	width += 0.11 if approach == COUNTERS[int(duel.stance)] else -0.025
	width += 0.10 if duel.rupture and duel.kind == "shot" else 0.0
	width += mini(3, int(state.momentum)) * 0.012
	width += 0.015 if int(duel.left) == int(state.captain) else 0.0
	if duel.get("super", false):
		width += clampf(float(duel.technique.basePower) * 0.002, 0.06, 0.16)
	return clampf(width, 0.15, 0.64)

static func timing_success(pointer: float, width: float) -> bool:
	return absf(pointer - 0.5) <= width * 0.5

func resolve_duel(pointer: float, approach: int, timed_out: bool = false) -> Dictionary:
	if state.pending.is_empty():
		return {"accepted": false}
	var duel = state.pending.duplicate(true)
	var success = not timed_out and timing_success(pointer, duel_width(approach))
	var perfect = success and absf(pointer - 0.5) < 0.035
	state.pending = {}
	if perfect:
		state.momentum += 1
		_gain_points(5)
	var result_text = ""
	if duel.kind == "defend":
		if success:
			result_text = "¡%s detiene a %s!" % [_short(duel.left), _short(duel.right)]
		else:
			state.rival_score += 1
			result_text = "Gol de %s. %s no llega." % [_short(duel.right), _short(duel.left)]
		_end_round()
	elif duel.kind == "shot":
		if success:
			state.score += 1
			result_text = "¡GOOOL de %s!%s" % [_short(duel.left), " ¡RUPTURA!" if duel.rupture else ""]
		else:
			result_text = "%s bloquea a %s." % [_short(duel.right), _short(duel.left)]
		if int(state.score) >= 3:
			state.finished = true
		else:
			_begin_counter()
	elif duel.kind == "dribble":
		if success:
			var origin = home_position(int(state.holder))
			var marker = away_position(int(duel.defender))
			var next = Vector2(minf(0.86, origin.x + 0.18), clampf(origin.y + (-0.10 if marker.y >= origin.y else 0.10), 0.10, 0.90))
			state.home[int(state.holder)] = [next.x, next.y]
			state.away[int(duel.defender)] = [maxf(0.14, origin.x - 0.04), origin.y]
			state.trail.append([next.x, next.y])
			result_text = "¡%s! %s deja atrás a %s y gana terreno." % [duel.technique.name, _short(duel.left), _short(duel.right)]
			_after_action()
		else:
			result_text = "%s detiene %s. ¡Contraataque!" % [_short(duel.right), duel.technique.name]
			_begin_counter()
	else:
		if success:
			_complete_pass(duel.kind, int(duel.target))
			result_text = "%s supera a %s. %s" % [_short(duel.left), _short(duel.right), state.log]
		else:
			result_text = "%s roba a %s. ¡Contraataque!" % [_short(duel.right), _short(duel.left)]
			_begin_counter()
	state.log = result_text
	state.last_event = "perfect" if perfect else "success" if success else "miss"
	return {"accepted": true, "success": success, "perfect": perfect, "text": result_text, "kind": duel.kind}

func _after_action() -> void:
	if int(state.beats) <= 0:
		_begin_counter()
		state.log += " Sin pulsos: Adler sale a la contra."

func _begin_counter() -> void:
	var striker = 641 if int(state.round) % 2 else 638
	state.pending = {"kind": "defend", "target": -1, "defender": 0, "stance": int(state.round) % 3,
		"left": int(state.lineup[0]), "right": striker, "rupture": false}

func _end_round() -> void:
	if int(state.rival_score) >= 3 or int(state.round) >= 6:
		state.finished = true
		return
	state.round += 1
	_gain_points(10)
	_reset_possession()

func _gain_points(amount: int) -> void:
	state.technique_points = mini(100, int(state.get("technique_points", 60)) + amount)

func technique_cost(technique: Dictionary) -> int:
	return maxi(20, int(technique.get("ptCost", 8)) * 3)

func _find_technique(player_id: int, technique_id: String) -> Dictionary:
	for technique in catalog[player_id].get("superTechniques", []):
		if technique.id == technique_id:
			return technique
	return {}

func preview_super(technique_id: String, target: int = -1) -> Dictionary:
	var result = {"legal": false, "reason": "Técnica no disponible."}
	if state.is_empty() or state.finished or not state.pending.is_empty() or int(state.beats) < 1:
		return result
	var technique = _find_technique(int(state.lineup[int(state.holder)]), technique_id)
	if technique.is_empty():
		return result
	result.technique = technique
	result.cost = technique_cost(technique)
	if int(state.technique_points) < int(result.cost):
		result.reason = "Necesitas %s PT. Enlaza pases para recargar." % result.cost
		return result
	if technique.type == "shot":
		if home_position(int(state.holder)).x < 0.55 and not rupture_ready():
			result.reason = "Avanza hacia la portería antes de usar este disparo."
			return result
		result.reason = "Tiro especial: más potencia en el duelo contra Magnus."
	elif technique.type == "dribble":
		result.reason = "Supera a tu marca y avanza con un regate especial."
	elif technique.type == "pass":
		var route = preview("pass", target)
		if not route.legal:
			result.reason = "Selecciona antes al receptor en el campo."
			return result
		result.reason = "Pase especial con refuerzo en el duelo de intercepción."
	else:
		result.reason = "Esta técnica se utiliza al defender."
		return result
	result.legal = true
	return result

func execute_super(technique_id: String, target: int = -1) -> Dictionary:
	var check = preview_super(technique_id, target)
	if not check.legal:
		return {"accepted": false, "text": check.reason}
	var technique = check.technique
	state.technique_points -= int(check.cost)
	state.super_uses += 1
	state.beats -= 1
	state.total_actions += 1
	if technique.type == "dribble":
		_open_duel("dribble", -1, nearest_marker(home_position(int(state.holder))))
	elif technique.type == "shot":
		_open_duel("shot", -1, 0)
	else:
		var route = preview_route_for_super(target)
		if int(route.defender) >= 0:
			_open_duel("pass", target, int(route.defender))
		else:
			_complete_pass("pass", target)
			state.momentum += 1
	if not state.pending.is_empty() and state.pending.kind != "defend":
		state.pending["super"] = true
		state.pending.technique = technique.duplicate(true)
	state.log = "¡%s activa %s!" % [_short(int(state.lineup[int(state.holder)])), technique.name]
	return {"accepted": true, "technique": technique, "text": state.log}

func preview_route_for_super(target: int) -> Dictionary:
	# Previsualiza sin volver a consumir ni exigir un pulso ya gastado.
	var beats = int(state.beats)
	state.beats = maxi(1, beats)
	var route = preview("pass", target)
	state.beats = beats
	return route

func available_duel_techniques() -> Array:
	if state.pending.is_empty() or state.pending.get("super", false):
		return []
	var kind = state.pending.kind
	var needed = "save" if kind == "defend" else "shot" if kind == "shot" else "dribble" if kind == "dribble" else "pass"
	var result: Array = []
	for technique in catalog[int(state.pending.left)].get("superTechniques", []):
		if technique.type == needed and int(state.technique_points) >= technique_cost(technique):
			result.append(technique)
	return result

func activate_duel_technique(technique_id: String) -> Dictionary:
	for technique in available_duel_techniques():
		if technique.id == technique_id:
			state.technique_points -= technique_cost(technique)
			state.super_uses += 1
			state.pending["super"] = true
			state.pending.technique = technique.duplicate(true)
			return {"accepted": true, "technique": technique}
	return {"accepted": false}

func outcome() -> String:
	return "victory" if int(state.score) > int(state.rival_score) else "draw" if int(state.score) == int(state.rival_score) else "defeat"

func _short(id: int) -> String:
	var name: String = catalog[int(id)].name
	var words = name.split(" ")
	return words[0] + " " + words[1] if words.size() > 1 else name
