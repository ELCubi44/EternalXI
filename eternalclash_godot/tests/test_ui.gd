extends SceneTree

var failures: int = 0
var screens: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	var app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	for target in ["home", "team", "cards"]:
		app._go(target)
		await process_frame
		await process_frame
		check(app.root_column.get_child(0).size.y < 150, "Cabecera demasiado alta en " + target)
		check(app.body.size.x <= 664, "Contenido fuera del ancho móvil en " + target)
		screens += 1
	app.selected_slot = 4
	app.page = "team"
	app._render()
	await process_frame
	check(app.body.get_child_count() > 5, "Selector de reemplazos vacío")
	app.game.begin(app.profile.data.lineup, 434, {}, 12)
	app._go("match")
	await process_frame
	await process_frame
	check(app.body.size.x <= 664, "Partido fuera del ancho móvil")
	check(app.game.can_act("pass"), "Partido no permite empezar")
	app.game.state.finished = true
	app.game.state.score = 3
	app._render()
	await process_frame
	screens += 2
	print("CLASH_UI: %s screens + formation picker; %s failures" % [screens, failures])
	app.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
