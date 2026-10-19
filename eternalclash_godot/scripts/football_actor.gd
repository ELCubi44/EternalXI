extends Node3D
## Modelo de prueba articulado. La apariencia no modifica las rutas de animación.
const Motion = preload("res://scripts/super_motion.gd")
var player_id: int = 434
var joints: Dictionary = {}
var animator: AnimationPlayer
var skin: StandardMaterial3D
var shirt: StandardMaterial3D
var hair: StandardMaterial3D

func _ready() -> void:
	_build()
	animator = AnimationPlayer.new()
	animator.name = "Animator"
	add_child(animator)
	animator.add_animation_library("", Motion.library())
	animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL

func material(color: Color, glow: bool = false) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	if glow:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat

func mesh(parent: Node3D, shape: Mesh, pos: Vector3, mat: Material, dimensions: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	node.mesh = shape
	node.material_override = mat
	node.position = pos
	node.scale = dimensions
	parent.add_child(node)
	return node

func sphere(parent: Node3D, pos: Vector3, dimensions: Vector3, mat: Material) -> MeshInstance3D:
	var shape = SphereMesh.new()
	shape.radial_segments = 16
	shape.rings = 8
	return mesh(parent, shape, pos, mat, dimensions)

func tube(parent: Node3D, pos: Vector3, length: float, top: float, bottom: float, mat: Material) -> MeshInstance3D:
	var shape = CylinderMesh.new()
	shape.height = length
	shape.top_radius = top
	shape.bottom_radius = bottom
	shape.radial_segments = 12
	shape.rings = 1
	return mesh(parent, shape, pos, mat)

func pivot(parent: Node3D, joint_name: String, pos: Vector3) -> Node3D:
	var node = Node3D.new()
	node.name = joint_name
	node.position = pos
	parent.add_child(node)
	joints[joint_name] = node
	return node

func _build() -> void:
	var miguel = player_id == 444
	var keeper = player_id == 435 or player_id == 624
	skin = material(Color("d88d42") if miguel else Color("ffbf78"))
	shirt = material(Color("bb2031") if keeper else Color("1354ce"))
	hair = material(Color("3b501e") if keeper else Color("1c2028") if miguel else Color("493020"))
	var white = material(Color("f0f5ff"))
	var gold = material(Color("ffcb4d"))
	var dark = material(Color("10264c"))
	var rig = pivot(self, "Rig", Vector3.ZERO)
	var hips = pivot(rig, "Hips", Vector3(0,1.15,0))
	tube(hips,Vector3(0,0.02,0),.28,.25,.24,shirt)
	var chest = pivot(hips,"Chest",Vector3(0,.27,0))
	var torso = tube(chest,Vector3(0,.15,0),.58,.32,.24,shirt)
	torso.scale.z = .68
	# Franjas y escudo construidos en volumen, sin pegar el retrato en la cabeza.
	for side in [-1,1]:
		var trim = mesh(chest,BoxMesh.new(),Vector3(side*.25,.27,.15),white,Vector3(.055,.38,.025))
		trim.rotation_degrees.z = side*22
	var sash = mesh(chest,BoxMesh.new(),Vector3(0,.12,.205),gold,Vector3(.045,.55,.025))
	sash.rotation_degrees.z = -28
	sphere(chest,Vector3(.14,.27,.22),Vector3(.09,.12,.03),white)
	sphere(chest,Vector3(.14,.27,.24),Vector3(.05,.07,.015),gold)
	tube(chest,Vector3(0,.49,0),.12,.115,.13,skin)
	var head = pivot(chest,"Head",Vector3(0,.78,0))
	sphere(head,Vector3.ZERO,Vector3(.63,.74,.56),skin)
	for side in [-1,1]:
		sphere(head,Vector3(side*.31,-.035,0),Vector3(.13,.20,.12),skin)
		# Ojos grandes, iris y cejas; proporciones de figura anime provisional.
		sphere(head,Vector3(side*.125,.015,.25),Vector3(.17,.21,.055),dark)
		sphere(head,Vector3(side*.125,.025,.277),Vector3(.14,.175,.025),white)
		sphere(head,Vector3(side*.12,.014,.294),Vector3(.075,.12,.025),material(Color("607e32") if keeper else Color("95551b")))
		sphere(head,Vector3(side*.12,.013,.309),Vector3(.037,.09,.012),dark)
		sphere(head,Vector3(side*.105,.047,.32),Vector3(.022,.032,.009),white)
		var brow = mesh(head,BoxMesh.new(),Vector3(side*.128,.155,.262),hair,Vector3(.18,.025,.033))
		brow.rotation_degrees.z = side*12
	sphere(head,Vector3(0,-.07,.282),Vector3(.07,.08,.09),skin)
	mesh(head,BoxMesh.new(),Vector3(0,-.18,.245),dark,Vector3(.10,.015,.015))
	sphere(head,Vector3(0,.18,-.055),Vector3(.68,.53,.60),hair)
	if keeper:
		var headband = tube(head,Vector3(0,.17,0),.12,.325,.325,shirt)
		headband.scale.z = .89
	for i in range(13):
		var a = i*TAU/13.0
		var tuft = tube(head,Vector3(cos(a)*.25,.32+sin(a)*.06,sin(a)*.19),.40,.0,.12,hair)
		tuft.rotation_degrees = Vector3(sin(a)*42,0,-cos(a)*53)
	# Flequillo reconocible: mechón gris de Miguel, castaño de Thiago.
	for i in range(4):
		var fringe = tube(head,Vector3(-.21+i*.13,.22,.24),.32,0,.09,material(Color("bbb8b1")) if miguel and i<2 else hair)
		fringe.rotation_degrees.z = 150-i*12
		fringe.rotation_degrees.x = -10
	for side in [-1,1]:
		var suffix = "L" if side<0 else "R"
		var arm = pivot(chest,"Arm"+suffix,Vector3(side*.34,.36,0))
		tube(arm,Vector3(0,-.12,0),.26,.145,.13,shirt)
		tube(arm,Vector3(0,-.25,0),.05,.137,.137,gold)
		tube(arm,Vector3(0,-.31,0),.11,.11,.10,skin)
		var elbow = pivot(arm,"Elbow"+suffix,Vector3(0,-.36,0))
		tube(elbow,Vector3(0,-.14,0),.28,.10,.085,skin)
		sphere(elbow,Vector3(0,-.33,.015),Vector3(.19,.23,.18),white if keeper else skin)
		if side == -1 and player_id == 434:
			tube(arm,Vector3(0,-.14,0),.10,.15,.15,gold)
		var leg = pivot(hips,"Leg"+suffix,Vector3(side*.15,-.10,0))
		tube(leg,Vector3(0,-.12,0),.28,.14,.13,shirt)
		tube(leg,Vector3(0,-.27,0),.035,.133,.133,white)
		tube(leg,Vector3(0,-.36,0),.16,.10,.09,skin)
		var knee = pivot(leg,"Knee"+suffix,Vector3(0,-.44,0))
		sphere(knee,Vector3.ZERO,Vector3(.19,.19,.19),skin)
		tube(knee,Vector3(0,-.22,0),.37,.095,.075,shirt)
		tube(knee,Vector3(0,-.08,0),.045,.10,.10,gold)
		sphere(knee,Vector3(0,-.43,.09),Vector3(.22,.17,.42),dark)
		mesh(knee,BoxMesh.new(),Vector3(0,-.39,.17),white,Vector3(.14,.025,.06))

func pose(move: String, time: float) -> void:
	animator.play(move)
	animator.seek(time,true)
