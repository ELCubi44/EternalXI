extends SceneTree
## Comprueba que el recurso anima dos apariencias y que la escena se libera.
var failures: int = 0
func _initialize() -> void:
	call_deferred("_run")
func check(value: bool,message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func _run() -> void:
	var Scene = load("res://scripts/super_cinematic.gd")
	var poses: Array = []
	var libraries: Array = []
	for id in [434,444]:
		var cinema = Scene.new()
		cinema.size = Vector2(720,1600)
		cinema.playback = false
		cinema.player_id = id
		cinema.player_name = "Thiago Solari" if id==434 else "Miguel Gracia Cubo"
		cinema.technique = {"name":"Disparo Valestia","type":"shot","cost":30,"basePower":55}
		root.add_child(cinema)
		await process_frame
		cinema.sample(2.0)
		var charge: Vector3 = cinema.actor.joints.LegR.rotation_degrees
		cinema.sample(2.75)
		var impact: Vector3 = cinema.actor.joints.LegR.rotation_degrees
		check(charge.x>40 and impact.x < -90,"La pierna cambia de carga a patada")
		poses.append(impact)
		check(cinema.world_view.size==Vector2i(540,1200),"Resolución 3D limitada")
		check(cinema.actor.animator.has_animation("shot"),"Biblioteca compartida disponible")
		libraries.append(cinema.actor.animator.get_animation_library(""))
		check(cinema.ball.position.z>1,"El balón sale después del contacto")
		# Capturas con renderer real: -- --capture=C:/ruta/existente
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--capture="):
				var folder = arg.trim_prefix("--capture=")
				for moment in [0.5,2.0,2.75,3.2]:
					cinema.sample(moment)
					await process_frame
					await RenderingServer.frame_post_draw
					root.get_texture().get_image().save_png(folder+"/actor-%s-%.2f.png" % [id,moment])
		cinema.queue_free()
		await process_frame
	check(poses[0].is_equal_approx(poses[1]),"Dos personajes ejecutan la misma patada")
	check(libraries[0]==libraries[1],"Las dos apariencias usan el mismo recurso de animación")
	for kind in ["save","dribble"]:
		var cinema = Scene.new()
		cinema.size = Vector2(720,1600)
		cinema.playback = false
		cinema.technique = {"name":kind,"type":kind}
		root.add_child(cinema)
		await process_frame
		for moment in [0.0,1.0,2.0,3.0,4.0]:
			cinema.sample(moment)
		check(cinema.actor.animator.has_animation(kind),"Movimiento compatible: "+kind)
		var done = [0]
		cinema.finished.connect(func(): done[0]+=1)
		cinema.playback = true
		cinema._process(10)
		cinema._process(10)
		check(done[0]==1,"Finalización única: "+kind)
		cinema.queue_free()
		await process_frame
	print("CINEMATIC_3D: two actors, shared kick, camera/ball, save/dribble, cleanup; %s failures" % failures)
	quit(0 if failures==0 else 1)
