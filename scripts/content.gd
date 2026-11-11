extends RefCounted
# Collision and artwork share these polygons. Coordinates are relative to each body.
const TITLES = ["First salvage", "Make room", "Bridge the gap", "Left luggage", "Offset thinking", "Small margins", "Cross purposes", "Heavy little things", "Side by side", "Narrow escape", "Overhang", "The last shift"]
const NOTES = ["Leave room beneath the bridges.", "The numbers are names, not an order.", "Build a path for the weight.", "Look at where each bridge stands.", "Plan the gaps before you drop.", "A small adjustment makes a difference.", "Follow the opening, not the centre.", "Wide beams need balanced support.", "Keep the supports under the load.", "Give the treasures some breathing room.", "An overhang can still be balanced.", "One careful construction. Three recoveries."]

static func rect(x: float, y: float, w: float, h: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x,y), Vector2(x+w,y), Vector2(x+w,y+h), Vector2(x,y+h)])

static func shape(kind: String, w: float, h: float, gap: float = 0.0, offset: float = 0.0, treasure: int = 0) -> Dictionary:
	var polys: Array = []
	if kind == "bridge":
		var left = offset - gap/2.0
		var right = offset + gap/2.0
		polys = [rect(-w/2,-h/2,w,22), rect(-w/2,-h/2+22,left+w/2,h-22), rect(right,-h/2+22,w/2-right,h-22)]
	elif kind == "cantilever":
		polys = [rect(-w/2,-h/2,w,22),rect(-46,-h/2+22,92,h-22)]
	elif kind == "bracket":
		polys = [rect(-w/2,-h/2,w,22),rect(-w/2 if offset>0 else -w/2+64,-h/2+22,w-64,h-22)]
	elif kind == "wedge":
		polys = [PackedVector2Array([Vector2(-w/2,h/2),Vector2(-w/2,-h/2),Vector2(w/2,h/2)])]
	elif kind == "cross":
		polys = [rect(-w/2,h/2-22,w,22),rect(-22,-h/2,44,h-22)]
	elif kind == "step":
		polys = [rect(-w/2,0,w,h/2),rect(-w/2,-h/2,w*0.58,h/2)]
	elif kind == "elbow":
		polys = [rect(-w/2,h/2-22,w,22),rect(-w/2,-h/2,24,h-22)]
	else:
		polys = [rect(-w/2,-h/2,w,h)]
	return {"kind":kind,"w":w,"h":h,"gap":gap,"offset":offset,"treasure":treasure,"polys":polys}

static func sequence(index: int) -> Dictionary:
	var shifts = [[0,0,0],[-18,18,0],[26,-26,0],[-38,28,-22],[36,-36,30],[-42,38,-28],[40,-30,42],[-34,42,-40],[44,-44,24],[-42,42,-42],[44,30,-44],[-44,44,-38]][index]
	var widths = [180,180,184,190,184,190,196,196,192,190,200,196]
	var w = float(widths[index])
	var treasure_width = 42.0 if index < 6 else 38.0
	var gap = treasure_width + (24 if index < 3 else 16)
	var families = [
		["bridge","bridge","bridge"],["bridge","bridge","bridge"],["bridge","bridge","bridge"],
		["bracket","bridge","bridge"],["bridge","cantilever","bridge"],["bracket","bridge","bracket"],
		["cantilever","bridge","bracket"],["bridge","bracket","cantilever"],["bracket","cantilever","bridge"],
		["cantilever","bracket","bracket"],["bracket","bracket","cantilever"],["cantilever","bracket","cantilever"]
	][index]
	var shapes: Array = [shape("slab",200,30)]
	var route: Array = [0.0]
	for n in range(3):
		shapes.append(shape("core",treasure_width,42,0,0,n+1))
		var part_width = w-(n*4 if index>5 else 0)
		var offset = float(shifts[n])
		if families[n]=="cantilever": offset = 72.0 if shifts[n]>0 else -72.0
		if families[n]=="bracket": offset = (part_width/2-32)*(1 if shifts[n]>0 else -1)
		shapes.append(shape(families[n],part_width,84 + (n%2)*8,gap,offset))
		route.append(offset)
		route.append(0.0)
	var cap_kind = ["slab","slab","step","wedge","elbow","post","wedge","cross","elbow","step","wedge","cross"][index]
	shapes.append(shape(cap_kind,50 if cap_kind=="post" else (112 if index<6 else 144),100 if cap_kind=="post" else (38 if cap_kind=="slab" else 58)))
	# Authored reference placement: treasure pockets beside the structural load path.
	route.append(0.0)
	return {"id":index,"title":TITLES[index],"note":NOTES[index],"pieces":shapes,"route":route}
