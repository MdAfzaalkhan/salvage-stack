extends Node
const Arena = preload("res://scripts/arena.gd")
const Store = preload("res://scripts/store.gd")
const Sound = preload("res://scripts/audio.gd")
const Commerce = preload("res://scripts/commerce.gd")
const Content = preload("res://scripts/content.gd")
const Preview = preload("res://scripts/preview.gd")
const Coach = preload("res://scripts/coach.gd")
const Glass = preload("res://scripts/glass.gd")
const Hero = preload("res://scripts/hero.gd")
const SequenceCard = preload("res://scripts/sequence_card.gd")
const ExtractionFX = preload("res://scripts/extraction_fx.gd")
const INK = Color("f4f5fa")
const MUTED = Color("aeb5c6")
const AMBER = Color("ffbc3d")
const CREAM = Color("08090e")
var store = Store.new()
var commerce = Commerce.new()
var audio: Node
var arena: Node2D
var ui: Control
var overlay: Control
var menu: Control
var hud: Control
var screen = "startup"
var overlay_kind = ""
var settings_return = "home"
var current = 0
var dragged = false
var result_pending = false
var round_token = 0
var last_result: Dictionary = {}
var screen_size = Vector2(720,1280)
var top_inset = 30.0
var bottom_inset = 28.0
var theme: Theme
var coach_step: Label
var coach_message: Label
var coach_note: Label
var coach_panel: PanelContainer
var action_button: Button
var effects: Node2D
var background: TextureRect
var held_pointer = false
var objective_buttons: Array = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().auto_accept_quit = false
	if OS.has_environment("SALVAGE_TEST_SAVE_PATH"):
		store.path = OS.get_environment("SALVAGE_TEST_SAVE_PATH")
	store.load_save()
	current = int(store.data.last)
	theme = preload("res://assets/dark_theme.tres")
	Glass.simple = bool(ProjectSettings.get_setting("salvage/visuals/simple_effects",false)) or OS.get_processor_count()<=4
	var background_layer = CanvasLayer.new()
	background_layer.layer = -10
	add_child(background_layer)
	background = TextureRect.new()
	background.texture = preload("res://assets/background.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background_layer.add_child(background)
	background.modulate.a = 0
	background.create_tween().tween_property(background,"modulate:a",1.0,0.25)
	var layer = CanvasLayer.new()
	add_child(layer)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.theme = theme
	layer.add_child(ui)
	effects = Node2D.new()
	effects.process_mode = Node.PROCESS_MODE_PAUSABLE
	ui.add_child(effects)
	get_viewport().size_changed.connect(_layout)
	audio = Sound.new()
	add_child(audio)
	audio.settings(store.data.settings)
	_layout()
	var intro = Label.new()
	intro.text = "SALVAGE\nSTACK"
	intro.add_theme_font_override("font",preload("res://assets/fonts/salvage-grid.fnt"))
	intro.add_theme_font_size_override("font_size",48)
	intro.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	intro.position = Vector2(0,screen_size.y/2-60)
	intro.size = Vector2(screen_size.x,120)
	ui.add_child(intro)
	await get_tree().create_timer(0.35).timeout
	intro.queue_free()
	home()
	audio.music.play()
	# Test harness uses this explicit opt-in flag; normal play has no autoplay.
	if "--capture-demo" in OS.get_cmdline_user_args():
		_demo_capture.call_deferred()

func style(color: Color, radius: int = 18) -> StyleBoxFlat:
	return Glass.panel(color,radius)

func _layout() -> void:
	var previous_overlay = overlay_kind
	var previous_settings_return = settings_return
	screen_size = get_viewport().get_visible_rect().size
	if OS.get_name() in ["Android","iOS"]:
		var safe = DisplayServer.get_display_safe_area()
		var display = DisplayServer.screen_get_size()
		if display.y>0:
			top_inset = maxf(24,float(safe.position.y)*screen_size.y/display.y+12)
			bottom_inset = maxf(24,float(display.y-safe.end.y)*screen_size.y/display.y+12)
	if is_instance_valid(arena):
		arena.position = Vector2(screen_size.x/2,screen_size.y-bottom_inset-450)
	if screen == "game" and is_instance_valid(arena):
		refresh_hud()
	elif screen == "home":
		home()
	elif screen == "sequences":
		sequences()
	if previous_overlay == "pause":
		pause_menu()
	elif previous_overlay == "settings":
		settings_menu(previous_settings_return)
	elif previous_overlay == "results" and not last_result.is_empty():
		_show_result(last_result.won,last_result.count,last_result.culprit)
	elif previous_overlay == "collection":
		collection()

func clear_control(c) -> void:
	if is_instance_valid(c) and not c.is_queued_for_deletion():
		if c.get_parent() != null:
			c.get_parent().remove_child(c)
		c.queue_free()

func surface() -> Control:
	var c = Control.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(c)
	return c

func column(parent: Control, at: Vector2, width: float, gap: int = 16) -> VBoxContainer:
	var box = VBoxContainer.new()
	box.position = at
	box.size.x = width
	box.add_theme_constant_override("separation",gap)
	parent.add_child(box)
	return box

func text(parent: Node, value: String, font_size: int = 26, color: Color = INK, centered: bool = false) -> Label:
	var l = Label.new()
	l.text = value
	l.add_theme_font_size_override("font_size",font_size)
	l.add_theme_color_override("font_color",color)
	if centered: l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func primary_style(color: Color) -> StyleBoxFlat:
	return Glass.navigation(color)

func button(parent: Node, value: String, action: Callable, primary: bool = false, height: float = 84) -> Button:
	var b = Button.new()
	b.text = value
	b.custom_minimum_size.y = height
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if primary:
		for state in ["normal","hover","pressed","hover_pressed"]:
			var color = AMBER if state=="normal" else (Color("ffd072") if state=="hover" else Color("e9a934"))
			b.add_theme_stylebox_override(state,primary_style(color))
		for key in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color"]:
			b.add_theme_color_override(key,Color("14120b"))
	b.pressed.connect(func():
		if b.is_queued_for_deletion(): return
		audio.play("ui")
		action.call()
	)
	parent.add_child(b)
	return b

func completed() -> int:
	var n = 0
	for p in store.data.progress:
		if p.won: n += 1
	return n

func home() -> void:
	_clear_held_inputs()
	_clear_effects()
	round_token += 1
	get_tree().paused = false
	result_pending = false
	overlay_kind = ""
	clear_control(overlay)
	clear_control(hud)
	clear_control(menu)
	if is_instance_valid(arena):
		arena.get_parent().remove_child(arena)
		arena.queue_free()
	arena = null
	audio.stop_effects()
	audio.music.stream_paused = false
	screen = "home"
	menu = surface()
	var col = column(menu,Vector2(48,top_inset+4),screen_size.x-96,14)
	var bar = HBoxContainer.new()
	col.add_child(bar)
	var spring = Control.new()
	spring.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spring)
	icon_button(bar,"settings","Settings",func(): settings_menu("home"))
	wordmark(col,66,true)
	var art = Hero.new()
	art.name = "Hero"
	art.animate = not store.data.settings.reduced_motion
	art.custom_minimum_size.y = clampf(screen_size.y*0.29,320,420)
	col.add_child(art)
	text(col,"BUILD. EXTRACT. RECOVER.",22,MUTED,true)
	var gap = Control.new()
	gap.custom_minimum_size.y = 12
	col.add_child(gap)
	var cp = store.data.checkpoint
	button(col,"Continue" if not cp.is_empty() else "Play",func():
		if not cp.is_empty(): start(int(cp.sequence),cp)
		else: start(current)
	,true,96)
	button(col,"Sequences",sequences,false,88)
	text(col,"%d / 12 sequences completed"%completed(),22,MUTED,true)
	if store.restored_backup: text(col,"Recovered your previous safe save.",18,MUTED,true)
	if not store.problem.is_empty(): text(col,store.problem,20,Color("ff9386"),true)
	_enter(col)

func sequences() -> void:
	_clear_held_inputs()
	screen = "sequences"
	clear_control(menu)
	menu = surface()
	var col = column(menu,Vector2(32,top_inset),screen_size.x-64,18)
	var heading = HBoxContainer.new()
	col.add_child(heading)
	icon_button(heading,"back","Home",home)
	text(heading,"SEQUENCES",34).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text(col,"%d of 12 complete"%completed(),22,MUTED)
	var scroll = ScrollContainer.new()
	scroll.name = "SequenceScroll"
	scroll.custom_minimum_size.y = screen_size.y-top_inset-bottom_inset-210
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var grid = GridContainer.new()
	grid.name = "SequenceGrid"
	grid.columns = 4 if screen_size.x>=900 else 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",16)
	grid.add_theme_constant_override("v_separation",16)
	scroll.add_child(grid)
	for i in range(12):
		var progress = store.data.progress[i]
		var card = SequenceCard.new()
		card.name = "Sequence%02d"%(i+1)
		card.index = i
		card.best = int(progress.best)
		card.won = progress.won
		card.current = i==current
		card.scroll = scroll
		card.custom_minimum_size = Vector2((screen_size.x-64-16*(grid.columns-1))/grid.columns,196)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.activated.connect(func():
			if screen=="sequences" and overlay_kind.is_empty(): start(i)
		)
		grid.add_child(card)
	if completed()==12: button(col,"Collection complete",collection,true,72)
	_enter(col)

func start(index: int, cp: Dictionary = {}) -> void:
	_clear_held_inputs()
	_clear_effects()
	round_token += 1
	get_tree().paused = false
	clear_control(overlay)
	clear_control(menu)
	clear_control(hud)
	overlay_kind = ""
	result_pending = false
	current = index
	store.data.last = current
	if cp.is_empty():
		store.data.checkpoint = {}
	store.write()
	if is_instance_valid(arena):
		arena.get_parent().remove_child(arena)
		arena.queue_free()
	arena = Arena.new()
	arena.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(arena)
	arena.position = Vector2(screen_size.x/2,screen_size.y-bottom_inset-450)
	arena.changed.connect(refresh_hud)
	arena.checkpoint.connect(func(data):
		if current==0 and data.recovered.size()>0:
			store.data.tutorial_done = true
		store.data.checkpoint = data
		store.data.progress[current].best = maxi(int(store.data.progress[current].best),data.recovered.size())
		store.write()
		refresh_hud()
	)
	arena.sound.connect(_feedback)
	arena.finished.connect(_finished)
	arena.extracted.connect(_extracted)
	screen = "game"
	dragged = false
	audio.music.stream_paused = false
	arena.begin(current,cp)
	if cp.is_empty():
		store.data.checkpoint = arena.snapshot()
		store.write()
	refresh_hud()
	hud.modulate.a=0
	hud.create_tween().tween_property(hud,"modulate:a",1.0,0.09)

func _feedback(kind: String) -> void:
	audio.play(kind)
	if store.data.settings.haptics and OS.get_name() in ["Android","iOS"] and kind in ["drop","extract","fail","complete"]:
		Input.vibrate_handheld(28 if kind=="fail" else 12,0.35)

func refresh_hud() -> void:
	if screen != "game" or not is_instance_valid(arena):
		return
	clear_control(hud)
	hud = surface()
	var top = column(hud,Vector2(32,top_inset),screen_size.x-64,12)
	var row = HBoxContainer.new()
	top.add_child(row)
	wordmark(row,26,false).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon_button(row,"pause","Pause",pause_menu)
	var extracting = arena.phase in ["extract","won"]
	var progress = arena.recovered.size() if extracting else arena.placed
	text(top,"%s · %d/%d"%["EXTRACT" if extracting else "BUILD",progress,3 if extracting else 8],28)
	var divider = ColorRect.new()
	divider.color = Color("303647")
	divider.custom_minimum_size.y = 1
	top.add_child(divider)
	var preview_row = HBoxContainer.new()
	preview_row.add_theme_constant_override("separation",14)
	preview_row.alignment = BoxContainer.ALIGNMENT_CENTER
	objective_buttons.clear()
	top.add_child(preview_row)
	if arena.phase == "build":
		for id in range(arena.placed,mini(8,arena.placed+3)):
			var slot = VBoxContainer.new()
			preview_row.add_child(slot)
			text(slot,"NOW" if id==arena.placed else "NEXT",15,AMBER if id==arena.placed else MUTED,true)
			var p = Preview.new()
			p.spec = arena.sequence.pieces[id]
			p.custom_minimum_size = Vector2(108,54)
			slot.add_child(p)
	else:
		for t in range(1,4):
			var b = button(preview_row,"%d%s"%[t,"  ✓" if arena.recovered.has(t) else ""],func(): arena.select_number(t),false,76)
			b.tooltip_text = "Treasure %d"%t
			b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			b.custom_minimum_size.x = 112
			b.disabled = arena.recovered.has(t) or arena.waiting or arena.phase!="extract"
			var edge = Glass.accent(t)
			b.add_theme_stylebox_override("normal",Glass.panel(edge.darkened(0.91),14,Color(edge,0.7)))
			if arena.selected==t: b.add_theme_stylebox_override("normal",Glass.panel(edge.darkened(0.78),14,INK))
			objective_buttons.append(b)
	var footer = column(hud,Vector2(32,screen_size.y-bottom_inset-322),screen_size.x-64,10)
	footer.name = "ActionFooter"
	coach_step = null
	coach_message = null
	coach_note = null
	coach_panel = null
	if tutorial_step()>=0:
		coach_panel = Coach.new()
		coach_panel.name = "TutorialPrompt"
		coach_panel.custom_minimum_size.y = 156
		var frame = Glass.panel(Color("151720"),18,Color("4a536b"))
		frame.set_border_width_all(1)
		frame.border_color = Color("4a536b")
		frame.content_margin_top = 10
		frame.content_margin_bottom = 16
		coach_panel.add_theme_stylebox_override("panel",frame)
		footer.add_child(coach_panel)
		var content = VBoxContainer.new()
		content.add_theme_constant_override("separation",2)
		coach_panel.add_child(content)
		var line = HBoxContainer.new()
		content.add_child(line)
		coach_step = text(line,"",22,INK)
		coach_step.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		coach_step.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var skip = button(line,"Skip",skip_tutorial,false,64)
		skip.name = "SkipTutorial"
		skip.custom_minimum_size.x = 104
		skip.add_theme_stylebox_override("normal",StyleBoxEmpty.new())
		skip.add_theme_font_size_override("font_size",21)
		coach_message = text(content,"",25,INK,true)
		coach_message.size_flags_vertical = Control.SIZE_EXPAND_FILL
		coach_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		coach_note = text(content,"Numbers are names, not an order.",19,INK,true)
	else:
		var hint = arena.sequence.note
		if current==0 and arena.phase=="build" and not store.data.tutorial_done:
			hint = "Build carefully. Then recover the three treasures.\nLet the grey bridges carry the weight."
		if arena.waiting: hint = "Settling…" if arena.action_time<8 else "Still moving. Pause → Restore checkpoint or Retry."
		if not store.problem.is_empty(): hint = store.problem
		var caption = text(footer,hint,23,MUTED,true)
		caption.custom_minimum_size.y = 156
		caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if arena.phase=="build":
		var slider = HSlider.new()
		slider.name = "PlacementSlider"
		slider.min_value = -100
		slider.max_value = 100
		slider.step = 1
		slider.value = arena.aim
		slider.custom_minimum_size.y = 44
		slider.editable = not arena.waiting
		slider.value_changed.connect(place_at)
		footer.add_child(slider)
	else:
		var spacer = Control.new()
		spacer.custom_minimum_size.y = 44
		footer.add_child(spacer)
	action_button = button(footer,"DROP" if arena.phase=="build" else "EXTRACT %s"%(str(arena.selected) if arena.selected>0 else "TREASURE"),perform_action,false,92)
	action_button.icon = load("res://assets/icons/drop.svg" if arena.phase=="build" else "res://assets/icons/extract.svg")
	action_button.add_theme_constant_override("h_separation",16)
	action_button.name = "PrimaryAction"
	_update_tutorial_prompt()

func tutorial_step() -> int:
	if not is_instance_valid(arena) or current!=0 or store.data.tutorial_done or arena.phase not in ["build","extract"]:
		return -1
	if arena.phase=="build":
		if arena.placed==0: return 1 if dragged else 0
		return 1 if arena.placed==1 and arena.waiting else -1
	if arena.recovered.size()>0 or arena.selected>0: return 3
	return 2

func _update_tutorial_prompt() -> void:
	var step = tutorial_step()
	if is_instance_valid(coach_message):
		coach_step.text = "%d / 4"%(step+1)
		coach_message.text = ["Slide left or right to place your piece.","Tap Drop. Let the piece settle.","Tap a gold treasure to select it.","Tap Extract. Keep the tower standing."][maxi(0,step)]
		coach_note.visible = step==3 and not arena.waiting
		if arena.waiting:
			coach_message.text = "Settling…" if arena.action_time<8 else "Still moving. Pause → Restore checkpoint or Retry."
		coach_panel.pointer = step in [1,3] and not arena.waiting
		coach_panel.queue_redraw()
	if is_instance_valid(action_button):
		action_button.disabled = arena.waiting or arena.phase not in ["build","extract"] or (arena.phase=="extract" and arena.selected==0) or step==0
	arena.coach_hint = "place" if step==0 else ("select" if step==2 and not arena.waiting else "")
	arena.queue_redraw()

func place_at(x: float) -> void:
	if arena.waiting or arena.phase!="build": return
	var old = arena.aim
	arena.set_aim(x)
	if absf(arena.aim-old)>=1:
		dragged = true
		_update_tutorial_prompt()

func perform_action() -> void:
	if tutorial_step()==0: return
	if arena.phase=="build": arena.drop()
	else: arena.extract()

func skip_tutorial() -> void:
	store.data.tutorial_done = true
	store.write()
	refresh_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if overlay_kind == "settings":
			settings_back()
		elif overlay_kind == "pause":
			resume()
		elif screen == "game" and overlay_kind.is_empty():
			pause_menu()
		elif screen == "sequences":
			home()
		get_viewport().set_input_as_handled()
		return
	if screen != "game" or not overlay_kind.is_empty() or not is_instance_valid(arena):
		return
	var point = Vector2.ZERO
	var is_press = false
	if event is InputEventScreenTouch and event.pressed:
		held_pointer=true
		point = event.position
		is_press = true
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		held_pointer=true
		point = event.position
		is_press = true
	elif event is InputEventScreenDrag and held_pointer:
		place_at(event.position.x-arena.position.x)
	elif event is InputEventMouseMotion and held_pointer and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		place_at(event.position.x-arena.position.x)
	if is_press:
		if arena.phase == "build": place_at(point.x-arena.position.x)
		else: arena.select_at(point)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_LEFT: place_at(arena.aim-4)
		if event.keycode == KEY_RIGHT: place_at(arena.aim+4)
		if event.keycode in [KEY_1,KEY_2,KEY_3]: arena.select_number(event.keycode-KEY_0)
		if event.keycode == KEY_SPACE:
			perform_action()

func modal(title: String, description: String = "") -> VBoxContainer:
	clear_control(overlay)
	overlay = surface()
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var shade = ColorRect.new()
	shade.color = Color(0.01,0.015,0.03,0.77)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)
	var panel = PanelContainer.new()
	panel.name = "ModalPanel"
	panel.modulate.a=0
	panel.mouse_filter=Control.MOUSE_FILTER_STOP
	panel.size.x = minf(640,screen_size.x-64)
	panel.add_theme_stylebox_override("panel",Glass.panel(Color("151720"),24))
	overlay.add_child(panel)
	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation",14)
	col.custom_minimum_size.x=panel.size.x-48
	panel.add_child(col)
	var title_label = text(col,title,32,INK,true)
	title_label.add_theme_font_override("font",preload("res://assets/fonts/salvage-grid.fnt"))
	title_label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if not description.is_empty(): text(col,description,23,MUTED,true)
	_reveal_panel.call_deferred(panel)
	return col

func pause_menu() -> void:
	if not is_instance_valid(arena) or result_pending: return
	_clear_held_inputs()
	get_tree().paused = true
	refresh_hud() # Recreate sliders/buttons to discard native held-pointer state.
	audio.music.stream_paused = true
	audio.stop_effects()
	overlay_kind = "pause"
	var col = modal("PAUSED","Sequence %02d · %s"%[current+1,Content.TITLES[current]])
	button(col,"Resume",resume,true,82)
	button(col,"Retry",func(): start(current),false,76)
	if not store.data.checkpoint.is_empty():
		button(col,"Restore checkpoint",func(): start(int(store.data.checkpoint.sequence),store.data.checkpoint.duplicate(true)),false,72)
		text(col,"Returns to the last settled action.",18,MUTED,true)
	button(col,"Home",home,false,72)
	button(col,"Settings",func(): settings_menu("pause"),false,72)

func resume() -> void:
	_clear_held_inputs()
	refresh_hud()
	clear_control(overlay)
	overlay_kind = ""
	get_tree().paused = false
	audio.music.stream_paused = false

func settings_menu(from_screen: String) -> void:
	_clear_held_inputs()
	settings_return = from_screen
	overlay_kind = "settings"
	var col = modal("SETTINGS")
	for pair in [["Music","music"],["Effects","effects"]]:
		text(col,pair[0],26)
		var slider = HSlider.new()
		slider.custom_minimum_size.y = 64
		slider.min_value = 0
		slider.max_value = 1
		slider.step = 0.05
		slider.value = store.data.settings[pair[1]]
		var key = pair[1]
		slider.value_changed.connect(func(v): store.data.settings[key]=v; audio.settings(store.data.settings))
		slider.drag_ended.connect(func(_changed): store.write())
		col.add_child(slider)
	for pair in [["Haptics","haptics"],["Reduced Motion","reduced_motion"]]:
		var toggle = CheckButton.new()
		toggle.text = pair[0]
		toggle.custom_minimum_size.y = 80
		toggle.button_pressed = store.data.settings[pair[1]]
		var key = pair[1]
		toggle.toggled.connect(func(v):
			store.data.settings[key] = v
			store.write()
			if key=="reduced_motion" and is_instance_valid(menu):
				var hero = menu.find_child("Hero",true,false)
				if hero!=null:
					hero.animate = not v
					if v: hero.elapsed=2.0; hero.queue_redraw()
		)
		col.add_child(toggle)
	text(col,"Reduced Motion keeps the hero static and uses short fades. Tower physics remain visible.",20,MUTED,true)
	text(col,"Rounds resume from a settled checkpoint.",19,MUTED,true)
	text(col,"v%s"%ProjectSettings.get_setting("application/config/version"),18,MUTED,true)
	button(col,"Done",settings_back,true,80)

func settings_back() -> void:
	store.write()
	if settings_return == "pause":
		overlay_kind = "pause"
		pause_menu()
	else:
		home()

func _finished(won: bool, count: int, culprit: int) -> void:
	if result_pending:
		return
	result_pending = true
	var token = round_token
	store.record(current,count,won)
	if won: _feedback("complete")

	# Briefly show the red culprit before the result panel. No camera shake.
	await get_tree().create_timer(0.08 if store.data.settings.reduced_motion else 0.55).timeout
	if screen != "game" or not is_instance_valid(arena) or token != round_token:
		return
	last_result = {"won":won,"count":count,"culprit":culprit}
	_show_result(won,count,culprit)

func _show_result(won: bool, count: int, culprit: int) -> void:
	_clear_held_inputs()
	get_tree().paused = true
	overlay_kind = "results"
	var description = "%d / 3 recovered"%count
	if not won: description += "\nPiece %d touched the loss boundary."%(culprit+1)
	var col = modal("SALVAGE\nCOMPLETE" if won else "TOWER LOST",description)
	var shelf = Hero.new()
	shelf.name = "RecoveryShelf"
	shelf.result_shelf = true
	shelf.recovered = arena.recovered.duplicate()
	shelf.animate = not store.data.settings.reduced_motion
	shelf.custom_minimum_size.y = 180
	col.add_child(shelf)
	if won:
		if current<11: button(col,"Next",func(): commerce.between_rounds(); start(current+1),true,90)
		else: button(col,"Collection complete" if completed()==12 else "Sequences",collection if completed()==12 else sequences_from_results,true,90)
	button(col,"Retry",func(): start(current),not won,84)
	var navigation = HBoxContainer.new()
	navigation.add_theme_constant_override("separation",12)
	col.add_child(navigation)
	button(navigation,"Sequences",sequences_from_results,false,72)
	button(navigation,"Home",home,false,72)

func sequences_from_results() -> void:
	home()
	sequences()

func collection() -> void:
	home()
	var col = modal("COLLECTION\nCOMPLETE","12 / 12 sequences complete")
	overlay_kind = "collection"
	var shelf = Hero.new()
	shelf.result_shelf = true
	shelf.animate = not store.data.settings.reduced_motion
	shelf.custom_minimum_size.y = 180
	col.add_child(shelf)
	button(col,"Replay a sequence",func(): clear_control(overlay); overlay_kind=""; sequences(),true)
	button(col,"Home",home)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if is_instance_valid(arena) and screen=="game" and overlay_kind.is_empty() and not result_pending:
			pause_menu()
		if is_instance_valid(audio):
			audio.music.stream_paused = true
			audio.stop_effects()
		if store.data is Dictionary and not store.data.is_empty(): store.write()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_APPLICATION_RESUMED:
		if is_instance_valid(audio) and overlay_kind not in ["pause","settings"]:
			audio.music.stream_paused = false
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		store.write()
		get_tree().quit()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if screen=="game" and overlay_kind.is_empty(): pause_menu()
		elif overlay_kind=="settings": settings_back()
		elif overlay_kind=="pause": resume()
		elif screen=="sequences": home()

func _demo_capture() -> void:
	var capture_script=load("res://tests/capture_screens.gd").new()
	add_child(capture_script)
	capture_script.run(self)

func wordmark(parent: Node, font_size: int = 52, centered: bool = false) -> Label:
	var label=text(parent,"SALVAGE\nSTACK",font_size,INK,centered)
	label.add_theme_font_override("font",preload("res://assets/fonts/salvage-grid.fnt"))
	label.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	return label

func icon_button(parent: Node, icon: String, accessible_label: String, action: Callable) -> Button:
	var b=button(parent,"",action,false,88)
	b.tooltip_text=accessible_label
	b.custom_minimum_size.x=88
	b.size_flags_horizontal=Control.SIZE_SHRINK_END
	b.icon=load("res://assets/icons/"+icon+".svg")
	return b

func _enter(control: Control) -> void:
	control.modulate.a=0
	var end=control.position
	var reduced=store.data.settings.reduced_motion
	if not reduced: control.position.y+=8
	var tween=control.create_tween().set_parallel(true)
	tween.tween_property(control,"modulate:a",1.0,0.1 if reduced else 0.22)
	if not reduced: tween.tween_property(control,"position",end,0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _reveal_panel(panel) -> void:
	if not is_instance_valid(panel) or panel.is_queued_for_deletion(): return
	for i in range(3):
		await get_tree().process_frame
		if not is_instance_valid(panel) or panel.is_queued_for_deletion(): return
	panel.reset_size()
	panel.size.y=panel.get_combined_minimum_size().y
	panel.position=Vector2((screen_size.x-panel.size.x)/2,clampf((screen_size.y-panel.size.y)/2,top_inset,screen_size.y-bottom_inset-panel.size.y))
	panel.show()
	panel.modulate.a=0
	panel.create_tween().tween_property(panel,"modulate:a",1.0,0.08 if store.data.settings.reduced_motion else 0.16)

func _clear_held_inputs() -> void:
	held_pointer=false
	for action in ["ui_left","ui_right","ui_up","ui_down","ui_accept","ui_select"]: Input.action_release(action)

func _clear_effects() -> void:
	if not is_instance_valid(effects): return
	for child in effects.get_children(): child.queue_free()

func _extracted(spec: Dictionary, at: Vector2, angle: float, number: int) -> void:
	# Collision is already disabled by Arena. This node has no physics children.
	var copy=ExtractionFX.new()
	copy.spec=spec
	copy.position=at
	copy.rotation=angle
	effects.add_child(copy)
	var token=round_token
	await get_tree().process_frame
	if token!=round_token or not is_instance_valid(copy) or copy.is_queued_for_deletion(): return
	var tween=copy.create_tween().set_parallel(true)
	if store.data.settings.reduced_motion:
		tween.tween_property(copy,"modulate:a",0.0,0.12)
	else:
		var target=Vector2(screen_size.x/2,top_inset+180)
		if objective_buttons.size()>=number and is_instance_valid(objective_buttons[number-1]): target=objective_buttons[number-1].get_global_rect().get_center()
		tween.tween_property(copy,"position",target,0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(copy,"rotation",0.0,0.4)
		tween.tween_property(copy,"scale",Vector2.ONE*0.55,0.4)
		tween.tween_property(copy,"modulate:a",0.0,0.15).set_delay(0.27)
	tween.chain().tween_callback(copy.queue_free)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and not event.pressed: held_pointer=false
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed: held_pointer=false
