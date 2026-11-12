extends HSlider
# Decorative direction cues; Range values and native touch behaviour are unchanged.
func _draw() -> void:
	var c=Color("aeb5c6")
	var y=size.y/2
	for side in [-1,1]:
		var x=-23.0 if side<0 else size.x+23.0
		draw_line(Vector2(x-side*12,y),Vector2(x,y),c,1.3,true)
		draw_line(Vector2(x,y),Vector2(x-side*5,y-4),c,1.3,true)
		draw_line(Vector2(x,y),Vector2(x-side*5,y+4),c,1.3,true)
