extends SceneTree
var failures = 0
class MemoryProfile:
 extends RefCounted
 var data: Dictionary = {}
 func save() -> bool:
  return true

func _initialize() -> void:
 call_deferred("_run")
func check(condition: bool,message: String) -> void:
 if not condition:
  failures += 1
  push_error(message)
func frames() -> void:
 await process_frame
 await process_frame
func _run() -> void:
 var app = load("res://main.tscn").instantiate()
 root.add_child(app)
 await frames()
 var memory = MemoryProfile.new()
 memory.data = app.profile.data.duplicate(true)
 app.profile = memory
 for screen in ["home","team","cards"]:
  app._go(screen)
  await frames()
  check(app.content.size.x<=696 and app.content.size.y<=1470,"Pantalla vertical dentro de límites: "+screen)
 app._go("home")
 app._open_showcase()
 await frames()
 var before_showcase = JSON.stringify(app.profile.data)
 await app._preview_move(444,"shot")
 await frames()
 check(JSON.stringify(app.profile.data)==before_showcase,"La muestra no cobra PT, altera guardado ni desbloquea técnicas")
 check(not app.busy,"La muestra devuelve el control al terminar")
 app.game.begin(app.profile.data.lineup,app.profile.data.levels,int(app.profile.data.captain),app.cards)
 app._go("match")
 await frames()
 check(app.pitch.size.x>=680 and app.pitch.size.x<=696,"Campo ocupa todo el ancho")
 check(app.pitch.size.y>=1120,"Campo ocupa la mayor parte de la altura")
 check(app.pitch.point(Vector2(.9,.5)).y<app.pitch.point(Vector2(.1,.5)).y,"Se ataca hacia arriba")
 check(app.pitch.actor_nodes.size()==14,"Catorce retratos circulares")
 check(app.super_button.get_global_rect().end.x<=720,"SÚPER cabe a la derecha")
 check(app.super_button.get_global_rect().end.y<=1600,"Controles caben abajo")
 app._select_player(6)
 await frames()
 check(app.target==6 and app.pitch.preview_data.has("defender"),"Selector y rival visibles")
 app.game.state.log = "Texto largo que no debe reducir el campo. ".repeat(30)
 app.action = "decoy"
 app._render()
 await frames()
 check(app.pitch.size.y>=1120,"Los textos largos no reducen el campo")
 check(app.confirm_button.get_global_rect().end.y<1500,"Confirmación al alcance")
 app._open_super_menu()
 await frames()
 check(is_instance_valid(app.super_overlay),"Menú de técnicas accesible")
 check(app.super_overlay.get_global_rect().size==app.get_viewport_rect().size,"Menú de técnicas llena la pantalla")
 await app._use_super("eternal-xi-n-wg-010-st1")
 await frames()
 check(app.game.state.pending.kind=="dribble","Regate especial activa duelo propio")
 check(app.game.state.pending.technique.name=="Regate del Eclipse","Se muestra técnica real")
 check(is_instance_valid(app.gauge),"El duelo especial mantiene control manual")
 check(app.strike_button.get_global_rect().end.y<=1600,"Pulso especial dentro de pantalla")
 app._choose_approach(1)
 check(app.duel_started and not app.strike_button.disabled,"Enfoque inicia pulso")
 app.game.state.pending = {}
 app.game.state.home[4] = [.70,.17]
 app.game.execute("shot")
 app._render()
 await frames()
 check(is_instance_valid(app.boost_button),"El tiro permite activar su supertécnica")
 check(app.approach_buttons.size()==3,"Tres enfoques en vertical")
 check(app.approach_buttons[2].get_global_rect().end.x<=720,"Enfoques caben a lo ancho")
 await app._duel_super("eternal-xi-n-wg-010-st2")
 await frames()
 check(app.game.state.pending.get("super",false),"Activación especial en duelo")
 check(app.strike_button.get_global_rect().end.y<=1600,"Duelo de tiro completo visible")
 app.game.resolve_duel(.5,1)
 app.game.state.technique_points = 60
 app._render()
 await frames()
 check(is_instance_valid(app.boost_button),"Superparada disponible")
 check(app.strike_button.get_global_rect().end.y<=1600,"Duelo defensivo cabe en vertical")
 app.game.state.finished = true
 app.game.state.pending = {}
 app._render()
 await frames()
 print("RUPTURE_UI: portrait field, circles, super menu, 2 cinematics, shot/save duels; %s failures" % failures)
 app.sound.stop()
 app.sound.stream = null
 app.queue_free()
 await frames()
 quit(0 if failures==0 else 1)
