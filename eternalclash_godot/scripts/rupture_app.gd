extends Control

const Rules = preload("res://scripts/rupture_engine.gd")
const Profile = preload("res://scripts/profile.gd")
const Field = preload("res://scripts/rupture_pitch.gd")
const Gauge = preload("res://scripts/pulse_gauge.gd")
const SuperScene = preload("res://scripts/super_cinematic.gd")
const PortraitSuperScene = preload("res://scripts/super_portrait_cinematic.gd")
const BG = Color("09131f")
const PANEL = Color("142638")
const GOLD = Color("f4cf7a")
const GREEN = Color("6be3c5")
const MUTED = Color("a2b7c8")
var game = Rules.new()
var profile = Profile.new()
var cards: Dictionary = {}
var portraits: Dictionary = {}
var roster: Array = []
var frame: Control
var content: Control
var page: String = "home"
var action: String = "pass"
var target: int = -1
var slot: int = -1
var previous: Dictionary = {}
var notice: String = ""
var busy: bool = false
var pitch
var gauge
var duel_started: bool = false
var approach: int = -1
var approach_buttons: Array = []
var strike_button: Button
var duel_note: Label
var sound: AudioStreamPlayer
var super_overlay: Control
var super_button: Button
var confirm_button: Button
var boost_button: Button

func _ready() -> void:
 var catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/cards.json"))
 for card in catalog.cards:
  var id = int(card.playerId)
  cards[id] = card
  portraits[id] = load("res://art/portraits/%s.png" % id)
  if card.team == "Eternal XI":
   roster.append(id)
 profile.load_profile()
 if not _lineup_valid(profile.data.lineup):
  profile.data.lineup = profile.defaults().lineup
 if not profile.data.match.is_empty():
  game.restore(profile.data.match, cards)
 sound = AudioStreamPlayer.new()
 sound.volume_db = -10
 add_child(sound)
 _theme()
 _render()

func _process(_delta: float) -> void:
 if duel_started and is_instance_valid(gauge) and gauge.elapsed > 7.0 and not busy:
  _resolve_pulse(true)

func _notification(what: int) -> void:
 if what == NOTIFICATION_APPLICATION_PAUSED and not profile.data.is_empty():
  _save()
 if what == NOTIFICATION_APPLICATION_RESUMED and is_instance_valid(frame) and not busy:
  duel_started = false
  if is_instance_valid(gauge):
   gauge.running = false
   _render()

func _theme() -> void:
 var design = Theme.new()
 design.default_font_size = 22
 design.set_color("font_color", "Label", Color("f5f8fc"))
 design.set_color("font_color", "Button", Color("f5f8fc"))
 design.set_color("font_disabled_color", "Button", Color("667b8b"))
 for type in ["normal", "hover", "pressed", "disabled"]:
  design.set_stylebox(type, "Button", _box(Color("263d54") if type != "disabled" else Color("122231"), 12))
 theme = design

func _box(color: Color, radius: int = 18) -> StyleBoxFlat:
 var box = StyleBoxFlat.new()
 box.bg_color = color
 box.set_corner_radius_all(radius)
 box.set_content_margin_all(16)
 return box

func _label(value: String, size_value: int = 22, color: Color = Color.WHITE) -> Label:
 var label = Label.new()
 label.text = value
 label.add_theme_font_size_override("font_size", size_value)
 label.add_theme_color_override("font_color", color)
 label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 return label

func _button(value: String, callback: Callable, primary: bool = false) -> Button:
 var button = Button.new()
 button.text = value
 button.custom_minimum_size.y = 54
 button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 button.pressed.connect(callback)
 if primary:
  for state_name in ["normal", "hover", "pressed"]:
   button.add_theme_stylebox_override(state_name, _box(GOLD, 12))
  button.add_theme_color_override("font_color", BG)
  button.add_theme_color_override("font_hover_color", BG)
  button.add_theme_color_override("font_pressed_color", BG)
 return button

func _panel(parent: Node, width: float = 0) -> VBoxContainer:
 var panel = PanelContainer.new()
 panel.add_theme_stylebox_override("panel", _box(PANEL))
 if width > 0:
  panel.custom_minimum_size.x = width
 parent.add_child(panel)
 var column = VBoxContainer.new()
 column.add_theme_constant_override("separation", 10)
 panel.add_child(column)
 return column

func _portrait(id: int, height: float, width: float = 0) -> TextureRect:
 var image = TextureRect.new()
 image.texture = portraits[id]
 image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 image.custom_minimum_size = Vector2(width, height)
 image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 return image

func _render() -> void:
 boost_button = null
 gauge = null
 duel_started = false
 approach_buttons = []
 if is_instance_valid(frame):
  remove_child(frame)
  frame.queue_free()
 frame = Control.new()
 frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(frame)
 var background = ColorRect.new()
 background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 background.color = BG
 background.mouse_filter = Control.MOUSE_FILTER_IGNORE
 frame.add_child(background)
 var margin = MarginContainer.new()
 margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for side in ["left", "right"]:
  margin.add_theme_constant_override("margin_" + side,12)
 margin.add_theme_constant_override("margin_top",30)
 margin.add_theme_constant_override("margin_bottom",28)
 frame.add_child(margin)
 var column = VBoxContainer.new()
 column.add_theme_constant_override("separation",8)
 margin.add_child(column)
 var header = HBoxContainer.new()
 header.custom_minimum_size.y = 58
 header.add_theme_constant_override("separation",12)
 column.add_child(header)
 if page == "match":
  var back = _button("‹ Inicio",_go.bind("home"))
  back.custom_minimum_size.x = 108
  back.size_flags_horizontal = Control.SIZE_FILL
  header.add_child(back)
 var title = _label("RUPTURA",25,GOLD)
 title.custom_minimum_size.x = 155
 header.add_child(title)
 var status = _label("%s monedas · 0.4" % int(profile.data.coins),21,MUTED)
 status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
 status.custom_minimum_size.x = 280
 if page == "match" and not game.state.is_empty():
  status.text = "XI  %s : %s  ADLER" % [int(game.state.score),int(game.state.rival_score)]
  status.add_theme_font_size_override("font_size",25)
  status.add_theme_color_override("font_color",Color.WHITE)
 header.add_child(status)
 content = Control.new()
 content.size_flags_vertical = Control.SIZE_EXPAND_FILL
 column.add_child(content)
 match page:
  "match": _match_page()
  "team": _team_page()
  "cards": _cards_page()
  _: _home_page()
 if page != "match":
  var nav = HBoxContainer.new()
  nav.custom_minimum_size.y = 70
  nav.add_theme_constant_override("separation",10)
  column.add_child(nav)
  for entry in [["Inicio","home"],["Equipo","team"],["Cartas","cards"]]:
   nav.add_child(_button(entry[0],_go.bind(entry[1]),page==entry[1]))
 if page == "match" and not game.state.pending.is_empty() and not game.state.finished:
  _duel_overlay()

func _fill(node: Control, parent: Node) -> void:
 parent.add_child(node)
 node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _home_page() -> void:
 var scroll = ScrollContainer.new()
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 _fill(scroll,content)
 var column = VBoxContainer.new()
 column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 column.add_theme_constant_override("separation",18)
 scroll.add_child(column)
 var hero = PanelContainer.new()
 hero.custom_minimum_size.y = 440
 hero.clip_contents = true
 hero.add_theme_stylebox_override("panel",_box(PANEL))
 column.add_child(hero)
 var image = TextureRect.new()
 image.texture = load("res://art/institute.png")
 image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
 hero.add_child(image)
 var shade = ColorRect.new()
 shade.color = Color(0.02,0.04,0.08,0.35)
 shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
 hero.add_child(shade)
 var words = VBoxContainer.new()
 hero.add_child(words)
 words.add_child(_label("EL BALÓN SE MUEVE.\nLA HUELLA PERMANECE.",32,GOLD))
 var spacer = Control.new()
 spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
 words.add_child(spacer)
 words.add_child(_label("Crea el hueco.\nDesata tu supertécnica.",30))
 var play = _button("CONTINUAR PARTIDO" if _active() else "JUGAR RUPTURA",_start,true)
 play.custom_minimum_size.y = 86
 column.add_child(play)
 var showcase = _button("VER SUPERTÉCNICAS",_open_showcase)
 showcase.custom_minimum_size.y = 70
 column.add_child(showcase)
 var rules = _panel(column)
 rules.add_child(_label("TOCA, ENLAZA Y ROMPE",26,GOLD))
 rules.add_child(_label("Elige una carta, toca al compañero y confirma la ruta. Paredes y señuelos abren huecos para el remate.",24))
 rules.add_child(_label("SÚPER abre las técnicas del jugador que lleva el balón. Los pases recargan PT. También puedes activar una superparada en los duelos del portero.",23,GREEN))
 rules.add_child(_label("3 jugadores + amplitud + profundidad = RUPTURA.\nLee al rival y pulsa en verde para ganar el duelo.",23,MUTED))
 if not notice.is_empty():
  rules.add_child(_label(notice,22,GOLD))

func _match_page() -> void:
 if game.state.finished:
  _results()
  return
 var column = VBoxContainer.new()
 column.add_theme_constant_override("separation",8)
 _fill(column,content)
 var info_bar = HBoxContainer.new()
 info_bar.custom_minimum_size.y = 32
 column.add_child(info_bar)
 var pulses = _label("ATAQUE %s/6   ·   %s PULSOS" % [int(game.state.round),int(game.state.beats)],19,MUTED)
 pulses.custom_minimum_size.x = 220
 pulses.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 info_bar.add_child(pulses)
 var links_label = _label("RUPTURA LISTA" if game.rupture_ready() else "RED %s/3" % mini(3,game.state.chain.size()),19,GREEN)
 links_label.custom_minimum_size.x = 180 if game.rupture_ready() else 100
 info_bar.add_child(links_label)
 var points_label = _label("%s PT" % int(game.state.technique_points),21,GOLD)
 points_label.custom_minimum_size.x = 90
 points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
 info_bar.add_child(points_label)
 pitch = Field.new()
 pitch.game = game
 pitch.textures = portraits
 pitch.action = action
 pitch.selected = target
 pitch.preview_data = game.preview(action,target)
 pitch.previous = previous
 pitch.size_flags_vertical = Control.SIZE_EXPAND_FILL
 pitch.player_tapped.connect(_select_player)
 column.add_child(pitch)
 var info = game.preview(action,target)
 var strip = PanelContainer.new()
 strip.custom_minimum_size.y = 98
 strip.add_theme_stylebox_override("panel",_box(PANEL,12))
 column.add_child(strip)
 var row = HBoxContainer.new()
 row.add_theme_constant_override("separation",12)
 strip.add_child(row)
 var carrier = game._short(int(game.state.lineup[int(game.state.holder)]))
 var text = carrier + " · toca a un compañero"
 if action == "shot":
  text = carrier + " contra Magnus"
 elif target >= 1:
  text = carrier + " → " + game._short(int(game.state.lineup[target]))
 if target >= 1 or action == "shot":
  text += "\n" + str(info.reason)
 else:
  text += "\nElige una ruta o pulsa SÚPER."
 var explanation = _label(text,20,GREEN if info.get("legal",false) else MUTED)
 explanation.max_lines_visible = 3
 explanation.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 row.add_child(explanation)
 confirm_button = _button("EJECUTAR\n" + {"pass":"PASE","wall":"PARED","decoy":"SEÑUELO","shot":"TIRO"}[action],_execute,true)
 confirm_button.custom_minimum_size = Vector2(174,72)
 confirm_button.size_flags_horizontal = Control.SIZE_FILL
 confirm_button.add_theme_font_size_override("font_size",18)
 confirm_button.disabled = not info.get("legal",false)
 row.add_child(confirm_button)
 var hand = HBoxContainer.new()
 hand.custom_minimum_size.y = 86
 hand.add_theme_constant_override("separation",7)
 column.add_child(hand)
 for entry in [["PASE","pass","1 pulso"],["PARED","wall","2 pulsos"],["SEÑUELO","decoy","1 pulso"],["RUPTURA" if game.rupture_ready() else "TIRO","shot","1 pulso"]]:
  var button = _button(entry[0]+"\n"+entry[2],_select_action.bind(entry[1]),action==entry[1])
  button.add_theme_font_size_override("font_size",18)
  button.disabled = int(game.state.beats) < game.cost(entry[1])
  for style in ["normal","hover","pressed"]:
   var box = _box(GOLD if action==entry[1] else Color("263d54"),12)
   box.content_margin_left = 8
   box.content_margin_right = 8
   button.add_theme_stylebox_override(style,box)
  hand.add_child(button)
 super_button = _button("SÚPER\n%s PT" % int(game.state.technique_points),_open_super_menu)
 super_button.add_theme_font_size_override("font_size",18)
 var super_style = _box(Color("48375f"),12)
 super_style.content_margin_left = 8
 super_style.content_margin_right = 8
 super_style.border_color = Color("b79aff")
 super_style.set_border_width_all(2)
 super_button.add_theme_stylebox_override("normal",super_style)
 super_button.disabled = int(game.state.beats)<1
 hand.add_child(super_button)

func _select_player(index: int) -> void:
 if busy or not game.state.pending.is_empty():
  return
 if index == int(game.state.holder):
  notice = "Ese jugador ya tiene el balón."
  return
 target = index
 previous = {}
 _render()

func _select_action(value: String) -> void:
 if busy:
  return
 action = value
 if value == "shot":
  target = -1
 previous = {}
 _render()

func _execute() -> void:
 if busy:
  return
 previous = game.state.duplicate(true)
 var result = game.execute(action, target)
 if not result.get("accepted", false):
  return
 _sfx("pass")
 target = -1
 action = "pass"
 _save()
 _render()

func _duel_overlay() -> void:
 var duel = game.state.pending
 var overlay = ColorRect.new()
 overlay.color = Color(0.015,0.035,0.065,0.98)
 _fill(overlay,frame)
 var margin = MarginContainer.new()
 for side in ["left","right","top","bottom"]:
  margin.add_theme_constant_override("margin_"+side,24)
 _fill(margin,overlay)
 var layout = VBoxContainer.new()
 layout.add_theme_constant_override("separation",12)
 margin.add_child(layout)
 var defense = duel.kind=="defend"
 var kind = "CONTRAATAQUE · CONTROLA AL PORTERO" if defense else "DUELO DE REGATE" if duel.kind=="dribble" else "RUPTURA · REMATE COMBINADO" if duel.kind=="shot" and duel.rupture else "DUELO DE TIRO" if duel.kind=="shot" else "DUELO DE INTERCEPCIÓN"
 layout.add_child(_label(kind,25,GOLD))
 var heroes = HBoxContainer.new()
 heroes.add_theme_constant_override("separation",20)
 heroes.size_flags_vertical = Control.SIZE_EXPAND_FILL
 layout.add_child(heroes)
 for id in [int(duel.left),int(duel.right)]:
  var own = id==int(duel.left)
  var hero = VBoxContainer.new()
  hero.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  hero.custom_minimum_size.x = 300
  heroes.add_child(hero)
  var name_label = _label(_name(id),26,GREEN if own else Color("f0a18b"))
  name_label.custom_minimum_size.y = 68
  name_label.max_lines_visible = 3
  hero.add_child(name_label)
  var image = _portrait(id,220)
  image.size_flags_vertical = Control.SIZE_EXPAND_FILL
  hero.add_child(image)
  var detail = str(duel.technique.name) if own and duel.get("super",false) else "PARADA NORMAL" if own and defense else "TIRO NORMAL" if own and duel.kind=="shot" else "REGATE" if own and duel.kind=="dribble" else "PASE" if own else "BASTION ADLER"
  var label = _label(detail,22,GOLD if own and duel.get("super",false) else MUTED)
  label.custom_minimum_size.y = 60
  hero.add_child(label)
 var intent_box = _panel(layout)
 intent_box.add_child(_label("INTENCIÓN DEL RIVAL",18,MUTED))
 intent_box.add_child(_label((game.SHOT_INTENTS if defense else game.STANCES)[int(duel.stance)].to_upper(),27,Color("f0a18b")))
 var options = game.available_duel_techniques()
 if not options.is_empty():
  var technique = options[0]
  var boost = _button("SÚPER · %s\n%s PT · refuerza este duelo" % [technique.name,game.technique_cost(technique)],_duel_super.bind(str(technique.id)),true)
  boost_button = boost
  boost.custom_minimum_size.y = 76
  boost.add_theme_font_size_override("font_size",21)
  layout.add_child(boost)
 elif duel.get("super",false):
  layout.add_child(_label("SUPERTÉCNICA ACTIVA · zona de acierto ampliada",21,GOLD))
 var approaches = VBoxContainer.new()
 approaches.add_theme_constant_override("separation",9)
 layout.add_child(approaches)
 approach_buttons = []
 for i in range(3):
  var labels = ["BLOQUEAR · contra el tiro potente","ESTIRARSE · contra la escuadra","AGUANTAR · contra el amago"] if defense else ["POTENCIA · rompe la espera","EFECTO · rodea el cierre","AMAGO · castiga la presión"]
  var button = _button(labels[i],_choose_approach.bind(i))
  button.custom_minimum_size.y = 70
  approaches.add_child(button)
  approach_buttons.append(button)
 duel_note = _label("Elige tu enfoque; después pulsa en verde.",22,GOLD)
 layout.add_child(duel_note)
 gauge = Gauge.new()
 gauge.speed = 0.50+int(duel.stance)*0.045+int(game.state.round)*0.025
 gauge.custom_minimum_size.y = 84
 layout.add_child(gauge)
 strike_button = _button("ELIGE UN ENFOQUE PARA EMPEZAR",_resolve_pulse.bind(false),true)
 strike_button.custom_minimum_size.y = 94
 strike_button.add_theme_font_size_override("font_size",22)
 strike_button.disabled = true
 layout.add_child(strike_button)

func _choose_approach(value: int) -> void:
 if duel_started or busy:
  return
 approach = value
 if is_instance_valid(boost_button):
  boost_button.disabled = true
 gauge.target_width = game.duel_width(value)
 gauge.elapsed = 0.0
 gauge.running = true
 duel_started = true
 for button in approach_buttons:
  button.disabled = true
 var correct = value == game.COUNTERS[int(game.state.pending.stance)]
 duel_note.text = "¡Buena lectura! Pulsa en la zona verde." if correct else "ENFOQUE DIFÍCIL · BUSCA LA ZONA VERDE"
 strike_button.text = "¡AHORA! · PULSA EN VERDE"
 strike_button.disabled = false
 _sfx("pass")

func _resolve_pulse(timed_out: bool = false) -> void:
 if not duel_started or busy or not is_instance_valid(gauge):
  return
 busy = true
 duel_started = false
 gauge.running = false
 var before_duel = game.state.duplicate(true)
 var result = game.resolve_duel(gauge.pointer, approach, timed_out)
 if game.state.finished:
  profile.settle(game.state, game.outcome())
 _save()
 _sfx("goal" if result.success else "miss")
 var result_overlay = ColorRect.new()
 result_overlay.color = Color(0.02, 0.08, 0.11, 0.96)
 _fill(result_overlay, frame)
 var center = CenterContainer.new()
 _fill(center, result_overlay)
 var column = VBoxContainer.new()
 column.custom_minimum_size.x = 620
 center.add_child(column)
 var headline = _label("¡PULSO PERFECTO!" if result.perfect else "¡DUELO GANADO!" if result.success else "DUELO PERDIDO", 36, GOLD if result.success else Color("ed9c88"))
 headline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 column.add_child(headline)
 var explanation = _label(result.text, 26)
 explanation.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 column.add_child(explanation)
 await get_tree().create_timer(1.6).timeout
 busy = false
 previous = before_duel if result.kind == "dribble" and result.success else {}
 _render()

func _results() -> void:
 var scroll = ScrollContainer.new()
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 _fill(scroll,content)
 var column = VBoxContainer.new()
 column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 column.add_theme_constant_override("separation",20)
 scroll.add_child(column)
 var outcome = game.outcome()
 column.add_child(_label({"victory":"¡RUPTURA VICTORIOSA!","draw":"EMPATE","defeat":"ADLER GANA ESTA VEZ"}[outcome],34,GOLD))
 column.add_child(_label("ETERNAL XI  %s : %s  ADLER" % [int(game.state.score),int(game.state.rival_score)],34))
 column.add_child(_portrait(434,320))
 column.add_child(_label("+%s monedas · progreso guardado" % (100 if outcome=="victory" else 50),26,GREEN))
 column.add_child(_button("OTRO PARTIDO",_start,true))
 column.add_child(_button("CAMBIAR EQUIPO",_go.bind("team")))

func _scroll_grid(columns: int) -> GridContainer:
 var scroll = ScrollContainer.new()
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 _fill(scroll, content)
 var grid = GridContainer.new()
 grid.columns = columns
 grid.add_theme_constant_override("h_separation", 12)
 grid.add_theme_constant_override("v_separation", 12)
 grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 scroll.add_child(grid)
 return grid

func _team_page() -> void:
 var grid = _scroll_grid(2)
 var ids: Array = profile.data.lineup if slot < 0 else roster
 for i in range(ids.size()):
  var id = int(ids[i])
  if slot >= 0 and (id in profile.data.lineup or (cards[id].position == "goalkeeper") != (slot == 0)):
   continue
  var column = _panel(grid)
  column.get_parent().custom_minimum_size.x = 320
  column.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
  column.add_child(_label("POSICIÓN %s" % (i + 1) if slot < 0 else "REEMPLAZO", 19, GOLD))
  column.add_child(_portrait(id, 160))
  column.add_child(_label(_name(id), 23))
  column.add_child(_label("NIVEL %s · %s" % [_level(id), _position(cards[id].position)], 19, MUTED))
  column.add_child(_button("Cambiar" if slot < 0 else "Elegir", _pick_slot.bind(i) if slot < 0 else _replace.bind(id)))
  if slot < 0:
   column.add_child(_button("CAPITÁN" if int(profile.data.captain) == id else "Capitán", _captain.bind(id)))
 if slot >= 0:
  var back = _button("Cancelar", _cancel_picker)
  grid.add_child(back)

func _cards_page() -> void:
 var grid = _scroll_grid(2)
 for id in roster:
  var column = _panel(grid)
  column.get_parent().custom_minimum_size.x = 320
  column.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
  column.add_child(_label("CARTA N · " + _position(cards[id].position), 20, GOLD))
  column.add_child(_portrait(id, 145))
  column.add_child(_label(_name(id), 23))
  column.add_child(_label("NV. %s · PASE %s · TIRO %s" % [_level(id), int(cards[id].stats.pass), int(cards[id].stats.shot)], 19, MUTED))
  var button = _button("Mejorar · %s" % (_level(id) * 50), _train.bind(id))
  button.disabled = int(profile.data.coins) < _level(id) * 50 or _level(id) >= 10 or _active()
  column.add_child(button)

func _pick_slot(index: int) -> void:
 if _active():
  notice = "Termina el partido para cambiar la formación."
  _go("home")
  return
 slot = index
 _render()

func _cancel_picker() -> void:
 slot = -1
 _render()

func _replace(id: int) -> void:
 profile.data.lineup[slot] = id
 if not int(profile.data.captain) in profile.data.lineup:
  profile.data.captain = id
 slot = -1
 _save()
 _render()

func _captain(id: int) -> void:
 if not _active():
  profile.data.captain = id
  _save()
 _render()

func _train(id: int) -> void:
 if not _active() and profile.train(id):
  _save()
 _render()

func _active() -> bool:
 return not game.state.is_empty() and not game.state.finished

func _start() -> void:
 if not _active():
  game.begin(profile.data.lineup, profile.data.levels, int(profile.data.captain), cards)
 action = "pass"
 target = -1
 previous = {}
 _save()
 _go("match")

func _go(value: String) -> void:
 if busy:
  return
 page = value
 slot = -1
 previous = {}
 _render()

func _save() -> void:
 if not game.state.is_empty():
  profile.data.match = game.state.duplicate(true)
 if not profile.save():
  notice = "Error al guardar. Informa antes de cerrar la prueba."
  push_error(notice)

func _lineup_valid(ids: Array) -> bool:
 var unique: Dictionary = {}
 for id in ids:
  if int(id) not in roster:
   return false
  unique[int(id)] = true
 return ids.size() == 7 and unique.size() == 7 and cards[int(ids[0])].position == "goalkeeper"

func _level(id: int) -> int:
 return int(profile.data.levels.get(str(id), 1))

func _name(id: int) -> String:
 return str(cards[id].name)

func _position(value: String) -> String:
 return {"goalkeeper": "POR", "fullBack": "LAT", "centreBack": "DEF", "defensiveMidfielder": "MCD", "attackingMidfielder": "MP", "winger": "EXT", "striker": "DEL"}.get(value, value)

func _technique(id: int, type: String) -> String:
 for technique in cards[id].get("superTechniques", []):
  if technique.type == type:
   return str(technique.name)
 return {"shot": "Disparo combinado", "save": "Defensa de la portería", "pass": "Pase de enlace", "defense": "Cierre de línea"}.get(type, "Técnica de equipo")

func _sfx(kind: String) -> void:
 if DisplayServer.get_name() == "headless":
  return
 var path = "res://audio/%s.wav" % kind
 if ResourceLoader.exists(path):
  sound.stream = load(path)
  sound.play()

func _open_super_menu() -> void:
 if busy or game.state.is_empty() or not game.state.pending.is_empty():
  return
 var id = int(game.state.lineup[int(game.state.holder)])
 super_overlay = ColorRect.new()
 super_overlay.color = Color(0.02,0.025,0.065,0.98)
 _fill(super_overlay,frame)
 var margin = MarginContainer.new()
 for side in ["left","right","top","bottom"]:
  margin.add_theme_constant_override("margin_"+side,28)
 _fill(margin,super_overlay)
 var column = VBoxContainer.new()
 column.add_theme_constant_override("separation",20)
 margin.add_child(column)
 column.add_child(_label("SUPERTÉCNICAS · %s PT" % int(game.state.technique_points),28,GOLD))
 column.add_child(_label(_name(id),30))
 var image = _portrait(id,280)
 image.size_flags_vertical = Control.SIZE_EXPAND_FILL
 column.add_child(image)
 for technique in cards[id].get("superTechniques",[]):
  var check = game.preview_super(str(technique.id),target)
  var panel = _panel(column)
  var button = _button("%s · %s PT" % [technique.name,game.technique_cost(technique)],_use_super.bind(str(technique.id)),true)
  button.custom_minimum_size.y = 80
  button.add_theme_font_size_override("font_size",23)
  button.disabled = not check.legal
  panel.add_child(button)
  panel.add_child(_label(check.reason,22,GREEN if check.legal else MUTED))
 column.add_child(_label("Los pases recargan PT. Activar una técnica consume 1 pulso; aún tienes que ganar su duelo.",22,MUTED))
 column.add_child(_button("VOLVER AL CAMPO",_render))

func _use_super(technique_id: String) -> void:
 if busy:
  return
 var id = int(game.state.lineup[int(game.state.holder)])
 previous = game.state.duplicate(true)
 var result = game.execute_super(technique_id,target)
 if not result.get("accepted",false):
  return
 _save()
 target = -1
 await _show_super(result.technique,id)
 _render()

func _duel_super(technique_id: String) -> void:
 if busy or duel_started:
  return
 var id = int(game.state.pending.left)
 var result = game.activate_duel_technique(technique_id)
 if not result.get("accepted",false):
  return
 _save()
 await _show_super(result.technique,id)
 _render()

func _show_super(technique: Dictionary,id: int) -> void:
 busy = true
 # Solo mostramos un cuerpo propio cuando existe su apariencia preparada.
 var cinema = SuperScene.new() if id in [434,444,435] else PortraitSuperScene.new()
 cinema.technique = technique.duplicate(true)
 cinema.technique.cost = game.technique_cost(technique)
 cinema.portrait = portraits[id]
 cinema.player_name = _name(id)
 cinema.player_id = id
 _fill(cinema,frame)
 _sfx("super")
 await cinema.finished
 busy = false
 cinema.queue_free()

func _open_showcase() -> void:
 if busy:
  return
 var panel = PanelContainer.new()
 panel.add_theme_stylebox_override("panel",_box(BG,0))
 _fill(panel,frame)
 var column = VBoxContainer.new()
 column.add_theme_constant_override("separation",18)
 panel.add_child(column)
 column.add_child(_label("SUPERTÉCNICAS",32,GOLD))
 column.add_child(_label("Prueba visual · Sin gastar PT",24,GREEN))
 column.add_child(_label("El mismo movimiento con dos personajes. Esta muestra no desbloquea técnicas en el partido.",22,MUTED))
 var actors = HBoxContainer.new()
 column.add_child(actors)
 for id in [434,444]:
  var card = VBoxContainer.new()
  card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  actors.add_child(card)
  card.add_child(_portrait(id,310,280))
  card.add_child(_label(_name(id),22))
  var button = _button("Disparo Valestia",_preview_move.bind(id,"shot"),true)
  button.custom_minimum_size.y = 76
  card.add_child(button)
 for entry in [["Regate del Eclipse",434,"dribble"],["Muro de Puños",435,"save"]]:
  var button = _button(entry[0],_preview_move.bind(entry[1],entry[2]))
  button.custom_minimum_size.y = 76
  column.add_child(button)
 column.add_child(_button("Volver",_render))

func _preview_move(id: int,kind: String) -> void:
 if busy:
  return
 var source = cards[435 if kind=="save" else 434]
 for technique in source.superTechniques:
  if technique.type == kind:
   await _show_super(technique,id)
   return
