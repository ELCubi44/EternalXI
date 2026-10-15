extends SceneTree

const MatchRules = preload("res://scripts/match_engine.gd")
const Profile = preload("res://scripts/profile.gd")
var failures: int = 0
var checks: int = 0
var cards: Dictionary = {}

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/cards.json"))
	for card in catalog.cards:
		cards[int(card.playerId)] = card
		check(ResourceLoader.exists("res://art/portraits/%s.png" % int(card.playerId)), "Retrato sin empaquetar")
	var profile = Profile.new()
	profile.data = profile.defaults()
	var lineup: Array = profile.data.lineup
	var match_game = MatchRules.new()
	match_game.begin(lineup, 434, {}, 12, cards)
	check(match_game.rival_risk(false, true) < match_game.rival_risk(), "Replegar reduce el riesgo")
	var defense_before = int(match_game.state.defense_strength)
	var trained = MatchRules.new()
	trained.begin(lineup, 434, {"435": 5}, 12, cards)
	check(int(trained.state.defense_strength) > defense_before, "Entrenar al portero mejora la defensa real")
	check(not match_game.can_act("shot"), "No debe tirar fuera del área")
	var initial = match_game.state.duplicate(true)
	check(not match_game.act("shot", cards[434]).accepted, "Acción ilegal rechazada")
	check(match_game.state == initial, "Una acción ilegal no cambia la partida")
	match_game.state.zone = 2
	match_game.state.energy = 29
	check(not match_game.can_act("special"), "Técnica requiere energía")
	match_game.state.energy = 30
	check(match_game.can_act("special"), "Técnica disponible en el área con energía")
	match_game.act("special", cards[444])
	check(int(match_game.state.energy) == 0, "La técnica consume 30")
	# Compara una continuación con su guardado JSON real, incluidos enteros RNG.
	var resumed = MatchRules.new()
	resumed.restore(JSON.parse_string(JSON.stringify(match_game.state)))
	var first = match_game.act("pass", cards[434])
	var second = resumed.act("pass", cards[434])
	check(first == second and match_game.state.rng_state == resumed.state.rng_state, "Reabrir conserva el azar")
	for seed_value in range(200):
		var game = MatchRules.new()
		game.begin(lineup, 434, {}, seed_value, cards)
		var actions = 0
		while not game.state.finished and actions < 25:
			var action = "pass"
			if int(game.state.zone) == 2:
				action = "special" if game.can_act("special") else "shot"
			game.act(action, cards[int(game.state.lineup[int(game.state.holder)])])
			actions += 1
			check(int(game.state.energy) >= 0 and int(game.state.energy) <= 100, "Energía fuera de rango")
		check(game.state.finished and actions <= 18, "Un partido debe terminar en 18 acciones")
		var balance = int(profile.data.coins)
		var reward = profile.settle(game.state, game.outcome())
		check(reward in [50, 100] and int(profile.data.coins) == balance + reward, "Recompensa incorrecta")
		check(profile.settle(game.state, game.outcome()) == 0, "No se puede cobrar dos veces")
		check(not game.can_act("pass"), "No actuar tras terminar")
	profile.data = profile.defaults()
	check(profile.train(434), "Mejora asequible")
	check(int(profile.data.coins) == 100 and int(profile.data.levels["434"]) == 2, "La mejora consume monedas")
	profile.data.coins = 0
	check(not profile.train(434), "No entrenar sin saldo")
	var path = "user://test_profile.json"
	check(profile.save(path), "Escribir guardado")
	profile.data.coins = 22
	check(profile.save(path), "Segunda escritura y backup")
	var loaded = Profile.new()
	loaded.load_profile(path)
	check(int(loaded.data.coins) == 22, "Reabrir conserva saldo")
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string("archivo interrumpido")
	file.close()
	loaded.load_profile(path)
	check(int(loaded.data.coins) == 0, "Recupera backup si el principal se corrompe")
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	print("CLASH_TESTS: %s checks, %s failures; 200 complete matches" % [checks, failures])
	quit(0 if failures == 0 else 1)
