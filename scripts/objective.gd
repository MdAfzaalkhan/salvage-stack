extends Button
const Glass=preload("res://scripts/glass.gd")
const Content=preload("res://scripts/content.gd")
var number=1
var recovered=false
var selected=false
func _ready() -> void:
	for state in ["normal","hover","pressed","disabled","focus"]: add_theme_stylebox_override(state,StyleBoxEmpty.new())
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
func _draw() -> void:
	Glass.piece(self,Content.shape("core",42,42,0,0,number),size/2,1,selected or has_focus(),false,recovered)
	if recovered:
		var at=size/2
		draw_polyline(PackedVector2Array([at+Vector2(-8,0),at+Vector2(-2,7),at+Vector2(10,-8)]),Color("f4f5fa"),3,true)
