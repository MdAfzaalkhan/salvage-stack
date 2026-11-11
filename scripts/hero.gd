extends Control
const Glass = preload("res://scripts/glass.gd")
const Content = preload("res://scripts/content.gd")
var animate = true
var elapsed = 0.0
var result_shelf = false
var recovered: Array = [1,2,3]
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not animate: elapsed=2.0
func _process(delta: float) -> void:
	if animate:
		elapsed+=delta
		queue_redraw()
func _arrival(delay: float) -> float:
	return 1-pow(1-clampf((elapsed-delay)/0.45,0,1),3)
func _draw() -> void:
	var c = Vector2(size.x/2, size.y*.43)
	if result_shelf:
		c.y=size.y*.46
		for i in range(3):
			var t = _arrival(i*.08)
			var at = c+Vector2((i-1)*102,(1-t)*-22)
			var spec = Content.shape("core",64,68,0,0,i+1)
			if recovered.has(i+1):
				Glass.reflection(self,c+Vector2((i-1)*102,47),44,Glass.accent(i+1),t)
				Glass.piece(self,spec,at,1,false,false,false,t)
				draw_string(ThemeDB.fallback_font,at+Vector2(23,-27),"✓",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Glass.TEXT)
			else:
				Glass.piece(self,spec,at,1,false,false,true)
		Glass.piece(self,Content.shape("slab",354,18),c+Vector2(0,43))
		return
	var structure = [
		[Content.shape("slab",330,26),Vector2(0,143)],
		[Content.shape("bridge",290,100,230),Vector2(0,80)],
		[Content.shape("slab",164,30),Vector2(-50,15)],
		[Content.shape("wedge",104,64),Vector2(84,-2)]]
	for i in range(structure.size()):
		var t = _arrival(i*.07)
		var at = structure[i][1]+Vector2((1-t)*(-28 if i%2==0 else 28),0)
		Glass.piece(self,structure[i][0],c+at)
	for i in range(3):
		var t = _arrival(.22+i*.1)
		var bob = (sin(elapsed*.8+i*1.2)-1)*1.3 if animate and elapsed>1.2 else 0.0
		var at = c+Vector2((i-1)*76,100-(1-t)*32+bob)
		var shimmer = fmod(elapsed+float(i)*2.5,10)
		Glass.piece(self,Content.shape("core",56,60,0,0,i+1),at,1,false,false,false,t,shimmer if shimmer<1 and elapsed>2 else -1)
		Glass.reflection(self,c+Vector2((i-1)*76,166),45,Glass.accent(i+1),0.7+sin(elapsed*.8+i)*.12)
