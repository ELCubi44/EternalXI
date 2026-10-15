extends RefCounted
## Guardado separado del cliente Flutter; se puede recuperar la copia anterior.

const SAVE_PATH = "user://clash_profile_v1.json"
var data: Dictionary = {}

func defaults() -> Dictionary:
	return {"schema": 1, "coins": 150, "wins": 0, "played": 0, "levels": {},
		"lineup": [435, 437, 438, 440, 434, 443, 444], "captain": 434, "match": {}}

func load_profile(path: String = SAVE_PATH) -> void:
	data = defaults()
	for candidate in [path, path + ".bak"]:
		if not FileAccess.file_exists(candidate):
			continue
		var parser = JSON.new()
		if parser.parse(FileAccess.get_file_as_string(candidate)) != OK:
			continue
		var parsed = parser.data
		if parsed is Dictionary and valid(parsed):
			data = parsed
			return

func valid(value: Dictionary) -> bool:
	if value.get("schema") != 1 or not value.get("lineup") is Array or value.lineup.size() != 7:
		return false
	return value.get("levels") is Dictionary and value.get("match") is Dictionary and value.has("coins") and value.has("captain") and value.has("wins") and value.has("played")

func save(path: String = SAVE_PATH) -> bool:
	var file = FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "", true, true))
	file.close()
	var abs_path = ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		var backup_result = DirAccess.copy_absolute(abs_path, abs_path + ".bak")
		if backup_result != OK:
			return false
	return DirAccess.rename_absolute(abs_path + ".tmp", abs_path) == OK

func train(player_id: int) -> bool:
	var key = str(player_id)
	var level = int(data.levels.get(key, 1))
	var cost = level * 50
	if level >= 10 or int(data.coins) < cost:
		return false
	data.coins -= cost
	data.levels[key] = level + 1
	return true

func settle(match_state: Dictionary, outcome: String) -> int:
	if not match_state.get("finished", false) or match_state.get("rewarded", false):
		return 0
	var reward = 100 if outcome == "victory" else 50
	data.coins += reward
	data.played += 1
	if outcome == "victory":
		data.wins += 1
	match_state.rewarded = true
	data.match = match_state.duplicate(true)
	return reward
