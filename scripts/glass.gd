extends RefCounted
const TEXT = Color("f4f5fa")
const SECONDARY = Color("aeb5c6")
const AMBER = Color("ffbc3d")
const ACCENTS = [Color("ffbc3d"),Color("ef4da8"),Color("49d7f1")]
static var simple = false

static func accent(number: int) -> Color:
	return ACCENTS[clampi(number-1,0,2)]

static func panel(color: Color = Color("151720"), radius: int = 20, edge: Color = Color("34394b")) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	s.set_border_width_all(1)
	s.border_color = edge
	s.content_margin_left = 24
	s.content_margin_right = 24
	s.content_margin_top = 18
	s.content_margin_bottom = 18
	return s

static func navigation(color: Color = AMBER) -> StyleBoxFlat:
	return panel(color,18,color.lightened(0.2))

static func _poly(points: PackedVector2Array, origin: Vector2, factor: float) -> PackedVector2Array:
	var result = PackedVector2Array()
	for p in points: result.append(origin+p*factor)
	return result

static func _clip(item: CanvasItem, poly: PackedVector2Array, mask: PackedVector2Array, color: Color) -> void:
	for clipped in Geometry2D.intersect_polygons(poly,mask):
		item.draw_colored_polygon(clipped,color)

static var materials: Dictionary = {}
static var contours: Dictionary = {}

static func material_key(spec: Dictionary) -> String:
	return "%s|%.3f|%.3f|%.3f|%.3f|%.3f|%d" % [spec.kind,float(spec.w),float(spec.h),float(spec.get("gap",0)),float(spec.get("offset",0)),float(spec.get("surface",0)),int(spec.treasure)]

static func load_materials() -> void:
	if not materials.is_empty(): return
	var entries = preload("res://scripts/material_catalog.gd").ENTRIES
	for entry in entries:
		materials[entry.key] = load("res://assets/materials/"+entry.file)
		var paths: Array = []
		for points in entry.contours:
			var path = PackedVector2Array()
			for point in points: path.append(Vector2(point[0],point[1]))
			paths.append(path)
		contours[entry.key] = paths

static func piece(item: CanvasItem, spec: Dictionary, origin: Vector2 = Vector2.ZERO, factor: float = 1, selected: bool = false, failed: bool = false, ghost: bool = false, number_alpha: float = 1, _shine: float = -1) -> void:
	if spec.is_empty(): return
	load_materials()
	var key = material_key(spec)
	var w = float(spec.w)*factor
	var h = float(spec.h)*factor
	var number = int(spec.treasure)
	if materials.has(key):
		item.draw_texture_rect(materials[key],Rect2(origin-Vector2(w,h)/2,Vector2(w,h)),false,Color(1,0.43,0.4,1) if failed else Color(1,1,1,0.23 if ghost else 1))
	else:
		push_error("Missing authored material: "+key)
	if ghost:
		for contour in contours.get(key,[]):
			var poly = _poly(contour,origin,factor)
			for i in range(poly.size()): item.draw_dashed_line(poly[i],poly[(i+1)%poly.size()],Color(0.92,0.95,1,0.9),1.3,4,true)
	if number>0:
		var font = ThemeDB.fallback_font
		var size = maxi(13,roundi(minf(float(spec.w)*0.59,float(spec.h)*0.61)*factor))
		var label = str(number)
		var width = font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
		var at = origin+Vector2(-width/2,size*.35)
		item.draw_string_outline(font,at,label,HORIZONTAL_ALIGNMENT_LEFT,-1,size,maxi(1,roundi(factor)),Color(0.02,0.03,0.05,number_alpha*.65))
		item.draw_string(font,at,label,HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color(TEXT,number_alpha))
	if selected:
		var bounds = Rect2(origin-Vector2(w/2+5,h/2+5),Vector2(w+10,h+10))
		var l = minf(11,w*.26)
		for corner in [Vector2(0,0),Vector2(1,0),Vector2(0,1),Vector2(1,1)]:
			var point = bounds.position+bounds.size*corner
			item.draw_line(point,point+Vector2(l*(1-2*corner.x),0),TEXT,2,true)
			item.draw_line(point,point+Vector2(0,l*(1-2*corner.y)),TEXT,2,true)

static func reflection(item: CanvasItem, at: Vector2, width: float, color: Color, strength: float = 1) -> void:
	if simple: return
	for i in range(4,0,-1):
		var half = width*(0.42+float(i)*0.13)
		var height = 1.2+float(i)*1.3
		var points = PackedVector2Array()
		for n in range(33): points.append(at+Vector2(cos(TAU*n/32)*half,sin(TAU*n/32)*height))
		item.draw_colored_polygon(points,Color(color,0.012*strength))
