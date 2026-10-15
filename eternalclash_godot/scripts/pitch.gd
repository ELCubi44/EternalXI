extends Control
## Campo ligero; sin físicas ni modelos 3D para la primera prueba móvil.

var zone: int = 0
var ball_progress: float = 0.0
var home_ids: Array = []
var away_ids: Array = [624, 626, 629, 632, 638, 635, 641]
var textures: Dictionary = {}
var active: int = 4

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var rect = Rect2(12, 8, size.x - 24, size.y - 16)
	draw_style_box(_field_box(), rect)
	var line = Color(0.65, 0.9, 0.85, 0.45)
	for i in range(8):
		if i % 2 == 0:
			draw_rect(Rect2(rect.position.x, rect.position.y + i * rect.size.y / 8, rect.size.x, rect.size.y / 8), Color(1, 1, 1, 0.025))
	var inner = rect.grow(-20)
	draw_rect(inner, line, false, 2)
	draw_line(Vector2(inner.position.x, size.y / 2), Vector2(inner.end.x, size.y / 2), line, 2)
	draw_arc(size / 2, 44, 0, TAU, 48, line, 2, true)
	draw_rect(Rect2(size.x / 2 - 80, inner.position.y, 160, 52), line, false, 2)
	draw_rect(Rect2(size.x / 2 - 80, inner.end.y - 52, 160, 52), line, false, 2)
	var points = [Vector2(0.5, 0.91), Vector2(0.24, 0.77), Vector2(0.76, 0.77), Vector2(0.5, 0.64), Vector2(0.22, 0.53), Vector2(0.78, 0.53), Vector2(0.5, 0.42)]
	for i in range(7):
		var p: Vector2 = points[i] * size
		var enemy: Vector2 = Vector2(1.0 - points[i].x, (1.0 - points[i].y) * 0.72 + 0.03) * size
		_marker(enemy, int(away_ids[i]), Color("de715a"), false)
		if home_ids.size() == 7:
			_marker(p, int(home_ids[i]), Color("4ddcb0"), i == active)
	var ball = Vector2(size.x * (0.3 + 0.4 * ball_progress), size.y * (0.64 - zone * 0.14))
	draw_circle(ball, 9, Color.WHITE)
	draw_circle(ball, 3, Color("152535"))

func _marker(p: Vector2, player_id: int, tint: Color, selected: bool) -> void:
	if selected:
		draw_arc(p, 31, 0, TAU, 40, Color("f3cc72"), 3, true)
	draw_circle(p, 25, Color("10283a"))
	draw_arc(p, 25, 0, TAU, 40, tint, 2, true)
	if textures.has(player_id):
		draw_texture_rect_region(textures[player_id], Rect2(p - Vector2(20, 23), Vector2(40, 46)), Rect2(0, 0, 360, 480))

func _field_box() -> StyleBoxFlat:
	var box = StyleBoxFlat.new()
	box.bg_color = Color("104236")
	box.set_corner_radius_all(20)
	return box
