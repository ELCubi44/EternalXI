extends Control
## Escena 3D independiente; el duelo conserva su resolución manual.
signal finished
const Actor = preload("res://scripts/football_actor.gd")
var technique: Dictionary = {}
var portrait: Texture2D
var player_name: String = ""
var player_id: int = 434
var elapsed: float = 0.0
var duration: float = 5.2
var move: String = "shot"
var accent: Color = Color("ffce61")
var world_view: SubViewport
var world: Node3D
var actor: Node3D
var camera: Camera3D
var ball: Node3D
var aura: Node3D
var shield: MeshInstance3D
var trails: Array[MeshInstance3D] = []
var font: Font = ThemeDB.fallback_font
var overlay: Control
var completed: bool = false
var playback: bool = true

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	move = str(technique.get("type","shot"))
	if move not in ["shot","save","dribble"]:
		move = "shot"
	duration = 4.2 if move == "dribble" else 4.4 if move == "save" else 5.2
	accent = Color("bc8aff") if move == "dribble" else Color("68f5eb") if move == "save" else Color("ffce61")
	_build_world()
	overlay = Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.draw.connect(_draw_titles)
	resized.connect(_resize_view)
	_resize_view()
	sample(0)

func _resize_view() -> void:
	if is_instance_valid(world_view):
		# Resolución acotada para Android, independiente del tamaño de pantalla.
		var width = mini(540,maxi(2,int(size.x)))
		world_view.size = Vector2i(width,maxi(2,int(width*size.y/maxf(size.x,1))))

func _build_world() -> void:
	world_view = SubViewport.new()
	world_view.own_world_3d = true
	world_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	world_view.msaa_3d = Viewport.MSAA_2X
	add_child(world_view)
	var image = TextureRect.new()
	image.texture = world_view.get_texture()
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(image)
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	world = Node3D.new()
	world_view.add_child(world)
	var env_node = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("080e25")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("adcbff")
	env.ambient_light_energy = .65
	env_node.environment = env
	world.add_child(env_node)
	var key = DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-32,-28,0)
	key.light_color = Color("fff1d5")
	key.light_energy = 1.5
	world.add_child(key)
	var fill = DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-15,150,0)
	fill.light_color = accent
	fill.light_energy = .7
	world.add_child(fill)
	actor = Actor.new()
	actor.player_id = player_id
	world.add_child(actor)
	var ground = PlaneMesh.new()
	ground.size = Vector2(70,70)
	actor.mesh(world,ground,Vector3(0,-.075,0),actor.material(Color("102c42")))
	actor.sphere(world,Vector3(0,-.05,0),Vector3(1.3,.025,.8),actor.material(Color("081524"),true))
	for x in [-4.0,4.0]:
		actor.mesh(world,BoxMesh.new(),Vector3(x,-.06,0),actor.material(Color("43667c"),true),Vector3(.025,.015,35))
	for z in [-5.0,0.0,5.0]:
		actor.mesh(world,BoxMesh.new(),Vector3(0,-.06,z),actor.material(Color("43667c"),true),Vector3(8,.015,.025))
	for side in [-1,1]:
		for row in range(3):
			actor.mesh(world,BoxMesh.new(),Vector3(side*(6+row),row*.45,-5),actor.material(Color("13233e")),Vector3(1,.45,25))
			for i in range(10):
				actor.mesh(world,BoxMesh.new(),Vector3(side*(5.5+row),.5+row*.45,-13+i*2),actor.material(accent.darkened(.35),true),Vector3(.04,.025,.35))
	aura = Node3D.new()
	world.add_child(aura)
	for i in range(3):
		var ring = TorusMesh.new()
		ring.inner_radius = 1.0+i*.38
		ring.outer_radius = 1.025+i*.38
		ring.rings = 32
		ring.ring_segments = 6
		actor.mesh(aura,ring,Vector3(0,.01+i*.015,0),actor.material(accent,true))
	ball = Node3D.new()
	world.add_child(ball)
	actor.sphere(ball,Vector3.ZERO,Vector3.ONE*.36,actor.material(Color("fffaf0")))
	for i in range(6):
		var a = i*TAU/6
		actor.sphere(ball,Vector3(cos(a)*.15,sin(a)*.15,.07),Vector3(.09,.09,.065),actor.material(Color("162438")))
	for i in range(10):
		trails.append(actor.sphere(world,Vector3.ZERO,Vector3.ONE*.1,actor.material(accent,true)))
	var shield_mesh = TorusMesh.new()
	shield_mesh.inner_radius = .88
	shield_mesh.outer_radius = .96
	shield_mesh.rings = 40
	shield_mesh.ring_segments = 8
	shield = actor.mesh(world,shield_mesh,Vector3(0,1.8,.9),actor.material(accent,true))
	shield.rotation_degrees.x = 90
	shield.visible = move == "save"
	camera = Camera3D.new()
	camera.fov = 42
	camera.current = true
	world.add_child(camera)

func _process(delta: float) -> void:
	if not playback or completed:
		return
	elapsed = minf(duration,elapsed+delta)
	sample(elapsed)
	if elapsed >= duration:
		completed = true
		set_process(false)
		finished.emit()

func sample(seconds: float) -> void:
	elapsed = clampf(seconds,0,duration)
	actor.pose(move,elapsed)
	actor.position = Vector3.ZERO
	actor.rotation.y = 0
	var cam_pos = Vector3(3.8,2.8,7)
	var focus = Vector3(0,1.5,0)
	if move == "shot":
		if elapsed < 1.0:
			cam_pos = Vector3(1.0,2.9,3.7).lerp(Vector3(.7,2.7,3.6),elapsed)
			focus = Vector3(0,2.13,0)
		else:
			var pull = smoothstep(1.0,1.5,elapsed)
			cam_pos = Vector3(.7,2.7,3.6).lerp(Vector3(3.5,2.4,7.2),pull)
			focus = Vector3(0,2.13,0).lerp(Vector3(0,1.35,.35),pull)
			cam_pos.x += maxf(0,elapsed-2.8)*.5
		ball.position = _shot_ball(elapsed)
		actor.position.y = sin(clampf((elapsed-1.8)/1.6,0,1)*PI)*.24
	elif move == "dribble":
		actor.position.x = sin(elapsed*2.5)*.5*sin(PI*elapsed/duration)
		actor.position.y = absf(sin(elapsed*6))*.08
		ball.position = Vector3(actor.position.x+.3*cos(elapsed*5),.22,.65+.2*sin(elapsed*4))
		cam_pos = Vector3(3.6*cos(elapsed*.3),2.7,7)
	else:
		actor.position.y = sin(clampf((elapsed-.9)/2.3,0,1)*PI)*.32
		ball.position = Vector3(0,2.8-maxf(0,elapsed-2.1)*.8,maxf(.8,5-elapsed*2))
		shield.scale = Vector3.ONE*(1+sin(elapsed*8)*.04)
		shield.visible = elapsed>1.3 and elapsed<3.7
	camera.position = cam_pos
	camera.look_at(focus)
	ball.rotation = Vector3(elapsed*5,elapsed*3,0)
	aura.rotation.y = elapsed*.7
	aura.scale = Vector3.ONE*(1+sin(elapsed*9)*.04)
	for i in range(trails.size()):
		var trail = trails[i]
		if move == "shot":
			trail.visible = elapsed>2.55 and elapsed<4.4
			trail.position = _shot_ball(maxf(2.55,elapsed-i*.025))
		elif move == "dribble":
			trail.visible = elapsed>.8 and elapsed<3.5
			var a = elapsed*6-i*.15
			trail.position = actor.position+Vector3(sin(a)*.8,.4+i*.1,cos(a)*.8)
		else:
			trail.visible = elapsed>1.6 and elapsed<3.4
			var a = i*TAU/10+elapsed
			trail.position = Vector3(cos(a),1.8+sin(a),.9)
		trail.scale = Vector3.ONE*.1*maxf(.25,1.8-i*.13)
	if is_instance_valid(overlay):
		overlay.queue_redraw()

func _shot_ball(time: float) -> Vector3:
	if time < 2.55:
		return Vector3(.20,.20,.63).lerp(Vector3(.20,1.25,.85),smoothstep(1.9,2.55,time))
	var launch = time-2.55
	return Vector3(.20+launch*.7,1.25+launch*1.35,.85+launch*7)

func _draw_titles() -> void:
	var shade = Color("080e25")
	overlay.draw_rect(Rect2(0,0,size.x,size.y*.15),shade)
	overlay.draw_rect(Rect2(0,size.y*.77,size.x,size.y*.23),shade)
	_centered("SUPERTÉCNICA",size.y*.07,23,accent)
	_centered(_phase_label(),size.y*.108,18,Color("a9bfd5"))
	_centered(player_name,size.y*.817,27,Color.WHITE)
	var title = str(technique.get("name","Técnica especial"))
	var words = title.split(" ")
	if font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,36).x>size.x-40:
		var middle = maxi(1,words.size()/2)
		_centered(" ".join(words.slice(0,middle)),size.y*.86,34,accent)
		_centered(" ".join(words.slice(middle)),size.y*.89,34,accent)
	else:
		_centered(title,size.y*.875,36,accent)
	_centered("%s PT · POTENCIA %s" % [int(technique.get("cost",24)),int(technique.get("basePower",30))],size.y*.932,21,Color("a9bfd5"))
	var progress = elapsed/duration
	overlay.draw_rect(Rect2(26,size.y*.97,size.x-52,3),Color("23344a"))
	overlay.draw_rect(Rect2(26,size.y*.97,(size.x-52)*progress,3),accent)
	if move == "shot" and elapsed>2.55 and elapsed<2.75:
		overlay.draw_rect(Rect2(Vector2.ZERO,size),Color(1,.92,.65,(2.75-elapsed)*1.6))

func _phase_label() -> String:
	if move == "shot":
		return "CONCENTRACIÓN" if elapsed<1 else "CARGA DE ENERGÍA" if elapsed<2.55 else "¡IMPACTO!" if elapsed<3.35 else "TRAYECTORIA VALESTIA"
	if move == "dribble":
		return "AMAGO" if elapsed<1.2 else "GIRO DEL ECLIPSE" if elapsed<3.2 else "ACELERACIÓN"
	return "PREPARACIÓN" if elapsed<1.4 else "¡MURO DE PUÑOS!" if elapsed<3.2 else "BARRERA ACTIVADA"

func _centered(text: String,y: float,font_size: int,color: Color) -> void:
	var width = font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
	overlay.draw_string(font,Vector2((size.x-width)/2,y),text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)
