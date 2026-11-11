extends PanelContainer
# Actual tutorial component: layout and pointer stay separate from game artwork.
var pointer = false
func _draw() -> void:
	if pointer:
		var x = size.x/2
		draw_colored_polygon(PackedVector2Array([Vector2(x-14,size.y-2),Vector2(x,size.y+14),Vector2(x+14,size.y-2)]),Color("626b87"))
		draw_colored_polygon(PackedVector2Array([Vector2(x-10,size.y-3),Vector2(x,size.y+8),Vector2(x+10,size.y-3)]),Color("151720"))
