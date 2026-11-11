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

static func piece(item: CanvasItem, spec: Dictionary, origin: Vector2 = Vector2.ZERO, factor: float = 1, selected: bool = false, failed: bool = false, ghost: bool = false, number_alpha: float = 1, shine: float = -1) -> void:
	if spec.is_empty(): return
	var number = int(spec.treasure)
	var tint = accent(number) if number>0 else Color("889bbd")
	var front = tint.darkened(0.68) if number>0 else Color("263044")
	if failed: tint = Color("ff796c"); front=Color("582e38")
	var w = float(spec.w)*factor
	var h = float(spec.h)*factor
	for raw in spec.polys:
		var poly = _poly(raw,origin,factor)
		var colors = PackedColorArray()
		for p in poly:
			var t = clampf((p.y-origin.y+h/2)/h,0,1)
			var col = front.lightened(0.22).lerp(front.darkened(0.35),t)
			col.a = 0.2 if ghost else 0.98
			colors.append(col)
		item.draw_polygon(poly,colors)
		var closed = poly.duplicate()
		closed.append(poly[0])
		if ghost:
			for i in range(poly.size()): item.draw_dashed_line(poly[i],poly[(i+1)%poly.size()],Color(0.85,0.9,1,0.8),1.5,5,true)
			continue
		item.draw_polyline(closed,Color(tint,0.65 if number>0 else 0.42),maxf(1,factor),true)
		for inset in Geometry2D.offset_polygon(poly,-2.5*factor):
			var rim = inset.duplicate(); rim.append(inset[0])
			item.draw_polyline(rim,Color(tint,0.2),1,true)
		var top_mask = PackedVector2Array([origin+Vector2(-w,-h/2+2),origin+Vector2(w,-h/2+2),origin+Vector2(w,-h/2+5),origin+Vector2(-w,-h/2+5)])
		_clip(item,poly,top_mask,Color(0.9,0.94,1,0.23))
		if not simple:
			var stripe = PackedVector2Array([origin+Vector2(-w*.45,-h),origin+Vector2(-w*.24,-h),origin+Vector2(w*.32,h),origin+Vector2(w*.11,h)])
			_clip(item,poly,stripe,Color(0.8,0.87,1,0.07))
			if number>0:
				var facet = PackedVector2Array([origin+Vector2(-w/2,h/2),origin+Vector2(w/2,-h/2),origin+Vector2(w/2,h/2)])
				_clip(item,poly,facet,Color(tint,0.13))
			if shine>=0 and shine<=1:
				var x = lerpf(-w,w,shine)
				var sweep = PackedVector2Array([origin+Vector2(x-12,-h),origin+Vector2(x,-h),origin+Vector2(x+h,h),origin+Vector2(x+h-12,h)])
				_clip(item,poly,sweep,Color(1,1,1,0.15*sin(shine*PI)))
	if number>0:
		var font = ThemeDB.fallback_font
		var size = maxi(13,roundi(25*factor))
		var backing = panel(Color(0.015,0.02,0.04,0.55),maxi(2,roundi(4*factor)),Color(tint,0.15))
		item.draw_style_box(backing,Rect2(origin-Vector2(13,16)*factor,Vector2(26,32)*factor))
		var label = str(number)
		var width = font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
		item.draw_string(font,origin+Vector2(-width/2,size*.35),label,HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color(TEXT,number_alpha))
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
