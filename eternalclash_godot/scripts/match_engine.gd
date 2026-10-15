extends RefCounted
## Reglas propias de la demo. La presentación no decide los resultados.

var rng = RandomNumberGenerator.new()
var state: Dictionary = {}

func begin(lineup: Array, captain_id: int, levels: Dictionary, match_seed: int, catalog: Dictionary = {}) -> void:
	rng.seed = match_seed
	var defense_strength = 45
	if not catalog.is_empty():
		var keeper = catalog[int(lineup[0])]
		var keeper_level = int(levels.get(str(int(lineup[0])), 1))
		var defense_total = 0
		for id in lineup.slice(1):
			defense_total += int(catalog[int(id)].stats.defense) + (int(levels.get(str(int(id)), 1)) - 1) * 2
		defense_strength = int(keeper.stats.save) + (keeper_level - 1) * 2 + defense_total / 12
	state = {"lineup": lineup.duplicate(), "captain": captain_id, "levels": levels.duplicate(),
		"defense_strength": defense_strength,
		"seed": match_seed, "rng_state": str(rng.state), "score": 0, "rival_score": 0,
		"turn": 1, "zone": 0, "energy": 45, "holder": 4, "combo": 0,
		"finished": false, "rewarded": false, "log": "Recuperamos el balón. Construye la jugada."}

func restore(snapshot: Dictionary) -> void:
	state = snapshot.duplicate(true)
	rng.seed = int(state.seed)
	rng.state = int(state.rng_state)

func chance(action: String, card: Dictionary) -> int:
	var stat = "pass" if action == "pass" else "dribble"
	if action in ["shot", "special"]:
		stat = "shot"
	var level = int(state.levels.get(str(card.playerId), 1))
	var boost = 6 if int(state.captain) in state.lineup else 0
	var value = 52 + int(card.stats[stat]) / 3 + level * 2 + boost
	if action == "shot":
		value = 40 + int(card.stats.shot) / 3 + level * 2 + boost + int(state.combo) * 5
	if action == "special":
		value += 14 + int(state.combo) * 4
	return clampi(value, 35, 94)

func can_act(action: String) -> bool:
	if state.is_empty() or state.finished:
		return false
	if action == "shot":
		return int(state.zone) >= 2
	if action == "special":
		return int(state.zone) >= 2 and int(state.energy) >= 30
	return action in ["pass", "dribble", "recover"]

func act(action: String, card: Dictionary) -> Dictionary:
	if not can_act(action):
		return {"accepted": false, "text": "Acción no disponible."}
	var success = rng.randi_range(1, 100) <= chance(action, card)
	var text = ""
	var event = action
	if action == "recover":
		state.energy = mini(100, int(state.energy) + 20)
		text = "Replegamos: +20 de energía. Adler intenta atacar."
		_rival_attack(false, true)
	elif action == "pass":
		state.energy = mini(100, int(state.energy) + 12)
		if success:
			state.zone = mini(2, int(state.zone) + 1)
			state.holder = 1 + (int(state.holder) % 6)
			state.combo = mini(3, int(state.combo) + 1)
			text = "Pase enlazado. Avanzamos y ganamos +12 de energía."
		else:
			text = "Adler intercepta el pase."
			_rival_attack(false)
	elif action == "dribble":
		state.energy = mini(100, int(state.energy) + 7)
		if success:
			state.zone = mini(2, int(state.zone) + 1)
			state.combo = mini(3, int(state.combo) + 1)
			text = "%s supera a su marca." % card.name
		else:
			text = "Perdemos el duelo de regate."
			_rival_attack(false)
	else:
		if action == "special":
			state.energy -= 30
		if success:
			state.score += 1
			text = "¡GOL de %s!" % card.name
			event = "goal"
		else:
			text = "¡Magnus detiene el disparo!"
			event = "save"
		state.zone = 0
		state.combo = 0
		if int(state.score) < 3:
			_rival_attack(false)
	state.turn += 1
	# El rival también presiona aunque encadenemos pases seguros.
	if action in ["pass", "dribble"] and success and int(state.turn) % 4 == 0:
		_rival_attack(true)
	state.finished = int(state.score) >= 3 or int(state.rival_score) >= 3 or int(state.turn) > 18
	state.log = text + ("  " + str(state.get("rival_log", "")) if state.has("rival_log") else "")
	state.erase("rival_log")
	state.rng_state = str(rng.state)
	return {"accepted": true, "text": state.log, "event": event}

func rival_risk(pressing: bool = false, recovering: bool = false) -> int:
	var base = 32 if not pressing else 23
	return clampi(base - int(state.get("defense_strength", 45)) / 8 - (10 if recovering else 0), 5, 40)

func _rival_attack(keep_zone: bool, recovering: bool = false) -> void:
	var risk = rival_risk(keep_zone, recovering)
	if rng.randi_range(1, 100) <= risk:
		state.rival_score += 1
		state.rival_log = "Adler marca al contraataque."
	else:
		state.rival_log = "Hugo contiene el ataque rival."
	if not keep_zone:
		state.zone = 0
		state.holder = 4
		state.combo = 0

func outcome() -> String:
	if int(state.score) > int(state.rival_score):
		return "victory"
	return "draw" if int(state.score) == int(state.rival_score) else "defeat"
