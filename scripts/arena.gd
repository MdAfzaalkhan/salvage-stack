extends Node2D
const Content = preload("res://scripts/content.gd")
const Piece = preload("res://scripts/piece.gd")
signal changed
signal finished(won: bool, recovered: int, culprit: int)
signal checkpoint(data: Dictionary)
signal sound(kind: String)
signal extracted(spec: Dictionary, at: Vector2, angle: float, number: int)
const Glass = preload("res://scripts/glass.gd")
var failure_contact = Vector2.ZERO
var sequence: Dictionary
var bodies: Array = []
var ghost: RigidBody2D
var phase = "build"
var placed = 0
var recovered: Array = []
var selected = 0
var waiting = false
var stable_for = 0.0
var action_time = 0.0
var quiet_linear = 4.0
var quiet_angular = deg_to_rad(3.0)
var settle_duration = 0.6
var aim = 0.0
var lost_id = -1
var loss_area: Area2D
var active = true
var action_serial = 0
var max_settling = 0.0
var _notify_long_wait = false
var coach_hint = ""

func _ready() -> void:
	var foundation = StaticBody2D.new()
	var collider = CollisionShape2D.new()
	var rectangle = RectangleShape2D.new()
	rectangle.size = Vector2(200,34)
	collider.shape = rectangle
	collider.position = Vector2(0,17)
	foundation.add_child(collider)
	var pedestal = CollisionShape2D.new()
	var foot = RectangleShape2D.new()
	foot.size = Vector2(152,40)
	pedestal.shape = foot
	pedestal.position = Vector2(0,54)
	foundation.add_child(pedestal)
	add_child(foundation)
	loss_area = Area2D.new()
	loss_area.collision_layer = 0
	loss_area.collision_mask = 1
	# Catch tray fills the whole world below the visible red/striped top edge.
	var loss = CollisionShape2D.new()
	var zone = RectangleShape2D.new()
	zone.size = Vector2(20000,10000)
	loss.shape = zone
	loss.position = Vector2(0,5074)
	loss_area.add_child(loss)
	loss_area.body_entered.connect(_loss)
	add_child(loss_area)

func begin(index: int, restore: Dictionary = {}) -> void:
	action_serial += 1
	for body in bodies:
		body.free()
	bodies.clear()
	if is_instance_valid(ghost):
		ghost.free()
	ghost = null
	sequence = Content.sequence(index)
	placed = 0
	recovered = []
	phase = "build"
	selected = 0
	waiting = false
	stable_for = 0
	action_time = 0
	lost_id = -1
	failure_contact = Vector2.ZERO
	max_settling = 0.0
	active = true
	aim = 0
	if not restore.is_empty():
		placed = int(restore.placed)
		recovered = restore.recovered.duplicate()
		phase = str(restore.phase)
		for saved in restore.bodies:
			_make(int(saved.id),Vector2(float(saved.x),float(saved.y)),float(saved.r),Vector2(float(saved.get("vx",0)),float(saved.get("vy",0))),float(saved.get("av",0)))
		# Restored contacts must settle again; never freeze them.
		waiting = true
	else:
		show_preview()
	changed.emit()
	queue_redraw()

func _make(id: int, at: Vector2, angle: float = 0.0, velocity: Vector2 = Vector2.ZERO, spin: float = 0.0) -> RigidBody2D:
	var b = Piece.new()
	b.setup(sequence.pieces[id],id)
	# Establish transforms before entering the physics world: no overlap at origin.
	b.position = at
	b.rotation = angle
	b.linear_velocity = velocity
	b.angular_velocity = spin
	b.impact.connect(func(speed): sound.emit("heavy" if speed>260 else "impact"))
	add_child(b)
	bodies.append(b)
	return b

func top_y() -> float:
	var top = 0.0
	for b in bodies:
		for poly in b.spec.polys:
			for p in poly:
				top = minf(top,(b.transform*p).y)
	return top

func spawn_y(id: int) -> float:
	return minf(-130.0, top_y()-float(sequence.pieces[id].h)/2-100)

func show_preview() -> void:
	if is_instance_valid(ghost):
		ghost.queue_free()
	ghost = null
	if phase == "build" and placed < 8 and not waiting:
		ghost = Piece.new()
		ghost.setup(sequence.pieces[placed],placed,true)
		add_child(ghost)
		ghost.position = Vector2(aim,spawn_y(placed))
	queue_redraw()

func set_aim(x: float) -> void:
	if waiting or phase != "build":
		return
	# Every piece can be centred anywhere over the foundation; overhang is legal.
	aim = clampf(x,-100,100)
	if is_instance_valid(ghost):
		ghost.position.x = aim
	queue_redraw()

func drop() -> bool:
	if not active or phase != "build" or waiting or placed >= 8:
		return false
	waiting = true # Guard synchronously, before any signal or deferred physics work.
	stable_for = 0
	action_time = 0
	_notify_long_wait = false
	var y = spawn_y(placed)
	if is_instance_valid(ghost):
		ghost.queue_free()
	ghost = null
	_make(placed,Vector2(aim,y))
	placed += 1
	sound.emit("drop")
	changed.emit()
	return true

func select_at(p: Vector2) -> void:
	if phase != "extract" or waiting or not active:
		return
	for b in bodies:
		if b.spec.treasure > 0 and b.contains_point(p):
			selected = int(b.spec.treasure)
			for other in bodies:
				other.selected = other == b
				other.queue_redraw()
			sound.emit("select")
			changed.emit()
			return

func select_number(number: int) -> void:
	for b in bodies:
		if int(b.spec.treasure) == number:
			select_at(b.global_position)
			return

func extract() -> bool:
	if not active or phase != "extract" or waiting or selected == 0:
		return false
	waiting = true
	stable_for = 0
	action_time = 0
	_notify_long_wait = false
	for b in bodies.duplicate():
		if int(b.spec.treasure) == selected:
			recovered.append(selected)
			bodies.erase(b)
			# Disable collision immediately. Decorative feedback never gets a body.
			b.collision_layer = 0
			b.collision_mask = 0
			extracted.emit(b.spec,b.global_position,b.rotation,int(b.spec.treasure))
			b.queue_free()
	for b in bodies:
		b.sleeping = false
		b.selected = false
		b.queue_redraw()
	selected = 0
	sound.emit("extract")
	changed.emit()
	return true

func _physics_process(delta: float) -> void:
	if not active or phase == "lost" or phase == "won":
		return
	# Check the same polygons used to draw the piece. Also catches tunnelling.
	for b in bodies:
		for poly in b.spec.polys:
			for p in poly:
				if (b.transform*p).y >= 74.0:
					_loss(b)
					return
	if not waiting:
		return
	action_time += delta
	var quiet = true
	for b in bodies:
		if b.linear_velocity.length() > quiet_linear or absf(b.angular_velocity) > quiet_angular:
			quiet = false
	stable_for = stable_for+delta if quiet else 0.0
	if action_time > 8.0 and not _notify_long_wait:
		_notify_long_wait = true
		changed.emit()
	if stable_for >= settle_duration:
		max_settling = maxf(max_settling,action_time)
		waiting = false
		if placed == 8 and phase == "build":
			phase = "extract"
			sound.emit("recover")
		if phase=="extract" and recovered.size()>0 and recovered.size()<3:
			sound.emit("recover")
		if recovered.size() == 3:
			phase = "won"
			active = false
			finished.emit(true,3,-1)
		else:
			checkpoint.emit(snapshot())
			show_preview()
		changed.emit()

func _loss(body: Node) -> void:
	if not active or not bodies.has(body) or phase in ["lost","won"]:
		return
	lost_id = body.identity
	var deepest = Vector2(body.position.x,-INF)
	for poly in body.spec.polys:
		for point in poly:
			var actual = body.transform*point
			if actual.y>deepest.y: deepest=actual
	failure_contact=Vector2(deepest.x,74)
	body.failed = true
	body.queue_redraw()
	phase = "lost"
	active = false
	waiting = false
	if is_instance_valid(ghost):
		ghost.queue_free()
	ghost = null
	sound.emit("fail")
	finished.emit(false,recovered.size(),lost_id)
	changed.emit()
	queue_redraw()

func snapshot() -> Dictionary:
	var data = {"sequence":sequence.id,"placed":placed,"phase":phase,"recovered":recovered.duplicate(),"bodies":[]}
	for b in bodies:
		data.bodies.append({"id":b.identity,"x":b.position.x,"y":b.position.y,"r":b.rotation,"vx":b.linear_velocity.x,"vy":b.linear_velocity.y,"av":b.angular_velocity})
	return data

func _draw() -> void:
	var foundation_spec = {"kind":"foundation","w":200.0,"h":74.0,"gap":0.0,"offset":0.0,"surface":1.0,"treasure":0}
	Glass.piece(self,foundation_spec,Vector2(0,37))
	for n in range(3): Glass.reflection(self,Vector2((n-1)*58,12),28,Glass.accent(n+1),0.3)
	# Markings are beneath the unchanged physical loss plane y=74.
	draw_line(Vector2(-355,74),Vector2(355,74),Color(1,0.737,0.239,0.25),0.7,true)
	for x in range(-180,180,13):
		draw_line(Vector2(x,83),Vector2(x+6,77),Color(1,0.737,0.239,0.55),1,true)
	if lost_id>=0:
		draw_arc(failure_contact,10,0,TAU,32,Color("ff796c"),2,true)
		draw_line(failure_contact+Vector2(0,-19),failure_contact+Vector2(0,-10),Color("ff796c"),2,true)
	if coach_hint=="select":
		for b in bodies:
			if int(b.spec.treasure)==2:
				draw_arc(b.position,32,0,TAU,48,Color(0.94,0.3,0.66,0.4),1.5,true)
	if is_instance_valid(ghost):
		if coach_hint=="place":
			var c=ghost.position+Vector2(0,-float(ghost.spec.h)/2-24)
			draw_line(c+Vector2(-60,0),c+Vector2(60,0),Glass.AMBER,2,true)
			for sign_x in [-1,1]:
				var end=c+Vector2(60*sign_x,0)
				draw_line(end,end+Vector2(-10*sign_x,-6),Glass.AMBER,2,true)
				draw_line(end,end+Vector2(-10*sign_x,6),Glass.AMBER,2,true)
		var gx=ghost.position.x
		draw_dashed_line(Vector2(gx,ghost.position.y+ghost.spec.h/2+10),Vector2(gx,-6),Color(0.65,0.71,0.84,0.22),1,8,true)
