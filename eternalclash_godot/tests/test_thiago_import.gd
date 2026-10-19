extends SceneTree
## El modelo en desarrollo se comprueba aislado: no cambia la partida ni la UI.
var failures: int = 0
var skeleton: Skeleton3D
var animator: AnimationPlayer
var mesh_count: int = 0
var skin_count: int = 0
func _initialize() -> void:
	call_deferred("_run")
func check(value: bool,message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func scan(node: Node) -> void:
	if node is Skeleton3D:
		skeleton = node
	if node is AnimationPlayer:
		animator = node
	if node is MeshInstance3D:
		mesh_count += 1
		if node.skin != null:
			skin_count += 1
	for child in node.get_children():
		scan(child)
func _run() -> void:
	var packed = load("res://art/models/thiago/thiago.glb")
	check(packed is PackedScene,"GLB importado como escena")
	if not packed is PackedScene:
		quit(1)
		return
	var actor = packed.instantiate()
	root.add_child(actor)
	await process_frame
	scan(actor)
	check(skeleton != null,"Esqueleto importado")
	check(animator != null,"Animación importada")
	check(mesh_count>=20 and skin_count==mesh_count,"Todas las mallas usan skin")
	if skeleton != null and animator != null:
		check(skeleton.get_bone_count()==18,"Dieciocho huesos compatibles")
		var move: StringName = &""
		for name in animator.get_animation_list():
			if "Disparo" in str(name):
				move = name
		check(move != &"","Acción Disparo Valestia disponible")
		if move != &"":
			animator.play(move)
			animator.seek(0,true)
			await process_frame
			var before: Array[Transform3D] = []
			for bone in range(skeleton.get_bone_count()):
				before.append(skeleton.get_bone_pose(bone))
			animator.pause()
			animator.seek(67.0/30.0,true)
			await process_frame
			var changed = 0
			for bone in range(skeleton.get_bone_count()):
				var pose = skeleton.get_bone_pose(bone)
				check(pose.is_finite(),"Pose finita")
				if not pose.is_equal_approx(before[bone]):
					changed += 1
			check(changed>=5,"La acción modifica realmente varios huesos")
	actor.queue_free()
	await process_frame
	print("THIAGO_IMPORT: GLB, meshes/skin, 18 bones, animated poses; %s failures" % failures)
	quit(0 if failures==0 else 1)
