extends Node
# Run graphically with --capture-demo and an isolated SALVAGE_TEST_SAVE_PATH.
# Captures actual Godot frames; no mockups or manufactured success states.
var game: Node
func frame() -> void:
	for i in range(4): await get_tree().process_frame
func capture(name: String) -> void:
	await frame()
	if DisplayServer.get_name()=="headless":
		printerr("Rendered captures require a graphical Godot session.")
		return
	await RenderingServer.frame_post_draw
	game.get_viewport().get_texture().get_image().save_png("res://evidence/"+name+".png")
func settled() -> void:
	while game.arena.waiting: await get_tree().physics_frame
func run(main: Node) -> void:
	game=main
	await get_tree().create_timer(1.3).timeout
	await capture("01-home")
	game.sequences()
	await get_tree().create_timer(0.3).timeout
	await capture("02-sequences")
	game.store.data.tutorial_done=false
	game.start(0)
	await frame()
	await capture("03-tutorial")
	game.place_at(30)
	game.place_at(0)
	for i in range(8):
		game.place_at(float(game.arena.sequence.route[i]))
		if i==4: await capture("04-build")
		game.perform_action()
		await settled()
	game.arena.select_number(2)
	await capture("05-extract-selected")
	game.pause_menu()
	await get_tree().create_timer(0.3).timeout
	await capture("06-pause")
	game.settings_menu("pause")
	await get_tree().create_timer(0.3).timeout
	await capture("07-settings")
	game.settings_back()
	game.resume()
	for t in [2,1,3]:
		game.arena.select_number(t)
		game.perform_action()
		await settled()
	await get_tree().create_timer(1.1).timeout
	await capture("08-success")
	game.start(1)
	for i in range(8):
		game.place_at(0)
		game.perform_action()
		await settled()
		if game.arena.phase=="lost": break
	await get_tree().create_timer(0.9).timeout
	await capture("09-failure")
	game.audio.music.stop()
	game.audio.stop_effects()
	await frame()
	get_tree().quit()
