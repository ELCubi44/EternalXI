extends Control

const MatchEngine = preload("res://scripts/match_engine.gd")
const Profile = preload("res://scripts/profile.gd")
const Pitch = preload("res://scripts/pitch.gd")
const INK = Color("091322")
const PANEL = Color("13243a")
const MUTED = Color("99b2c9")
const GOLD = Color("f3cc72")
const MINT = Color("63e0b5")
var profile = Profile.new()
var game = MatchEngine.new()
var cards: Dictionary = {}
var roster: Array = []
var portraits: Dictionary = {}
var page: String = "home"
var root_column: VBoxContainer
var body: VBoxContainer
var notice: String = ""
var selected_slot: int = -1
var busy: bool = false

func _ready() -> void:
	var catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/cards.json"))
	for card in catalog.cards:
		cards[int(card.playerId)] = card
		portraits[int(card.playerId)] = load("res://art/portraits/%s.png" % int(card.playerId))
		if card.team == "Eternal XI":
			roster.append(int(card.playerId))
	profile.load_profile()
	if not _lineup_valid(profile.data.lineup):
		profile.data.lineup = profile.defaults().lineup
	if not profile.data.match.is_empty():
		var saved_match = profile.data.match
		if saved_match.has_all(["seed", "rng_state", "lineup", "holder", "energy", "finished", "score", "rival_score", "turn", "levels", "captain", "zone", "combo", "log"]) and _lineup_valid(saved_match.lineup):
			game.restore(saved_match)
	_build_theme()
	_render()

func _lineup_valid(ids: Array) -> bool:
	var unique: Dictionary = {}
	for id in ids:
		if not int(id) in roster:
			return false
		unique[int(id)] = true
	return ids.size() == 7 and unique.size() == 7 and cards[int(ids[0])].position == "goalkeeper"

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED and not profile.data.is_empty():
		_save()

func _build_theme() -> void:
	var design = Theme.new()
	design.default_font_size = 24
	design.set_color("font_color", "Label", Color("f4f7fc"))
	design.set_color("font_color", "Button", Color("f4f7fc"))
	design.set_color("font_disabled_color", "Button", Color("60768d"))
	design.set_stylebox("normal", "Button", _box(Color("203650"), 15))
	design.set_stylebox("pressed", "Button", _box(Color("345578"), 15))
	design.set_stylebox("hover", "Button", _box(Color("2b4564"), 15))
	design.set_stylebox("disabled", "Button", _box(Color("111f30"), 15))
	design.set_constant("h_separation", "GridContainer", 12)
	design.set_constant("v_separation", "GridContainer", 12)
	theme = design

func _box(color: Color, radius: int = 20) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	return style

func _label(text: String, font_size: int = 24, color: Color = Color.WHITE) -> Label:
	var node = Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return node

func _button(text: String, callback: Callable, primary: bool = false) -> Button:
	var node = Button.new()
	node.text = text
	node.custom_minimum_size.y = 78
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if primary:
		node.add_theme_stylebox_override("normal", _box(GOLD, 15))
		node.add_theme_color_override("font_color", INK)
	node.pressed.connect(callback)
	return node

func _panel(parent: Node, color: Color = PANEL) -> VBoxContainer:
	var panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(color))
	parent.add_child(panel)
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	return column

func _texture(id: int, height: float) -> TextureRect:
	var node = TextureRect.new()
	node.texture = portraits.get(id)
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.custom_minimum_size = Vector2(110, height)
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return node

func _go(target: String) -> void:
	if busy:
		return
	page = target
	selected_slot = -1
	notice = ""
	_render()

func _render() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var background = ColorRect.new()
	background.color = INK
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	margin.add_theme_constant_override("margin_top", 46)
	margin.add_theme_constant_override("margin_bottom", 48)
	add_child(margin)
	root_column = VBoxContainer.new()
	root_column.add_theme_constant_override("separation", 16)
	margin.add_child(root_column)
	var header = HBoxContainer.new()
	root_column.add_child(header)
	var title = _label("ETERNAL\nCLASH", 30, GOLD)
	title.custom_minimum_size.x = 245
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var balance = _label("%s MONEDAS\nPRUEBA 0.1 · SIN CONEXIÓN" % int(profile.data.coins), 20, MUTED)
	balance.custom_minimum_size.x = 350
	balance.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(balance)
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_column.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 18)
	scroll.add_child(body)
	if not notice.is_empty():
		body.add_child(_label(notice, 23, MINT))
	match page:
		"home": _home()
		"team": _team()
		"cards": _collection()
		"match": _match_screen()
	var navigation = HBoxContainer.new()
	navigation.add_theme_constant_override("separation", 10)
	root_column.add_child(navigation)
	for entry in [["INICIO", "home"], ["EQUIPO", "team"], ["CARTAS", "cards"]]:
		var button = _button(entry[0], _go.bind(entry[1]))
		if entry[1] == page:
			button.add_theme_color_override("font_color", GOLD)
		navigation.add_child(button)

func _home() -> void:
	var hero = PanelContainer.new()
	hero.custom_minimum_size.y = 610
	hero.clip_contents = true
	hero.add_theme_stylebox_override("panel", _box(PANEL))
	body.add_child(hero)
	var art = TextureRect.new()
	art.texture = load("res://art/institute.png")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	hero.add_child(art)
	var tint = ColorRect.new()
	tint.color = Color(0.02, 0.04, 0.09, 0.40)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero.add_child(tint)
	var layout = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	hero.add_child(layout)
	layout.add_child(_label("TORNEO ETERNO CAMPEÓN", 20, GOLD))
	layout.add_child(_label("Tu equipo.\nTu próxima leyenda.", 43))
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(spacer)
	layout.add_child(_label("ZARAGOZA · PARTIDO DE PREPARACIÓN", 20, GOLD))
	layout.add_child(_label("Eternal XI vs. Bastion Adler", 30))
	layout.add_child(_label("7 contra 7 · primero a 3 goles · máximo 18 acciones", 22))
	var active = not game.state.is_empty() and not game.state.finished
	body.add_child(_button("CONTINUAR PARTIDO" if active else "JUGAR PARTIDO", _start, true))
	var how = _panel(body)
	how.add_child(_label("CONSTRUYE LA JUGADA", 24, GOLD))
	how.add_child(_label("Enlaza pases para avanzar y cargar energía. Regatea, llega al área y elige entre un tiro o una supertécnica.", 24, MUTED))
	how.add_child(_label("Capitán activo: +6 puntos de probabilidad al equipo. Cambia tus siete cartas en Equipo.", 22, MINT))
	body.add_child(_label("%s partidos · %s victorias\nTu progreso se guarda solo en esta demo." % [int(profile.data.played), int(profile.data.wins)], 22, MUTED))

func _team() -> void:
	body.add_child(_label("Tu siete inicial", 36))
	body.add_child(_label("Toca una posición para cambiar su carta. El capitán aporta +6 puntos de probabilidad.", 23, MUTED))
	if selected_slot >= 0:
		body.add_child(_button("← Volver a la formación", _cancel_picker))
		body.add_child(_label("Elige reemplazo", 29, GOLD))
		for id in roster:
			var goalkeeper = cards[id].position == "goalkeeper"
			if goalkeeper != (selected_slot == 0):
				continue
			if id in profile.data.lineup:
				continue
			body.add_child(_button(cards[id].name + " · " + _position(cards[id].position), _replace.bind(id)))
		return
	var names = ["PORTERÍA", "DEFENSA IZQ.", "DEFENSA DER.", "MEDIOCENTRO", "BANDA IZQ.", "MEDIAPUNTA", "DELANTERA"]
	for i in range(7):
		var id = int(profile.data.lineup[i])
		var card = cards[id]
		var column = _panel(body)
		var row = HBoxContainer.new()
		column.add_child(row)
		var portrait = _texture(id, 104)
		portrait.size_flags_horizontal = Control.SIZE_FILL
		portrait.custom_minimum_size.x = 85
		row.add_child(portrait)
		var info = VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		info.add_child(_label(names[i], 18, GOLD))
		info.add_child(_label(card.name, 25))
		info.add_child(_label("N · NIVEL %s · %s" % [_level(id), str(card.style).to_upper()], 18, MUTED))
		var actions = HBoxContainer.new()
		column.add_child(actions)
		actions.add_child(_button("Cambiar", _pick_slot.bind(i)))
		actions.add_child(_button("CAPITÁN" if int(profile.data.captain) == id else "Hacer capitán", _captain.bind(id)))

func _position(value: String) -> String:
	return {"goalkeeper": "POR", "fullBack": "LAT", "centreBack": "DEF", "defensiveMidfielder": "MCD", "attackingMidfielder": "MP", "winger": "EXT", "striker": "DEL"}.get(value, value)

func _pick_slot(index: int) -> void:
	if _has_active_match():
		notice = "Termina el partido antes de cambiar la formación."
	else:
		selected_slot = index
	_render()

func _cancel_picker() -> void:
	selected_slot = -1
	_render()

func _replace(id: int) -> void:
	profile.data.lineup[selected_slot] = id
	if not int(profile.data.captain) in profile.data.lineup:
		profile.data.captain = id
	selected_slot = -1
	_save()
	_render()

func _captain(id: int) -> void:
	if _has_active_match():
		notice = "El capitán se cambia entre partidos."
	else:
		profile.data.captain = id
		_save()
	_render()

func _collection() -> void:
	body.add_child(_label("Tu colección", 36))
	body.add_child(_label("19 jugadores de Eternal XI · cartas N\nMejora una carta por 50 monedas × su nivel.", 23, MUTED))
	var grid = GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(grid)
	for id in roster:
		var column = _panel(grid)
		column.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.get_parent().custom_minimum_size.x = 304
		column.add_child(_label("N   /   " + _position(cards[id].position), 20, GOLD))
		column.add_child(_texture(id, 190))
		var name_label = _label(cards[id].name, 23)
		name_label.custom_minimum_size.y = 70
		column.add_child(name_label)
		var stat_name = "save" if cards[id].position == "goalkeeper" else "defense" if cards[id].position in ["fullBack", "centreBack", "defensiveMidfielder"] else "shot"
		var stat_title = {"save": "PARADA", "defense": "DEFENSA", "shot": "TIRO"}[stat_name]
		column.add_child(_label("NV. %s · %s %s" % [_level(id), stat_title, int(cards[id].stats[stat_name]) + (_level(id) - 1) * 2], 19, MUTED))
		var train = _button("Mejorar · %s" % (_level(id) * 50), _train.bind(id))
		train.disabled = _level(id) >= 10 or int(profile.data.coins) < _level(id) * 50
		column.add_child(train)

func _level(id: int) -> int:
	return int(profile.data.levels.get(str(id), 1))

func _train(id: int) -> void:
	if _has_active_match():
		notice = "Termina el partido antes de entrenar."
	elif profile.train(id):
		notice = "%s sube al nivel %s." % [cards[id].name, _level(id)]
		_save()
	_render()

func _has_active_match() -> bool:
	return not game.state.is_empty() and not game.state.finished

func _start() -> void:
	if not _has_active_match():
		game.begin(profile.data.lineup, int(profile.data.captain), profile.data.levels, int(Time.get_unix_time_from_system()), cards)
		_save()
	_go("match")

func _match_screen() -> void:
	if game.state.is_empty():
		_start()
		return
	var s = game.state
	if s.finished:
		_results()
		return
	var score = _panel(body)
	var score_label = _label("ETERNAL XI     %s : %s     ADLER" % [int(s.score), int(s.rival_score)], 30)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score.add_child(score_label)
	score.add_child(_label("ACCIÓN %s / 18     ·     ENERGÍA %s / 100" % [int(s.turn), int(s.energy)], 21, GOLD))
	var energy = ProgressBar.new()
	energy.value = s.energy
	energy.show_percentage = false
	energy.custom_minimum_size.y = 12
	score.add_child(energy)
	var pitch = Pitch.new()
	pitch.custom_minimum_size.y = 430
	pitch.home_ids = s.lineup
	pitch.textures = portraits
	pitch.zone = int(s.zone)
	pitch.active = int(s.holder)
	body.add_child(pitch)
	var id = int(s.lineup[int(s.holder)])
	var card = cards[id]
	var current = _panel(body)
	var row = HBoxContainer.new()
	current.add_child(row)
	var photo = _texture(id, 102)
	photo.size_flags_horizontal = Control.SIZE_FILL
	row.add_child(photo)
	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	info.add_child(_label(card.name, 27))
	info.add_child(_label(["SALIDA DE BALÓN", "MEDIOCAMPO", "ZONA DE TIRO"][int(s.zone)], 20, GOLD))
	info.add_child(_label("Enlace ×%s · Capitán +6" % int(s.combo), 20, MINT))
	body.add_child(_label(s.log, 23, MUTED))
	var grid = GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(grid)
	for entry in [["PASE", "pass"], ["REGATE", "dribble"], ["TIRO", "shot"], ["SUPERTÉCNICA", "special"]]:
		var action: String = entry[1]
		var available = game.can_act(action)
		var subtitle = "%s%% · %s" % [game.chance(action, card), "+12 energía" if action == "pass" else ("−30 energía" if action == "special" else "+7 energía" if action == "dribble" else "sin coste")]
		if not available:
			subtitle = "Necesitas 30 de energía" if action == "special" and int(s.zone) >= 2 else "Avanza hasta el área"
		var action_button = _button(entry[0] + "\n" + subtitle, _act.bind(action), action == "special" and available)
		action_button.custom_minimum_size = Vector2(320, 100)
		action_button.disabled = not available
		grid.add_child(action_button)
	body.add_child(_button("Replegar · +20 energía · menos riesgo rival", _act.bind("recover")))

func _act(action: String) -> void:
	if busy or not game.can_act(action):
		return
	busy = true
	var id = int(game.state.lineup[int(game.state.holder)])
	var result = game.act(action, cards[id])
	if game.state.finished:
		profile.settle(game.state, game.outcome())
	_save()
	var overlay = ColorRect.new()
	overlay.color = Color(0.02, 0.06, 0.12, 0.96)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var column = VBoxContainer.new()
	column.custom_minimum_size.x = 590
	column.add_theme_constant_override("separation", 24)
	center.add_child(column)
	column.add_child(_texture(id, 400 if action == "special" else 230))
	var title = "¡GOL!" if result.event == "goal" else "¡PARADÓN!" if result.event == "save" else "PASE ENLAZADO" if action == "pass" else "DUELO"
	if action == "special":
		title = _technique(cards[id]) + "\n" + title
	var label = _label(title, 40, GOLD)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(label)
	var text = _label(result.text, 25)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(text)
	column.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(column, "modulate:a", 1.0, 0.18)
	await get_tree().create_timer(1.15 if action == "special" else 0.7).timeout
	busy = false
	_render()

func _technique(card: Dictionary) -> String:
	for technique in card.get("superTechniques", []):
		if technique.get("type") == "shot":
			return str(technique.name).to_upper()
	return "TIRO DE VOLUNTAD"

func _results() -> void:
	var outcome = game.outcome()
	var column = _panel(body)
	column.add_child(_label("PARTIDO TERMINADO", 22, GOLD))
	column.add_child(_label({"victory": "¡Victoria de Eternal XI!", "draw": "Empate", "defeat": "Adler se lleva el partido"}[outcome], 40))
	column.add_child(_label("%s  —  %s" % [int(game.state.score), int(game.state.rival_score)], 64))
	column.add_child(_label("+%s monedas guardadas" % (100 if outcome == "victory" else 50), 28, MINT))
	column.add_child(_label("Mejora tus cartas, cambia el capitán y prueba otra formación.", 25, MUTED))
	body.add_child(_texture(434, 310))
	body.add_child(_button("MEJORAR MIS CARTAS", _go.bind("cards"), true))
	body.add_child(_button("VOLVER A JUGAR", _start))

func _save() -> void:
	if not game.state.is_empty():
		profile.data.match = game.state.duplicate(true)
	if not profile.save():
		notice = "No se pudo guardar. Mantén abierta la demo e informa del error."
		push_error("No se pudo guardar el perfil Clash")
