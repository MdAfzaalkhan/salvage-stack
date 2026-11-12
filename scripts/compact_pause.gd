extends Button
# 88 logical-pixel target; the visible surface is only 54 pixels.
func _ready() -> void:
	text = ""
	for state in ["normal","hover","pressed","disabled","focus"]:
		add_theme_stylebox_override(state,StyleBoxEmpty.new())
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
func _draw() -> void:
	var r = Rect2(Vector2(size.x-58,8),Vector2(54,54))
	var material = preload("res://scripts/glass.gd").panel(Color("20232e") if not is_pressed() else Color("34394b"),13,Color("687086") if has_focus() else Color("454b5e"))
	draw_style_box(material,r)
	draw_line(r.position+Vector2(12,2),r.position+Vector2(42,2),Color(1,1,1,.18),1,true)
	for x in [22,32]: draw_line(r.position+Vector2(x,18),r.position+Vector2(x,36),Color("f4f5fa"),2.5,true)
