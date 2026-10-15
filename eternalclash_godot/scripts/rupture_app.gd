extends Control

const Rules = preload("res://scripts/rupture_engine.gd")
const Profile = preload("res://scripts/profile.gd")
const Field = preload("res://scripts/rupture_pitch.gd")
const Gauge = preload("res://scripts/pulse_gauge.gd")
const BG = Color("09131f")
const PANEL = Color("142638")
const GOLD = Color("f4cf7a")
const GREEN = Color("6be3c5")
const MUTED = Color("a2b7c8")
var game = Rules.new()
var profile = Profile.new()
var cards: Dictionary = {}
var portraits: Dictionary = {}
var roster: Array = []
var frame: Control
var content: Control
var page: String = "home"
var action: String = "pass"
var target: int = -1
var slot: int = -1
var previous: Dictionary = {}
var notice: String = ""
var busy: bool = false
var pitch
var gauge
var duel_started: bool = false
var approach: int = -1
var approach_buttons: Array = []
var strike_button: Button
var duel_note: Label
var sound: AudioStreamPlayer

func _ready() -> void:
	var catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/cards.json"))
	for card in catalog.cards:
		var id = int(card.playerId)
		cards[id] = card
		portraits[id] = load("res://art/portraits/%s.png" % id)
		if card.team == "Eternal XI":
			roster.append(id)
	profile.load_profile()
	if not _lineup_valid(profile.data.lineup):
		profile.data.lineup = profile.defaults().lineup
	if not profile.data.match.is_empty():
		game.restore(profile.data.match, cards)
	sound = AudioStreamPlayer.new()
	sound.volume_db = -10
	add_child(sound)
	_theme()
	_render()

func _process(_delta: float) -> void:
	if duel_started and is_instance_valid(gauge) and gauge.elapsed > 7.0 and not busy:
		_resolve_pulse(true)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED and not profile.data.is_empty():
		_save()
	if what == NOTIFICATION_APPLICATION_RESUMED and is_instance_valid(frame):
		duel_started = false
		if is_instance_valid(gauge):
			gauge.running = false
			_render()

func _theme() -> void:
	var design = Theme.new()
	design.default_font_size = 22
	design.set_color("font_color", "Label", Color("f5f8fc"))
	design.set_color("font_color", "Button", Color("f5f8fc"))
	design.set_color("font_disabled_color", "Button", Color("667b8b"))
	for type in ["normal", "hover", "pressed", "disabled"]:
		design.set_stylebox(type, "Button", _box(Color("263d54") if type != "disabled" else Color("122231"), 12))
	theme = design

func _box(color: Color, radius: int = 18) -> StyleBoxFlat:
	var box = StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	box.set_content_margin_all(16)
	return box

func _label(value: String, size_value: int = 22, color: Color = Color.WHITE) -> Label:
	var label = Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size_value)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _button(value: String, callback: Callable, primary: bool = false) -> Button:
	var button = Button.new()
	button.text = value
	button.custom_minimum_size.y = 54
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(callback)
	if primary:
		for state_name in ["normal", "hover", "pressed"]:
			button.add_theme_stylebox_override(state_name, _box(GOLD, 12))
		button.add_theme_color_override("font_color", BG)
		button.add_theme_color_override("font_hover_color", BG)
		button.add_theme_color_override("font_pressed_color", BG)
	return button

func _panel(parent: Node, width: float = 0) -> VBoxContainer:
	var panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(PANEL))
	if width > 0:
		panel.custom_minimum_size.x = width
	parent.add_child(panel)
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	return column

func _portrait(id: int, height: float, width: float = 0) -> TextureRect:
	var image = TextureRect.new()
	image.texture = portraits[id]
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.custom_minimum_size = Vector2(width, height)
	image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return image

func _render() -> void:
	gauge = null
	duel_started = false
	approach_buttons = []
	if is_instance_valid(frame):
		remove_child(frame)
		frame.queue_free()
	frame = Control.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(frame)
	var background = ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = BG
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(background)
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	frame.add_child(margin)
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	var header = HBoxContainer.new()
	header.custom_minimum_size.y = 46
	header.add_theme_constant_override("separation", 16)
	column.add_child(header)
	var title = _label("ETERNAL CLASH  /  RUPTURA", 25, GOLD)
	title.custom_minimum_size.x = 390
	header.add_child(title)
	var status = _label("%s monedas · prueba 0.2" % int(profile.data.coins), 21, MUTED)
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.custom_minimum_size.x = 350
	if page == "match" and not game.state.is_empty():
		status.text = "XI  %s : %s  ADLER    ·    POSESIÓN %s / 6" % [int(game.state.score), int(game.state.rival_score), int(game.state.round)]
		status.add_theme_color_override("font_color", Color.WHITE)
	header.add_child(status)
	for entry in [["Inicio", "home"], ["Equipo", "team"], ["Cartas", "cards"]]:
		var button = _button(entry[0], _go.bind(entry[1]))
		button.custom_minimum_size = Vector2(118, 44)
		button.size_flags_horizontal = Control.SIZE_FILL
		header.add_child(button)
	content = Control.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(content)
	match page:
		"match": _match_page()
		"team": _team_page()
		"cards": _cards_page()
		_: _home_page()
	if page == "match" and not game.state.pending.is_empty() and not game.state.finished:
		_duel_overlay()

func _fill(node: Control, parent: Node) -> void:
	parent.add_child(node)
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _home_page() -> void:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	_fill(row, content)
	var art_panel = PanelContainer.new()
	art_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	art_panel.add_theme_stylebox_override("panel", _box(PANEL))
	row.add_child(art_panel)
	var image = TextureRect.new()
	image.texture = load("res://art/institute.png")
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art_panel.add_child(image)
	var shade = ColorRect.new()
	shade.color = Color(0.02, 0.05, 0.08, 0.38)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_panel.add_child(shade)
	var text = VBoxContainer.new()
	art_panel.add_child(text)
	text.add_child(_label("EL BALÓN SE MUEVE.\nLA HUELLA PERMANECE.", 43, GOLD))
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text.add_child(spacer)
	text.add_child(_label("Engaña a las marcas. Conecta tres jugadores.\nAbre una RUPTURA y resuelve el duelo con tus manos.", 28))
	var menu = _panel(row, 540)
	menu.add_child(_label("Una nueva forma de jugar", 31, GOLD))
	menu.add_child(_label("1. Elige PASE, PARED o SEÑUELO.\n2. Toca al compañero en el campo.\n3. Mira quién intercepta y confirma.", 24))
	menu.add_child(_label("Las marcas siguen la huella del balón. Arrástralas con señuelos. Enlaza tres jugadores, cambia de banda y gana profundidad para una Ruptura.", 23, MUTED))
	menu.add_child(_label("En los duelos: lee al rival, elige tu enfoque y pulsa cuando la aguja cruce la zona verde. Sin dados.", 23, GREEN))
	menu.add_child(_button("CONTINUAR RUPTURA" if _active() else "JUGAR RUPTURA", _start, true))
	menu.add_child(_label("7 contra 7 · 6 pulsos por ataque\nPrimero a 3 goles o 6 posesiones por equipo", 21, MUTED))
	if not notice.is_empty():
		menu.add_child(_label(notice, 21, GREEN))

func _match_page() -> void:
	if game.state.finished:
		_results()
		return
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	_fill(row, content)
	var left = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 10)
	row.add_child(left)
	pitch = Field.new()
	pitch.game = game
	pitch.textures = portraits
	pitch.action = action
	pitch.selected = target
	pitch.preview_data = game.preview(action, target)
	pitch.previous = previous
	pitch.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pitch.player_tapped.connect(_select_player)
	left.add_child(pitch)
	var hand = HBoxContainer.new()
	hand.custom_minimum_size.y = 104
	hand.add_theme_constant_override("separation", 10)
	left.add_child(hand)
	for entry in [["PASE", "pass", "1 pulso · cambia al receptor"], ["PARED", "wall", "2 pulsos · devuelve y avanza"], ["SEÑUELO", "decoy", "1 pulso · arrastra una marca"], ["RUPTURA" if game.rupture_ready() else "TIRO", "shot", "1 pulso · duelo de remate"]]:
		var button = _button(entry[0] + "\n" + entry[2], _select_action.bind(entry[1]), action == entry[1])
		button.add_theme_font_size_override("font_size", 20)
		button.disabled = int(game.state.beats) < game.cost(entry[1])
		hand.add_child(button)
	var rail_scroll = ScrollContainer.new()
	rail_scroll.custom_minimum_size.x = 352
	rail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	row.add_child(rail_scroll)
	var rail = _panel(rail_scroll)
	rail.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rail.add_child(_label("%s PULSOS" % int(game.state.beats), 30, GOLD))
	var links = mini(3, game.state.chain.size())
	rail.add_child(_label("¡RUPTURA LISTA!" if game.rupture_ready() else "RED %s / 3 · abre y avanza" % links, 22, GREEN))
	var carrier_id = int(game.state.lineup[int(game.state.holder)])
	var info = game.preview(action, target)
	var photos = HBoxContainer.new()
	rail.add_child(photos)
	photos.add_child(_portrait(carrier_id, 100, 105))
	var other_id = int(game.state.lineup[target]) if target >= 1 else 624 if action == "shot" else -1
	if other_id > 0:
		photos.add_child(_portrait(other_id, 100, 105))
	rail.add_child(_label(_name(carrier_id), 23))
	if action == "shot":
		rail.add_child(_label("contra Magnus Stahlberg", 21, GOLD))
	elif target >= 1:
		rail.add_child(_label("→ " + _name(int(game.state.lineup[target])), 21, GREEN))
	else:
		rail.add_child(_label("Toca a otro compañero\nen el campo.", 23, GOLD))
	if target >= 1 or action == "shot":
		rail.add_child(_label(str(info.reason), 21, GREEN if info.get("legal", false) and not info.get("duel", false) else Color("f2aa91")))
	if int(info.get("defender", -1)) >= 0 and action != "shot":
		var defender_id = game.ENEMIES[int(info.defender)]
		rail.add_child(_label("MARCA: " + _name(defender_id), 21, GOLD))
	var confirm = _button("EJECUTAR " + {"pass": "PASE", "wall": "PARED", "decoy": "SEÑUELO", "shot": "TIRO"}[action], _execute, true)
	confirm.disabled = not info.get("legal", false)
	rail.add_child(confirm)
	var last_play = _label(str(game.state.log), 19, MUTED)
	last_play.max_lines_visible = 3
	rail.add_child(last_play)

func _select_player(index: int) -> void:
	if busy or not game.state.pending.is_empty():
		return
	if index == int(game.state.holder):
		notice = "Ese jugador ya tiene el balón."
		return
	target = index
	previous = {}
	_render()

func _select_action(value: String) -> void:
	if busy:
		return
	action = value
	if value == "shot":
		target = -1
	previous = {}
	_render()

func _execute() -> void:
	if busy:
		return
	previous = game.state.duplicate(true)
	var result = game.execute(action, target)
	if not result.get("accepted", false):
		return
	_sfx("pass")
	target = -1
	action = "pass"
	_save()
	_render()

func _duel_overlay() -> void:
	var duel = game.state.pending
	var overlay = ColorRect.new()
	overlay.color = Color(0.015, 0.035, 0.065, 0.97)
	_fill(overlay, frame)
	var margin = MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	_fill(margin, overlay)
	var layout = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)
	var defense = duel.kind == "defend"
	var kind = "¡CONTRAATAQUE!  /  TÚ CONTROLAS AL PORTERO" if defense else "RUPTURA  /  REMATE COMBINADO" if duel.kind == "shot" and duel.rupture else "DUELO DE TIRO" if duel.kind == "shot" else "DUELO DE INTERCEPCIÓN"
	layout.add_child(_label(kind, 28, GOLD))
	var duel_row = HBoxContainer.new()
	duel_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	duel_row.add_theme_constant_override("separation", 28)
	layout.add_child(duel_row)
	var left = VBoxContainer.new()
	left.custom_minimum_size.x = 340
	duel_row.add_child(left)
	left.add_child(_label(_name(int(duel.left)), 29, GREEN))
	var own = _portrait(int(duel.left), 190)
	own.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(own)
	left.add_child(_label(_technique(int(duel.left), "save" if defense else "shot" if duel.kind == "shot" else "pass"), 22, GREEN))
	var middle = VBoxContainer.new()
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.add_theme_constant_override("separation", 12)
	duel_row.add_child(middle)
	middle.add_child(_label("LEE LA INTENCIÓN DEL RIVAL", 21, MUTED))
	var intent = game.SHOT_INTENTS[int(duel.stance)] if defense else game.STANCES[int(duel.stance)]
	middle.add_child(_label(intent.to_upper(), 31, Color("f0a18b")))
	middle.add_child(_label("Bloquea el tiro cargado.\nEstírate si busca la escuadra.\nAguanta si intenta engañarte." if defense else "Potencia rompe la espera.\nEfecto rodea el cierre.\nAmago castiga la presión.", 23))
	middle.add_child(_label("El enfoque correcto ensancha la zona verde.\nDespués, tú decides el instante.", 21, GREEN))
	duel_note = _label("1 · ELIGE TU ENFOQUE", 24, GOLD)
	middle.add_child(duel_note)
	var right = VBoxContainer.new()
	right.custom_minimum_size.x = 340
	duel_row.add_child(right)
	right.add_child(_label(_name(int(duel.right)), 29, Color("f0a18b")))
	var enemy = _portrait(int(duel.right), 190)
	enemy.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(enemy)
	right.add_child(_label(_technique(int(duel.right), "shot" if defense else "save" if duel.kind == "shot" else "defense"), 22, Color("f0a18b")))
	var approaches = HBoxContainer.new()
	approaches.add_theme_constant_override("separation", 14)
	layout.add_child(approaches)
	approach_buttons = []
	for i in range(3):
		var options = ["BLOQUEAR · tiro potente", "ESTIRARSE · busca la escuadra", "AGUANTAR · amaga el disparo"] if defense else ["POTENCIA · rompe la espera", "EFECTO · rodea el cierre", "AMAGO · castiga la presión"]
		var button = _button(options[i], _choose_approach.bind(i))
		approaches.add_child(button)
		approach_buttons.append(button)
	gauge = Gauge.new()
	gauge.speed = 0.50 + int(duel.stance) * 0.045 + int(game.state.round) * 0.025
	gauge.custom_minimum_size.y = 84
	layout.add_child(gauge)
	strike_button = _button("2 · ELIGE UN ENFOQUE PARA ACTIVAR EL PULSO", _resolve_pulse.bind(false), true)
	strike_button.custom_minimum_size.y = 76
	strike_button.disabled = true
	layout.add_child(strike_button)

func _choose_approach(value: int) -> void:
	if duel_started or busy:
		return
	approach = value
	gauge.target_width = game.duel_width(value)
	gauge.elapsed = 0.0
	gauge.running = true
	duel_started = true
	for button in approach_buttons:
		button.disabled = true
	var correct = value == game.COUNTERS[int(game.state.pending.stance)]
	duel_note.text = "¡LEÍSTE SU INTENCIÓN! · PULSA EN VERDE" if correct else "ENFOQUE DIFÍCIL · BUSCA LA ZONA VERDE"
	strike_button.text = "¡AHORA!  ·  PULSA CUANDO LA AGUJA ESTÉ EN VERDE"
	strike_button.disabled = false
	_sfx("pass")

func _resolve_pulse(timed_out: bool = false) -> void:
	if not duel_started or busy or not is_instance_valid(gauge):
		return
	busy = true
	duel_started = false
	gauge.running = false
	var result = game.resolve_duel(gauge.pointer, approach, timed_out)
	if game.state.finished:
		profile.settle(game.state, game.outcome())
	_save()
	_sfx("goal" if result.success else "miss")
	var result_overlay = ColorRect.new()
	result_overlay.color = Color(0.02, 0.08, 0.11, 0.96)
	_fill(result_overlay, frame)
	var center = CenterContainer.new()
	_fill(center, result_overlay)
	var column = VBoxContainer.new()
	column.custom_minimum_size.x = 1100
	center.add_child(column)
	var headline = _label("¡PULSO PERFECTO!" if result.perfect else "¡DUELO GANADO!" if result.success else "DUELO PERDIDO", 48, GOLD if result.success else Color("ed9c88"))
	headline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(headline)
	var explanation = _label(result.text, 30)
	explanation.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(explanation)
	await get_tree().create_timer(1.6).timeout
	busy = false
	previous = {}
	_render()

func _results() -> void:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 28)
	_fill(row, content)
	row.add_child(_portrait(434, 400, 400))
	var panel = _panel(row)
	panel.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var outcome = game.outcome()
	panel.add_child(_label({"victory": "¡RUPTURA VICTORIOSA!", "draw": "EL PARTIDO TERMINA EN EMPATE", "defeat": "ADLER HA LEÍDO TUS JUGADAS"}[outcome], 34, GOLD))
	panel.add_child(_label("ETERNAL XI    %s : %s    BASTION ADLER" % [int(game.state.score), int(game.state.rival_score)], 38))
	panel.add_child(_label("+%s monedas · progreso guardado" % (100 if outcome == "victory" else 50), 28, GREEN))
	panel.add_child(_label("Prueba otra ruta: atrae la marca con SEÑUELO, rompe con PARED y conecta a tres jugadores antes del tiro.", 26, MUTED))
	panel.add_child(_button("OTRO PARTIDO", _start, true))
	panel.add_child(_button("CAMBIAR EQUIPO", _go.bind("team")))

func _scroll_grid(columns: int) -> GridContainer:
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_fill(scroll, content)
	var grid = GridContainer.new()
	grid.columns = columns
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)
	return grid

func _team_page() -> void:
	var grid = _scroll_grid(7 if slot < 0 else 5)
	var ids: Array = profile.data.lineup if slot < 0 else roster
	for i in range(ids.size()):
		var id = int(ids[i])
		if slot >= 0 and (id in profile.data.lineup or (cards[id].position == "goalkeeper") != (slot == 0)):
			continue
		var column = _panel(grid)
		column.get_parent().custom_minimum_size.x = 200 if slot < 0 else 260
		column.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_child(_label("POSICIÓN %s" % (i + 1) if slot < 0 else "REEMPLAZO", 19, GOLD))
		column.add_child(_portrait(id, 160))
		column.add_child(_label(_name(id), 23))
		column.add_child(_label("NIVEL %s · %s" % [_level(id), _position(cards[id].position)], 19, MUTED))
		column.add_child(_button("Cambiar" if slot < 0 else "Elegir", _pick_slot.bind(i) if slot < 0 else _replace.bind(id)))
		if slot < 0:
			column.add_child(_button("CAPITÁN" if int(profile.data.captain) == id else "Capitán", _captain.bind(id)))
	if slot >= 0:
		var back = _button("Cancelar", _cancel_picker)
		grid.add_child(back)

func _cards_page() -> void:
	var grid = _scroll_grid(6)
	for id in roster:
		var column = _panel(grid)
		column.get_parent().custom_minimum_size.x = 230
		column.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_child(_label("CARTA N · " + _position(cards[id].position), 20, GOLD))
		column.add_child(_portrait(id, 145))
		column.add_child(_label(_name(id), 23))
		column.add_child(_label("NV. %s · PASE %s · TIRO %s" % [_level(id), int(cards[id].stats.pass), int(cards[id].stats.shot)], 19, MUTED))
		var button = _button("Mejorar · %s" % (_level(id) * 50), _train.bind(id))
		button.disabled = int(profile.data.coins) < _level(id) * 50 or _level(id) >= 10 or _active()
		column.add_child(button)

func _pick_slot(index: int) -> void:
	if _active():
		notice = "Termina el partido para cambiar la formación."
		_go("home")
		return
	slot = index
	_render()

func _cancel_picker() -> void:
	slot = -1
	_render()

func _replace(id: int) -> void:
	profile.data.lineup[slot] = id
	if not int(profile.data.captain) in profile.data.lineup:
		profile.data.captain = id
	slot = -1
	_save()
	_render()

func _captain(id: int) -> void:
	if not _active():
		profile.data.captain = id
		_save()
	_render()

func _train(id: int) -> void:
	if not _active() and profile.train(id):
		_save()
	_render()

func _active() -> bool:
	return not game.state.is_empty() and not game.state.finished

func _start() -> void:
	if not _active():
		game.begin(profile.data.lineup, profile.data.levels, int(profile.data.captain), cards)
	action = "pass"
	target = -1
	previous = {}
	_save()
	_go("match")

func _go(value: String) -> void:
	if busy:
		return
	page = value
	slot = -1
	previous = {}
	_render()

func _save() -> void:
	if not game.state.is_empty():
		profile.data.match = game.state.duplicate(true)
	if not profile.save():
		notice = "Error al guardar. Informa antes de cerrar la prueba."
		push_error(notice)

func _lineup_valid(ids: Array) -> bool:
	var unique: Dictionary = {}
	for id in ids:
		if int(id) not in roster:
			return false
		unique[int(id)] = true
	return ids.size() == 7 and unique.size() == 7 and cards[int(ids[0])].position == "goalkeeper"

func _level(id: int) -> int:
	return int(profile.data.levels.get(str(id), 1))

func _name(id: int) -> String:
	return str(cards[id].name)

func _position(value: String) -> String:
	return {"goalkeeper": "POR", "fullBack": "LAT", "centreBack": "DEF", "defensiveMidfielder": "MCD", "attackingMidfielder": "MP", "winger": "EXT", "striker": "DEL"}.get(value, value)

func _technique(id: int, type: String) -> String:
	for technique in cards[id].get("superTechniques", []):
		if technique.type == type:
			return str(technique.name)
	return {"shot": "Disparo combinado", "save": "Defensa de la portería", "pass": "Pase de enlace", "defense": "Cierre de línea"}.get(type, "Técnica de equipo")

func _sfx(kind: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var path = "res://audio/%s.wav" % kind
	if ResourceLoader.exists(path):
		sound.stream = load(path)
		sound.play()
