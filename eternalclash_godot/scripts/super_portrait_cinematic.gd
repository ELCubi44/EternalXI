extends Control
## Efectos nativos 2D: regate con ecos, tiro con estela y parada con escudo.
signal finished
var technique: Dictionary = {}
var portrait: Texture2D
var player_name: String = ""
var player_id: int = 0
var elapsed: float = 0.0
var duration: float = 2.0
var font: Font = ThemeDB.fallback_font

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()
	if elapsed >= duration:
		set_process(false)
		finished.emit()

func _draw() -> void:
	var t = clampf(elapsed / duration, 0, 1)
	var center = size * Vector2(0.5, 0.45)
	var accent = Color("b79aff") if technique.get("type") == "dribble" else Color("71e9fb") if technique.get("type") == "save" else Color("ffcf68")
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.015,0.025,0.075,0.98))
	for i in range(22):
		var y = fmod(i * 93.0 + elapsed * 340, size.y)
		draw_line(Vector2(-40,y), Vector2(size.x+40,y-190), Color(accent,0.16), 3, true)
	for i in range(4):
		draw_arc(center, 150 + fmod(elapsed * 180 + i * 70, 300), -PI * 0.9, PI * 0.9, 72, Color(accent,0.22), 4, true)
	if portrait != null:
		var shake = sin(elapsed * 32) * 4 * sin(PI*t)
		var rect = Rect2(center - Vector2(180,240) + Vector2(shake,0), Vector2(360,480))
		if technique.get("type") == "dribble":
			for i in [2,1]:
				var ghost = rect
				ghost.position.x -= 60 * i * sin(PI*t)
				draw_texture_rect(portrait,ghost,false,Color(accent,0.24))
		draw_texture_rect(portrait,rect,false)
	if technique.get("type") == "save":
		draw_arc(center+Vector2(0,100), 180+sin(elapsed*6)*12, -PI*0.9, -PI*0.1, 72, accent, 16, true)
	else:
		var ball = Vector2(size.x * (0.1 + t*0.8), size.y*(0.72-t*0.34))
		for i in range(12):
			draw_circle(ball-Vector2(i*12,-i*7),maxf(2,20-i),Color(accent,0.6-i*0.045))
		draw_circle(ball,20,Color.WHITE)
		draw_circle(ball,6,accent)
	_centered("SUPERTÉCNICA",size.y*0.13,26,accent)
	_centered(player_name,size.y*0.70,28,Color.WHITE)
	var name = str(technique.get("name","Técnica especial"))
	var parts = name.split(" ")
	if font.get_string_size(name,HORIZONTAL_ALIGNMENT_LEFT,-1,38).x > size.x-50:
		var middle = maxi(1,parts.size()/2)
		_centered(" ".join(parts.slice(0,middle)),size.y*0.78,36,accent)
		_centered(" ".join(parts.slice(middle)),size.y*0.82,36,accent)
	else:
		_centered(name,size.y*0.79,38,accent)
	_centered("%s PT  ·  POTENCIA %s" % [int(technique.get("cost",24)),int(technique.get("basePower",30))],size.y*0.88,23,Color("b9c8dd"))

func _centered(text: String, y: float, font_size: int, color: Color) -> void:
	var width = font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
	draw_string(font,Vector2((size.x-width)/2,y),text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)
