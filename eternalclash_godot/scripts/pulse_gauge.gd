extends Control

var pointer: float = 0.0
var target_width: float = 0.25
var running: bool = false
var elapsed: float = 0.0
var speed: float = 0.58

func _process(delta: float) -> void:
	if running:
		elapsed += delta
		pointer = 1.0 - absf(fmod(elapsed * speed, 2.0) - 1.0)
		queue_redraw()

func _draw() -> void:
	var rect = Rect2(12, 20, size.x - 24, 46)
	var box = StyleBoxFlat.new()
	box.bg_color = Color("203651")
	box.set_corner_radius_all(16)
	draw_style_box(box, rect)
	var target = Rect2(rect.position + Vector2(rect.size.x * (0.5 - target_width / 2), 0), Vector2(rect.size.x * target_width, 46))
	draw_rect(target, Color("48bca2"))
	draw_rect(Rect2(rect.position + Vector2(rect.size.x * 0.465, 0), Vector2(rect.size.x * 0.07, 46)), Color("f3cc72"))
	var x = rect.position.x + pointer * rect.size.x
	draw_line(Vector2(x, 10), Vector2(x, 76), Color.WHITE, 6, true)
	draw_circle(Vector2(x, 11), 7, Color.WHITE)
