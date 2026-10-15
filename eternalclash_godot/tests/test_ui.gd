extends SceneTree
var failures = 0
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
 for screen in ["home", "team", "cards"]:
  app._go(screen)
  await process_frame
  await process_frame
  check(app.content.size.x <= 1568 and app.content.size.y <= 650, "Pantalla fuera de límites: " + screen)
 app.game.begin(app.profile.data.lineup, app.profile.data.levels, int(app.profile.data.captain), app.cards)
 app._go("match")
 await process_frame
 await process_frame
 check(app.pitch.size.x > 1000 and app.pitch.size.y > 420, "El campo debe dominar la pantalla")
 app._select_player(6)
 await process_frame
 await process_frame
 check(app.target == 6, "Tocar al jugador elige receptor")
 check(app.pitch.preview_data.has("defender"), "Se previsualiza al rival antes de actuar")
 app.game.state.log = "Nombre muy largo y texto de jugada que debe desplazarse sin ampliar el campo. ".repeat(15)
 app.target = 6
 app.action = "decoy"
 app._render()
 await process_frame
 await process_frame
 check(app.pitch.get_global_rect().end.y <= 600, "Un texto largo no debe sacar las cartas de la pantalla")
 app.target = 6
 app._select_action("shot")
 check(app.target == -1, "Al tirar se elimina el receptor anterior")
 app.game.state.home[4] = [.70, .17]
 app.game.execute("shot")
 app._render()
 await process_frame
 await process_frame
 check(is_instance_valid(app.gauge), "Duelo presenta pulso manual")
 check(app.approach_buttons.size() == 3, "Duelo presenta tres enfoques")
 check(app.strike_button.disabled, "No resolver antes de elegir enfoque")
 app._choose_approach(1)
 check(app.duel_started and not app.strike_button.disabled, "El enfoque activa la intervención")
 check(app.strike_button.get_global_rect().end.y <= app.get_viewport_rect().size.y, "Botón de duelo debe caber en pantalla")
 check(app.approach_buttons[2].get_global_rect().end.x <= app.get_viewport_rect().size.x, "Enfoques deben caber a lo ancho")
 app.game.state.finished = true
 app.game.state.pending = {}
 app._render()
 await process_frame
 print("RUPTURE_UI: home, team, cards, field, preview, duel, result; %s failures" % failures)
 app.sound.stop()
 app.sound.stream = null
 app.queue_free()
 await process_frame
 quit(0 if failures == 0 else 1)
