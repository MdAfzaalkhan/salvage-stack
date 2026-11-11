extends SceneTree
const Arena = preload("res://scripts/arena.gd")
const Content = preload("res://scripts/content.gd")
const Store = preload("res://scripts/store.gd")
var arena: Node
var errors: Array = []
var records: Array = []
var restoration_records: Array = []

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, message: String) -> void:
	if not value:
		errors.append(message)
		printerr("CHECK FAILED: "+message)

func settle() -> bool:
	var frames = 0
	while arena.waiting and frames < 2400:
		await physics_frame
		frames += 1
	return not arena.waiting and arena.phase != "lost"

func route(index: int, order: Array, strategy: String = "authored") -> Dictionary:
	arena.begin(index)
	var seq = Content.sequence(index)
	var snapshots: Array = []
	for i in range(8):
		arena.set_aim(float(seq.route[i]) if strategy=="authored" else 0.0)
		check(arena.drop(),"drop accepted %s/%d"%[strategy,i])
		check(not arena.drop(),"duplicate drop blocked")
		if not await settle():
			return {"sequence":index+1,"order":order,"strategy":strategy,"outcome":"build loss" if arena.phase=="lost" else "timeout","culprit":arena.lost_id+1,"placed":arena.placed}
		snapshots.append(arena.snapshot())
	for t in order:
		arena.select_number(t)
		check(arena.extract(),"extract accepted")
		check(not arena.extract(),"duplicate extract blocked")
		if not await settle():
			return {"sequence":index+1,"order":order,"strategy":strategy,"outcome":"extraction loss" if arena.phase=="lost" else "timeout","culprit":arena.lost_id+1,"recovered":arena.recovered.size()}
	return {"sequence":index+1,"order":order,"strategy":strategy,"outcome":arena.phase,"max_settling_s":snappedf(arena.max_settling,0.001),"placements_x":seq.route if strategy=="authored" else [],"settled_constructions":snapshots}

func run() -> void:
	arena = Arena.new()
	root.add_child(arena)
	var orders = [[1,2,3],[1,3,2],[2,1,3],[2,3,1],[3,1,2],[3,2,1]]
	for index in range(12):
		for order in orders:
			var result = await route(index,order)
			records.append(result)
			check(result.outcome == "won","authored route %d %s: %s"%[index+1,order,result.outcome])
		print("SEQUENCE ",index+1," complete")
	# Repeated constructions are samples of this engine/platform, not cross-device proof.
	for index in [0,5,11]:
		for repeat in range(3):
			var result = await route(index,[3,2,1])
			result["repeat"] = repeat+1
			records.append(result)
			check(result.outcome=="won","repeat route")
	# Dominant strategy probe: same all-centred placement on every sequence.
	for index in range(12):
		records.append(await route(index,[3,2,1],"all centred"))
	# Check each settled build/extraction checkpoint of every authored route.
	for index in range(12):
		var source = records[index*6]
		var checkpoints = source.settled_constructions.duplicate(true)
		arena.begin(index,checkpoints[7])
		check(await settle(),"restore complete build")
		for t in [1,2]:
			arena.select_number(t)
			arena.extract()
			check(await settle(),"prepare extraction checkpoint")
			checkpoints.append(arena.snapshot())
		for cp_restore in checkpoints:
			arena.begin(index,cp_restore)
			var good = await settle()
			if good:
				for next in range(int(cp_restore.placed),8):
					arena.set_aim(float(arena.sequence.route[next]))
					arena.drop()
					if not await settle():
						good = false
						break
			if good:
				for t in [3,2,1]:
					if arena.recovered.has(t): continue
					arena.select_number(t)
					arena.extract()
					if not await settle():
						good = false
						break
			check(good and arena.phase=="won","checkpoint suffix wins: %d, placed %d, recovered %s"%[index+1,cp_restore.placed,cp_restore.recovered])
			restoration_records.append({"sequence":index+1,"placed":cp_restore.placed,"recovered":cp_restore.recovered,"outcome":arena.phase,"good":good})
	# Real geometry-based failure: base dropped beyond support centre.
	arena.begin(0)
	arena.set_aim(0)
	arena.drop()
	# Deliberately move a live body outside the supporting platform to test the loss boundary.
	arena.bodies[0].position.x = 260
	await settle()
	check(arena.phase=="lost","off-foundation drop loses")
	check(arena.lost_id==0,"loss identifies physical piece")
	# Restore an actual settled checkpoint and complete the remaining actions.
	arena.begin(4)
	for i in range(4):
		arena.set_aim(float(arena.sequence.route[i]))
		arena.drop()
		await settle()
	var cp = arena.snapshot()
	var save = Store.new()
	save.path = "res://evidence/test-save.json"
	save.data = save.defaults()
	save.data.checkpoint = cp
	check(save.write(),"checkpoint written")
	save.data.last = 4
	check(save.write(),"second atomic generation")
	var loaded = Store.new()
	loaded.path = save.path
	loaded.load_save()
	check(loaded.data.checkpoint.placed==4,"checkpoint read")
	var f = FileAccess.open(save.path,FileAccess.WRITE)
	f.store_string("damaged")
	f.close()
	loaded.load_save()
	check(loaded.restored_backup,"damaged main recovered backup")
	check(loaded.data.checkpoint.placed==4,"backup retains round")
	var invalid = cp.duplicate(true)
	invalid.bodies[0].x = "bad"
	check(not save.valid_checkpoint(invalid),"bad checkpoint rejected")
	arena.begin(4,cp)
	check(await settle(),"restored contacts settle")
	for i in range(4,8):
		arena.set_aim(float(arena.sequence.route[i]))
		arena.drop()
		check(await settle(),"restored build continues")
	for t in [2,1,3]:
		arena.select_number(t)
		arena.extract()
		check(await settle(),"restored extraction continues")
	check(arena.phase=="won","restored round wins")
	# Pausing must stop a falling physics body and settling clock.
	arena.begin(0)
	arena.drop()
	await physics_frame
	var before = arena.bodies[0].position
	var elapsed = arena.action_time
	paused = true
	for i in range(60): await process_frame
	check(arena.bodies[0].position==before,"pause stops physics")
	check(arena.action_time==elapsed,"pause stops attempt clock")
	paused = false
	await settle()
	arena.begin(0)
	check(arena.placed==0 and arena.recovered.is_empty() and arena.bodies.is_empty(),"retry clears full round")
	var out = FileAccess.open("res://evidence/physics-verification.json",FileAccess.WRITE)
	out.store_string(JSON.stringify({"engine":Engine.get_version_info(),"platform":OS.get_name(),"checks_failed":errors,"runs":records,"checkpoint_restorations":restoration_records},"\t"))
	out.close()
	print("VERIFICATION FINISHED: ",errors.size()," failures; ",records.size()," sampled routes")
	arena.free()
	quit(0 if errors.is_empty() else 1)
