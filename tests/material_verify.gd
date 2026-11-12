extends SceneTree
const Glass=preload("res://scripts/glass.gd")
const Content=preload("res://scripts/content.gd")
var errors: Array=[]
var game: Node
var rows: Array=[]
func _initialize() -> void: run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok: errors.append(message);printerr("CHECK FAILED: "+message)
func frame() -> void:
	for i in range(5): await process_frame
func settle() -> void:
	var steps=0
	while game.arena.waiting and steps<2400:
		await physics_frame
		steps+=1
	check(steps<2400,"settles")
func run() -> void:
	Glass.load_materials()
	var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/materials/shapes.json"))
	var samples=0
	for entry in manifest:
		var bitmap=(Glass.materials[entry.key] as Texture2D).get_image()
		check(bitmap.get_size()==Vector2i(roundi(entry.w*3),roundi(entry.h*3)),"three texels per unit: "+entry.key)
		for y in range(0,bitmap.get_height(),3):
			for x in range(0,bitmap.get_width(),3):
				var point=Vector2((x+.5)/3-entry.w/2,(y+.5)/3-entry.h/2)
				var inside=false
				for contour in Glass.contours[entry.key]:
					inside=inside or Geometry2D.is_point_in_polygon(point,contour)
				check((bitmap.get_pixel(x,y).a>0)==inside,"alpha matches exact contour: "+entry.key)
				samples+=1
	for n in range(12):
		for spec in Content.sequence(n).pieces: check(Glass.materials.has(Glass.material_key(spec)),"authored shape has texture")
	game=load("res://main.tscn").instantiate()
	root.add_child(game)
	await create_timer(.6).timeout
	game.store.data.tutorial_done=true
	for size in [Vector2i(720,1280),Vector2i(720,1560),Vector2i(960,1280)]:
		root.size=size
		await frame()
		for sequence in range(12):
			game.start(sequence)
			await frame()
			var build_zoom=game.world_zoom
			for i in range(8):
				game.place_at(float(game.arena.sequence.route[i]))
				await frame()
				var ghost=game.arena.ghost
				if is_instance_valid(ghost):
					var ghost_top=(root.canvas_transform*(ghost.global_position-Vector2(0,float(ghost.spec.h)/2))).y
					check(ghost_top>=game.top_inset+180,"highest preview clears compact header")
				game.perform_action()
				await settle()
				if i<7: check(is_equal_approx(build_zoom,game.world_zoom),"no per-drop zoom on authored route")
			check(game.arena.phase=="extract","eight actual placements reach extraction")
			await frame()
			for body in game.arena.bodies:
				for poly in body.spec.polys:
					for vertex in poly:
						var screen_point=root.canvas_transform*(body.global_transform*vertex)
						check(screen_point.y>=game.top_inset+180 and screen_point.y<game.footer_top,"full tower fits arena")
			var body=game.arena.bodies[1]
			var position_before=body.position
			var velocity_before=body.linear_velocity
			game._frame_world(game.framing_top,game.footer_top-14)
			check(body.position==position_before and body.linear_velocity==velocity_before,"framing does not mutate physics")
			var touch=InputEventScreenTouch.new()
			touch.pressed=true
			touch.position=root.canvas_transform*body.global_position
			game._unhandled_input(touch)
			check(game.arena.selected==int(body.spec.treasure),"transformed touch selects actual treasure")
			rows.append({"viewport":str(size),"sequence":sequence+1,"build_zoom":build_zoom,"extract_zoom":game.world_zoom})
	game.home()
	check(root.canvas_transform==Transform2D.IDENTITY,"Home resets world presentation")
	game.audio.music.stop();game.audio.stop_effects()
	var out=FileAccess.open("res://evidence/material-verification.json",FileAccess.WRITE)
	out.store_string(JSON.stringify({"failures":errors,"textures":manifest.size(),"alpha_samples":samples,"layouts":rows,"note":"Headless geometry, image-alpha and Control checks, not graphical or device inspection."},"\t"))
	out.close()
	print("MATERIAL CHECKS FINISHED: ",errors.size()," failures; ",samples," alpha samples; ",rows.size()," tower layouts")
	game.home()
	await frame()
	OS.delay_msec(150) # Allow the real audio thread to consume stop commands.
	await frame()
	game.free()
	await frame()
	Glass.materials.clear()
	Glass.contours.clear()
	quit(0 if errors.is_empty() else 1)
