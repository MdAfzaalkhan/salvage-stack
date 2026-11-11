extends SceneTree
const Glass=preload("res://scripts/glass.gd")
var game: Node
var failures: Array=[]
var records: Array=[]
func _initialize() -> void:
	run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok:
		failures.append(message)
		printerr("CHECK FAILED: "+message)
func frame() -> void:
	for i in range(6): await process_frame
func settle() -> void:
	var n=0
	while game.arena.waiting and n<2400:
		await physics_frame
		n+=1
	check(n<2400,"tower settles")
func panel_bounds() -> void:
	var panel=game.overlay.find_child("ModalPanel",true,false)
	check(panel.visible,"modal reveals after placement")
	var r=panel.get_global_rect()
	check(absf(r.get_center().x-root.size.x/2.0)<2,"modal horizontally centred")
	check(r.position.y>=game.top_inset-1 and r.end.y<=root.size.y-game.bottom_inset+1,"modal within safe layout: %s in %s safe %s/%s"%[r,root.size,game.top_inset,game.bottom_inset])
func run() -> void:
	game=load("res://main.tscn").instantiate()
	root.add_child(game)
	await create_timer(0.6).timeout
	check(game.theme.resource_path=="res://assets/dark_theme.tres","one shared dark theme")
	var font=load("res://assets/fonts/salvage-grid.fnt")
	check(font.has_char(65) and font.has_char(90) and font.has_char(48),"original pixel font glyphs")
	check(font.get_string_size("SALVAGE",HORIZONTAL_ALIGNMENT_LEFT,-1,66).x<624,"wordmark fits")
	game.store.data.tutorial_done=true
	for size in [Vector2i(720,1280),Vector2i(720,1560),Vector2i(960,1280)]:
		root.size=size
		await frame()
		game.home()
		await frame()
		var hero=game.menu.find_child("Hero",true,false)
		check(hero!=null and hero.get_children().is_empty(),"Home hero has no physics bodies")
		game.sequences()
		await frame()
		var grid=game.menu.find_child("SequenceGrid",true,false)
		check(grid.get_child_count()==12,"sequence count preserved")
		for i in range(12):
			check(grid.get_child(i).best==int(game.store.data.progress[i].best),"card uses saved recovery")
		var scroll=game.menu.find_child("SequenceScroll",true,false)
		scroll.custom_minimum_size.y=340
		scroll.get_parent().size.y=520
		await frame()
		var card=grid.get_child(0)
		var touch=InputEventScreenTouch.new()
		touch.pressed=true
		touch.position=Vector2(80,90)
		card._gui_input(touch)
		var drag=InputEventScreenDrag.new()
		drag.position=Vector2(80,-150)
		card._gui_input(drag)
		touch.pressed=false
		card._gui_input(touch)
		check(game.screen=="sequences","card drag does not launch a sequence")
		check(scroll.scroll_vertical>0,"card drag scrolls")
		scroll.scroll_vertical=0
		await frame()
		touch.pressed=true
		card._gui_input(touch)
		touch.pressed=false
		card._gui_input(touch)
		check(game.screen=="game" and game.current==0,"card tap selects sequence")
		game.held_pointer=true
		game.pause_menu()
		check(not game.held_pointer,"Pause clears held input")
		var panel=game.overlay.find_child("ModalPanel",true,false)
		check(panel.modulate.a==0,"overlay transparent until laid out")
		await frame()
		panel_bounds()
		game.settings_menu("pause")
		await frame()
		panel_bounds()
		game.settings_back()
		game.resume()
		check(not game.held_pointer,"resume requires a fresh input")
		# Rapid overlay replacement must not reveal stale/freed panels.
		game.pause_menu()
		game.settings_menu("pause")
		game.settings_back()
		game.resume()
		await frame()
		game.home()
		records.append({"viewport":str(size),"grid_scroll_and_tap":true,"modal_placement":true})
	# Real build and immediate logical extraction, with separate decorative copy.
	game.start(0)
	for i in range(8):
		game.place_at(float(game.arena.sequence.route[i]))
		game.perform_action()
		await settle()
	game.arena.select_number(2)
	var selected: Node
	for b in game.arena.bodies:
		if int(b.spec.treasure)==2: selected=b
	game.perform_action()
	check(selected.collision_layer==0 and selected.collision_mask==0,"collision removal precedes flight effect")
	check(game.arena.recovered==[2] and game.arena.bodies.size()==7,"extraction updates gameplay once")
	check(game.effects.get_child_count()==1,"non-colliding extraction copy created")
	for node in game.effects.get_children(): check(not node is CollisionObject2D and node.get_child_count()==0,"visual effect has no colliders")
	for b in game.arena.bodies: check(not b.freeze,"real tower never frozen for effect")
	await settle()
	check(game.arena.recovered==[2],"visual completion does not duplicate recovery")
	for t in [3,1]:
		game.arena.select_number(t)
		game.perform_action()
		await settle()
	await create_timer(0.9).timeout
	check(game.arena.phase=="won" and game.store.data.progress[0].won,"success only after physics result")
	panel_bounds()
	check(game.overlay.find_child("RecoveryShelf",true,false).recovered.size()==3,"success shelf shows actual recoveries")
	game.start(1)
	for i in range(8):
		game.place_at(0)
		game.perform_action()
		await settle()
		if game.arena.phase=="lost": break
	await create_timer(0.8).timeout
	check(game.arena.phase=="lost" and game.arena.lost_id>=0,"sample bad construction physically fails")
	check(game.arena.failure_contact.y==74,"failure marker uses existing loss plane")
	check(game.last_result.culprit==game.arena.lost_id,"result matches actual offending piece")
	check(game.overlay.find_child("RecoveryShelf",true,false).recovered==game.arena.recovered,"failure shelf uses actual recovered identities")
	game.home()
	game.store.data.settings.reduced_motion=true
	game.home()
	await frame()
	check(not game.menu.find_child("Hero",true,false).animate,"Reduced Motion gives static hero")
	Glass.simple=true
	game.home()
	await frame()
	check(Glass.simple,"simpler rendering path can be enabled")
	var out=FileAccess.open("res://evidence/glass-verification.json",FileAccess.WRITE)
	out.store_string(JSON.stringify({"failures":failures,"layouts":records,"extraction_logic_unchanged":true,"scope":"Headless Godot node/input/physics checks; no rendered screenshots or physical-device claim."},"\t"))
	out.close()
	print("GLASS CHECKS FINISHED: ",failures.size()," failures")
	game.audio.music.stop()
	game.audio.stop_effects()
	await frame()
	OS.delay_msec(150)
	await frame()
	game.free()
	await frame()
	quit(0 if failures.is_empty() else 1)
