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
var actor_nodes: Dictionary = {}
var clock: float = 0.0

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	set_process(true)
	var crop = Shader.new()
	crop.code = "shader_type canvas_item; void fragment(){ vec2 sample_uv=vec2(0.08+UV.x*0.84, 0.20+UV.y*0.65); vec4 c=texture(TEXTURE,sample_uv); c.a*=1.0-smoothstep(0.48,0.50,length(UV-vec2(0.5))); COLOR=c; }"
	var material = ShaderMaterial.new()
	material.shader = crop
	for id_value in game.state.lineup + game.ENEMIES:
		var id = int(id_value)
		var image = TextureRect.new()
		image.texture = textures[id]
		image.material = material
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		image.size = Vector2(70,70)
		add_child(image)
		actor_nodes[id] = image

func _process(delta: float) -> void:
	animation = minf(1.0, animation + delta * 2.7)
	clock += delta
	queue_redraw()

func field_rect() -> Rect2:
	return Rect2(24, 30, size.x - 48, size.y - 62)

func point(pos: Vector2) -> Vector2:
	var rect = field_rect()
	return rect.position + Vector2(pos.y * rect.size.x, (1.0 - pos.x) * rect.size.y)

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
	for i in range(12):
		if i % 2 == 0:
			draw_rect(Rect2(rect.position + Vector2(0, rect.size.y * i / 12), Vector2(rect.size.x, rect.size.y / 12)), Color(1, 1, 1, 0.045))
	var white = Color("d9f9ef")
	draw_rect(rect.grow(2), Color(0,0,0,0.4), false, 7)
	draw_rect(rect, white, false, 3)
	draw_line(point(Vector2(0.5,0)), point(Vector2(0.5,1)), white, 3)
	draw_arc(rect.get_center(), rect.size.x * 0.19, 0, TAU, 72, white, 3, true)
	draw_circle(rect.get_center(), 5, white)
	for x in [1.0, 0.17]:
		draw_rect(Rect2(point(Vector2(x, 0.20)), Vector2(rect.size.x * 0.60, rect.size.y * 0.17)), white, false, 3)
	for x in [1.0, 0.055]:
		draw_rect(Rect2(point(Vector2(x, 0.36)), Vector2(rect.size.x * 0.28, rect.size.y * 0.055)), white, false, 3)
	for x in [0.12, 0.88]:
		draw_circle(point(Vector2(x,0.5)), 4, white)
	for x in [0.0, 1.0]:
		var goal_a = point(Vector2(x, 0.36))
		var goal_b = point(Vector2(x, 0.64))
		draw_line(goal_a, goal_b, Color("f4cf7a") if x == 1.0 else Color("79d8fa"), 8, true)
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
	var ball = point(game.home_position(int(game.state.holder))) + Vector2(32, -26)
	if previous.has("holder"):
		var old = previous.home[int(previous.holder)]
		ball = (point(Vector2(old[0], old[1])) + Vector2(32, -26)).lerp(ball, eased)
	draw_circle(ball + Vector2(1, 3), 10, Color(0, 0, 0, 0.3))
	draw_circle(ball, 9, Color.WHITE)
	draw_circle(ball, 3, Color("173449"))
	_text("ADLER  /  ATACA HACIA ARRIBA", Vector2(28, 21), 17, Color("f4cf7a"))
	_text("ETERNAL XI", Vector2(28, size.y - 10), 17, Color("93dbe9"))

func _marker(p: Vector2, id: int, home: bool, focus: bool, holder: bool) -> void:
	var color = Color("65dff5") if home else Color("ff7d79")
	draw_circle(p + Vector2(0,5), 43, Color(0.01,0.03,0.05,0.65))
	draw_circle(p, 39, Color("102838"))
	draw_arc(p, 40, 0, TAU, 64, Color("07121b"), 8, true)
	draw_arc(p, 40, 0, TAU, 64, color, 4, true)
	draw_arc(p, 35.5, 0, TAU, 64, Color(1,1,1,0.45), 1, true)
	if focus or holder:
		var accent = Color("f4cf7a") if holder else Color("b3ffef") if home else Color("ff9c89")
		draw_arc(p, 48 + sin(clock * 4) * 1.5, 0, TAU, 64, accent, 4, true)
	if actor_nodes.has(id):
		actor_nodes[id].position = p - Vector2(35,35)
	var words = str(game.catalog[id].name).split(" ")
	var name = words[0]
	if (focus or holder) and words.size() > 1:
		name += " " + words[1]
	var width = font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x
	draw_style_box(_name_box(), Rect2(p + Vector2(-width / 2 - 7, 44), Vector2(width + 14, 27)))
	_text(name, p + Vector2(-width / 2, 64), 19, Color.WHITE)

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
