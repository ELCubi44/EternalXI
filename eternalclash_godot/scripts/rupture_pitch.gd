extends Control

signal player_tapped(index: int)
var game
var textures: Dictionary = {}
var selected: int = -1
var action: String = "pass"
var preview_data: Dictionary = {}
var previous: Dictionary = {}
var animation: float = 0.0
var font: Font = ThemeDB.fallback_font

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	set_process(true)

func _process(delta: float) -> void:
	if animation < 1.0:
		animation = minf(1.0, animation + delta * 2.7)
		queue_redraw()

func field_rect() -> Rect2:
	return Rect2(26, 30, size.x - 52, size.y - 62)

func point(pos: Vector2) -> Vector2:
	var rect = field_rect()
	return rect.position + pos * rect.size

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var closest = -1
		var distance = 68.0
		for i in range(1, 7):
			var d = event.position.distance_to(point(game.home_position(i)))
			if d < distance:
				closest = i
				distance = d
		if closest >= 0:
			player_tapped.emit(closest)
		accept_event()

func _draw() -> void:
	if game == null or game.state.is_empty():
		return
	var rect = field_rect()
	var surface = StyleBoxFlat.new()
	surface.bg_color = Color("103c36")
	surface.set_corner_radius_all(22)
	draw_style_box(surface, Rect2(Vector2.ZERO, size))
	for i in range(10):
		if i % 2 == 0:
			draw_rect(Rect2(rect.position + Vector2(rect.size.x * i / 10, 0), Vector2(rect.size.x / 10, rect.size.y)), Color(1, 1, 1, 0.025))
	var white = Color(0.65, 0.91, 0.83, 0.45)
	draw_rect(rect, white, false, 2)
	draw_line(point(Vector2(0.5, 0)), point(Vector2(0.5, 1)), white, 2)
	draw_arc(point(Vector2(0.5, 0.5)), rect.size.y * 0.19, 0, TAU, 60, white, 2, true)
	for x in [0.0, 0.83]:
		draw_rect(Rect2(point(Vector2(x, 0.2)), Vector2(rect.size.x * 0.17, rect.size.y * 0.6)), white, false, 2)
	draw_line(point(Vector2(1, 0.35)), point(Vector2(1, 0.65)), Color("f3cc72"), 7)
	# Huellas de pases: una red visible, no un contador escondido.
	var trail: Array = game.state.trail
	if trail.size() >= 3:
		var polygon = PackedVector2Array()
		for pos in trail:
			polygon.append(point(Vector2(pos[0], pos[1])))
		if polygon.size() >= 3:
			# Las rutas pueden cruzarse; usar líneas evita polígonos degenerados.
			draw_polyline(polygon, Color(0.32, 0.95, 0.8, 0.28), 12, true)
	for i in range(1, trail.size()):
		var p = point(Vector2(trail[i - 1][0], trail[i - 1][1]))
		var q = point(Vector2(trail[i][0], trail[i][1]))
		draw_line(p, q, Color("52bca9"), 3, true)
	# El plan de cada defensor está anunciado con una flecha discontinua.
	for i in range(1, 7):
		var p = point(game.away_position(i))
		var q = point(game.marker_intent(i))
		if action in ["pass", "wall"]:
			_arrow(p, q, Color(1, 0.43, 0.34, 0.35), 2)
	if selected >= 1 and not preview_data.is_empty():
		var start = point(game.home_position(int(game.state.holder)))
		var end = point(game.home_position(selected))
		var color = Color("fa9072") if preview_data.get("duel", false) else Color("6de8cb")
		if action == "decoy" and int(preview_data.get("defender", -1)) >= 0:
			var defender_position = game.away_position(int(preview_data.defender))
			var destination = Vector2(preview_data.destination[0], preview_data.destination[1])
			_arrow(point(game.home_position(selected)), point(destination), Color("6de8cb"), 4)
			start = point(defender_position)
			end = point(defender_position.move_toward(destination, 0.27))
			color = Color("d5acff")
		_arrow(start, end, color, 6)
		if action == "wall":
			_arrow(end, point(game.home_position(int(game.state.holder)) + Vector2(0.16, 0)), Color("f3cc72"), 4)
	if action == "shot" and preview_data.get("legal", false):
		_arrow(point(game.home_position(int(game.state.holder))), point(Vector2(0.98, 0.50)), Color("f3cc72"), 6)
	var eased = 1.0 - pow(1.0 - animation, 3)
	for i in range(7):
		var pos = game.away_position(i)
		if previous.has("away"):
			pos = Vector2(previous.away[i][0], previous.away[i][1]).lerp(pos, eased)
		var involved = not preview_data.is_empty() and int(preview_data.get("defender", -1)) == i
		_marker(point(pos), game.ENEMIES[i], false, involved, false)
	for i in range(7):
		var pos = game.home_position(i)
		if previous.has("home"):
			pos = Vector2(previous.home[i][0], previous.home[i][1]).lerp(pos, eased)
		_marker(point(pos), int(game.state.lineup[i]), true, i == selected, i == int(game.state.holder))
	var ball = point(game.home_position(int(game.state.holder))) + Vector2(28, 18)
	if previous.has("holder"):
		var old = previous.home[int(previous.holder)]
		ball = (point(Vector2(old[0], old[1])) + Vector2(28, 18)).lerp(ball, eased)
	draw_circle(ball + Vector2(1, 3), 10, Color(0, 0, 0, 0.3))
	draw_circle(ball, 9, Color.WHITE)
	draw_circle(ball, 3, Color("173449"))
	_text("TU PORTERÍA", Vector2(28, 20), 16, Color("87b4b1"))
	_text("ATACA HACIA AQUÍ  →", Vector2(size.x - 260, 20), 18, Color("f3cc72"))
	_text("AZUL: TU EQUIPO    ROJO: ADLER    FLECHAS: MARCA TRAS EL PASE", Vector2(28, size.y - 10), 16, Color("a0c4bc"))

func _marker(p: Vector2, id: int, home: bool, focus: bool, holder: bool) -> void:
	var color = Color("61dcc4") if home else Color("ee8978")
	if focus or holder:
		draw_circle(p, 47 if holder else 44, Color(0.95, 0.79, 0.43, 0.17))
		draw_arc(p, 44, 0, TAU, 48, Color("f3cc72"), 3, true)
	draw_circle(p + Vector2(0, 8), 30, Color("10212d"))
	draw_arc(p + Vector2(0, 8), 30, 0, TAU, 40, color, 2.5, true)
	if textures.has(id):
		draw_texture_rect(textures[id], Rect2(p - Vector2(38, 56), Vector2(76, 101)), false)
	var words = str(game.catalog[id].name).split(" ")
	var name = words[0]
	if home and words.size() > 1:
		name += " " + words[1].left(8)
	var width = font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
	draw_style_box(_name_box(), Rect2(p + Vector2(-width / 2 - 7, 43), Vector2(width + 14, 24)))
	_text(name, p + Vector2(-width / 2, 61), 17, Color.WHITE)

func _name_box() -> StyleBoxFlat:
	var box = StyleBoxFlat.new()
	box.bg_color = Color(0.025, 0.06, 0.1, 0.9)
	box.set_corner_radius_all(5)
	return box

func _arrow(start: Vector2, end: Vector2, color: Color, width: float) -> void:
	if start.distance_to(end) < 2:
		return
	draw_line(start, end, color, width, true)
	var direction = (end - start).normalized()
	draw_line(end, end - direction.rotated(0.55) * 15, color, width, true)
	draw_line(end, end - direction.rotated(-0.55) * 15, color, width, true)

func _text(value: String, pos: Vector2, font_size: int, color: Color) -> void:
	draw_string(font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
