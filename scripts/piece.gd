extends RigidBody2D
signal impact(speed: float)
var spec: Dictionary
var identity: int = 0
var selected = false
var failed = false
var preview = false
var last_impact = -1000
var velocity_before = Vector2.ZERO

func setup(data: Dictionary, id: int, ghost: bool = false) -> void:
	spec = data
	identity = id
	preview = ghost
	var total_area = 0.0
	for poly in spec.polys:
		var collision = CollisionPolygon2D.new()
		collision.polygon = poly
		add_child(collision)
		var area = 0.0
		for k in range(poly.size()):
			area += poly[k].cross(poly[(k+1)%poly.size()])
		total_area += absf(area)/2
	mass = maxf(0.3,total_area/5000.0)
	var material = PhysicsMaterial.new()
	material.friction = 0.72
	material.bounce = 0.015
	physics_material_override = material
	linear_damp = 0.35
	angular_damp = 0.6
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	contact_monitor = true
	max_contacts_reported = 8
	collision_layer = 0 if ghost else 1
	collision_mask = 0 if ghost else 1
	freeze = ghost
	body_entered.connect(_contact)

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	velocity_before = state.linear_velocity

func _contact(_body: Node) -> void:
	if preview:
		return
	var now = Time.get_ticks_msec()
	if velocity_before.length() > 65 and now-last_impact > 200:
		last_impact = now
		impact.emit(velocity_before.length())

func contains_point(world_point: Vector2) -> bool:
	var p = to_local(world_point)
	for poly in spec.polys:
		if Geometry2D.is_point_in_polygon(p,poly):
			return true
	return false

func _draw() -> void:
	preload("res://scripts/glass.gd").piece(self,spec,Vector2.ZERO,1,selected,failed,preview)
