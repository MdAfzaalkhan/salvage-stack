extends SceneTree
var game: Node
var errors: Array = []
var report: Array = []
func _initialize() -> void:
	run.call_deferred()
func check(ok: bool, msg: String) -> void:
	if not ok:
		errors.append(msg)
		printerr("CHECK FAILED: "+msg)
func frame() -> void:
	for i in range(5): await process_frame
func buttons_in_bounds(control: Node, size: Vector2) -> void:
	for c in control.get_children():
		if c is Button and c.is_visible_in_tree():
			var rect = c.get_global_rect()
			# Scroll list content deliberately extends past its clipped viewport.
			var scrolled = c.get_parent().get_parent() is ScrollContainer
			if not scrolled:
				check(rect.position.x>=-1 and rect.end.x<=size.x+1,"button horizontal bounds: "+c.text)
				check(rect.position.y>=-1 and rect.end.y<=size.y+1,"button vertical bounds: "+c.text)
			check(rect.size.y>=44,"touch target height: "+c.text)
			for state in ["normal","hover","pressed","hover_pressed","focus","disabled"]:
				var key = "font_color" if state=="normal" else "font_"+state+"_color"
				var fg = c.get_theme_color(key).srgb_to_linear().get_luminance()
				var bg_style = c.get_theme_stylebox("normal" if state=="focus" else state)
				var bg_color = bg_style.bg_color if bg_style is StyleBoxFlat else bg_style.get_meta("contrast_background",game.CREAM)
				var bg = bg_color.srgb_to_linear().get_luminance()
				var contrast = (maxf(fg,bg)+0.05)/(minf(fg,bg)+0.05)
				check(contrast>=4.5,"button text contrast "+state+": "+c.text)
		buttons_in_bounds(c,size)
func wait_for_tower() -> void:
	var n = 0
	while game.arena.waiting and n<2400:
		await physics_frame
		n += 1
	check(n<2400,"UI-driven tower settled")
func find_button(node: Node, value: String):
	var label = {"Next shift":"Next","Retry shift":"Retry"}.get(value,value)
	if node is Button and (node.text.to_lower()==label.to_lower() or node.tooltip_text==label): return node
	for child in node.get_children():
		var found = find_button(child,value)
		if found != null: return found
	return null
func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await create_timer(0.5).timeout
	game.store.data.tutorial_done = true
	for size in [Vector2i(720,1280),Vector2i(720,1560),Vector2i(960,1280)]:
		root.size = size
		await frame()
		game.home()
		await frame()
		buttons_in_bounds(game.menu,Vector2(size))
		game.sequences()
		await frame()
		buttons_in_bounds(game.menu,Vector2(size))
		game.start(0)
		await frame()
		buttons_in_bounds(game.hud,Vector2(size))
		check(game.arena.position.y+114<game.hud.get_child(game.hud.get_child_count()-1).position.y,"arena label above footer")
		game.pause_menu()
		await frame()
		check(paused,"pause sets paused tree")
		buttons_in_bounds(game.overlay,Vector2(size))
		game.settings_menu("pause")
		await frame()
		buttons_in_bounds(game.overlay,Vector2(size))
		game.store.data.settings.music=0.0
		game.store.data.settings.effects=0.0
		game.audio.settings(game.store.data.settings)
		check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")),"music mute")
		check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Effects")),"effects mute")
		game.settings_back()
		game.resume()
		check(not paused,"resume clears paused tree")
		game._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
		check(paused,"focus out pauses gameplay")
		check(game.audio.music.stream_paused,"focus out pauses music")
		game.resume()
		game.start(1)
		game.home()
		await frame()
		check(game.arena==null,"home removes arena")
		for voice in game.audio.voices: check(not voice.playing,"home stops effects")
		report.append({"viewport":str(size),"navigation_checked":true})
	root.size = Vector2i(720,1280)
	await frame()
	game.start(0)
	for i in range(8):
		game.arena.set_aim(float(game.arena.sequence.route[i]))
		find_button(game.hud,"Drop").pressed.emit()
		await wait_for_tower()
	check(game.arena.phase=="extract","UI enters extraction")
	for t in [3,1,2]:
		game.arena.select_number(t)
		find_button(game.hud,"Extract %d"%t).pressed.emit()
		await wait_for_tower()
	await create_timer(0.7).timeout
	check(game.overlay_kind=="results","UI reaches real win result")
	check(game.store.data.progress[0].won,"win saves completion")
	buttons_in_bounds(game.overlay,Vector2(720,1280))
	check(find_button(game.overlay,"Next shift")!=null,"next available after win")
	find_button(game.overlay,"Next shift").pressed.emit()
	check(game.current==1 and game.arena.placed==0 and not paused,"next starts fresh sequence")
	game.arena.drop()
	game.arena.bodies[0].position.x = 270
	await wait_for_tower()
	await create_timer(0.7).timeout
	check(game.overlay_kind=="results" and game.arena.phase=="lost","real loss result")
	check(find_button(game.overlay,"Next shift")==null,"no next after failure")
	find_button(game.overlay,"Retry shift").pressed.emit()
	check(game.arena.placed==0 and game.arena.recovered.is_empty(),"retry result resets")
	game.settings_menu("home") if game.screen=="home" else game.pause_menu()
	game.settings_menu("pause")
	game.store.data.settings.reduced_motion = true
	game.settings_back()
	game.home()
	await frame()
	check(not game.menu.get_child(0).get_child(2).animate,"reduced motion disables home animation")
	game.collection()
	await frame()
	buttons_in_bounds(game.overlay,Vector2(720,1280))
	game.home()
	var f = FileAccess.open("res://evidence/ui-verification.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"errors":errors,"layouts":report,"note":"Headless Control bounds checks, not visual or device inspection."},"\t"))
	f.close()
	print("UI CHECKS FINISHED: ",errors.size()," failures")
	game.audio.music.stop()
	game.audio.stop_effects()
	# Let the audio server consume its stop commands before fast headless shutdown.
	await frame()
	OS.delay_msec(150)
	await frame()
	game.free()
	await frame()
	quit(0 if errors.is_empty() else 1)
