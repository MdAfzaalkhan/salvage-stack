extends SceneTree
const Store = preload("res://scripts/store.gd")
var game: Node
var errors: Array = []
var layouts: Array = []
func _initialize() -> void:
	run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		errors.append(message)
		printerr("CHECK FAILED: "+message)
func frame() -> void:
	for i in range(5): await process_frame
func settled() -> void:
	var n = 0
	while game.arena.waiting and n<2400:
		await physics_frame
		n+=1
	check(n<2400,"tower settles")
func touch_place(x: float) -> void:
	var touch = InputEventScreenTouch.new()
	touch.pressed=true
	touch.position=game.arena.global_position+Vector2(x,-160)
	game._unhandled_input(touch)
	var e = InputEventScreenDrag.new()
	e.position = game.arena.global_position+Vector2(x,-160)
	game._unhandled_input(e)
func bounds() -> void:
	var box = game.coach_panel.get_global_rect()
	check(game.action_button.get_global_rect().end.y<=root.size.y-game.bottom_inset,"tutorial action respects bottom inset")
	check(box.end.x<=root.size.x and box.end.y<game.action_button.get_global_rect().position.y,"prompt bounds and action separation")
	check(box.position.y>game.arena.position.y+114,"prompt stays below arena loss label")
	var message = game.coach_message.get_global_rect()
	check(message.end.y<=box.end.y-5,"prompt text fits card vertically")
	check(message.end.x<=box.end.x,"prompt text fits horizontally")
	if game.coach_note.visible:
		check(game.coach_note.get_global_rect().end.y<=box.end.y-5,"extraction note fits card")
func run() -> void:
	# Exercise an actual 0.1.0 envelope without the new optional field.
	var store = Store.new()
	store.path = "res://evidence/tutorial-migration-save.json"
	var old = store.defaults()
	old.erase("tutorial_done")
	old.last = 2
	old.progress[1].best = 2
	var payload = JSON.stringify(old)
	var file = FileAccess.open(store.path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"version":1,"payload":payload,"sha256":payload.sha256_text()}))
	file.close()
	store.load_save()
	check(store.data.last==2 and store.data.progress[1].best==2,"old progress preserved")
	check(store.data.tutorial_done==false,"old save receives tutorial default")
	check(store.write(),"migrated save can be written")
	game=load("res://main.tscn").instantiate()
	root.add_child(game)
	await create_timer(0.5).timeout
	game.store.data=game.store.defaults()
	for size in [Vector2i(720,1280),Vector2i(720,1560),Vector2i(960,1280)]:
		root.size=size
		await frame()
		game.store.data.tutorial_done=false
		game.start(0)
		await frame()
		check(game.tutorial_step()==0,"start at place prompt")
		bounds()
		check(game.action_button.disabled,"place action required before tutorial Drop")
		game.perform_action()
		check(game.arena.placed==0,"keyboard cannot skip place prompt")
		var slider = game.hud.find_child("PlacementSlider",true,false)
		touch_place(28)
		check(game.tutorial_step()==1 and not game.action_button.disabled,"touch advances placement prompt")
		check(slider==game.hud.find_child("PlacementSlider",true,false),"slider survives first gesture")
		touch_place(0)
		await frame()
		bounds()
		game.action_button.pressed.emit()
		game.perform_action()
		check(game.arena.placed==1,"rapid duplicate tutorial Drop blocked")
		check(game.tutorial_step()==1 and game.arena.waiting,"drop prompt waits for settling")
		await settled()
		check(game.tutorial_step()==-1 and game.coach_panel==null,"compact build guidance between tutorial actions")
		for i in range(1,8):
			game.place_at(float(game.arena.sequence.route[i]))
			game.action_button.pressed.emit()
			await settled()
		await frame()
		check(game.tutorial_step()==2,"extraction starts at selection prompt")
		bounds()
		check(game.action_button.disabled,"Extract needs selection")
		var cp = game.arena.snapshot()
		# Any treasure may be selected. Number 3 is deliberately used first.
		var target: Node
		for b in game.arena.bodies:
			if int(b.spec.treasure)==3: target=b
		var tap=InputEventScreenTouch.new()
		tap.pressed=true
		tap.position=target.global_position
		game._unhandled_input(tap)
		await frame()
		check(game.tutorial_step()==3 and game.arena.selected==3,"tap any treasure advances select")
		check(game.action_button.text=="EXTRACT 3" and game.coach_note.visible,"selected identity and unordered hint")
		bounds()
		game.pause_menu()
		check(paused,"tutorial pauses physics")
		game.resume()
		check(game.tutorial_step()==3,"resume retains prompt progress")
		game.action_button.pressed.emit()
		game.perform_action()
		check(game.arena.recovered.size()==1,"duplicate extraction blocked")
		check(not game.store.data.tutorial_done,"completion waits for actual settling")
		await settled()
		await frame()
		check(game.store.data.tutorial_done and game.tutorial_step()==-1,"first safe extraction completes tutorial")
		var loaded=Store.new()
		loaded.path=game.store.path
		loaded.load_save()
		check(loaded.data.tutorial_done,"tutorial completion survives save reload")
		game.start(0)
		check(game.tutorial_step()==-1 and not game.action_button.disabled,"retry does not repeat completed tutorial")
		# An extraction followed by collapse must not count as tutorial success.
		game.store.data.tutorial_done=false
		game.start(0,cp)
		await settled()
		game.arena.select_number(1)
		game.perform_action()
		game.arena.bodies[0].position=Vector2(270,80)
		await settled()
		check(game.arena.phase=="lost" and not game.store.data.tutorial_done,"collapse does not complete tutorial")
		game.start(0)
		game.hud.find_child("SkipTutorial",true,false).pressed.emit()
		check(game.store.data.tutorial_done and not game.action_button.disabled,"Skip restores ordinary controls")
		loaded.load_save()
		check(loaded.data.tutorial_done,"Skip survives save reload")
		game.home()
		layouts.append({"viewport":str(size),"touch_prompts_checked":4,"saved_completion":true,"skip":true})
	var out=FileAccess.open("res://evidence/tutorial-verification.json",FileAccess.WRITE)
	out.store_string(JSON.stringify({"errors":errors,"layouts":layouts,"old_save_migration":true,"note":"Headless actual Control and physics/input checks; no rendered screenshot/device claim."},"\t"))
	out.close()
	print("TUTORIAL CHECKS FINISHED: ",errors.size()," failures")
	game.audio.music.stop()
	game.audio.stop_effects()
	await frame()
	OS.delay_msec(150)
	await frame()
	game.free()
	await frame()
	quit(0 if errors.is_empty() else 1)
