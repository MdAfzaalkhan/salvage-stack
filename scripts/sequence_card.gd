extends Control
signal activated
const Glass = preload("res://scripts/glass.gd")
const Content = preload("res://scripts/content.gd")
var index = 0
var best = 0
var won = false
var current = false
var scroll: ScrollContainer
var held = false
var moved = false
var touch_active = false
var press_y = 0.0
var scroll_y = 0

func _ready() -> void:
	focus_mode=Control.FOCUS_ALL
	mouse_filter=Control.MOUSE_FILTER_STOP
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)

func _begin(point: Vector2) -> void:
	held=true
	moved=false
	press_y=point.y
	scroll_y=scroll.scroll_vertical if is_instance_valid(scroll) else 0
	grab_focus()

func _move(point: Vector2) -> void:
	if not held: return
	var distance=point.y-press_y
	if absf(distance)>12: moved=true
	if moved and is_instance_valid(scroll): scroll.scroll_vertical=scroll_y-roundi(distance)

func _release() -> void:
	var choose=held and not moved
	held=false
	if choose: activated.emit()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		touch_active=event.pressed
		if event.pressed: _begin(get_global_transform()*event.position)
		else: _release()
		accept_event()
	elif event is InputEventScreenDrag:
		_move(get_global_transform()*event.position)
		accept_event()
	elif event is InputEventMouseButton:
		if event.device==-1 or touch_active: return
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			if is_instance_valid(scroll): scroll.scroll_vertical+=-64 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 64
		elif event.button_index==MOUSE_BUTTON_LEFT:
			if event.pressed: _begin(get_global_transform()*event.position)
			else: _release()
		accept_event()
	elif event is InputEventMouseMotion and not touch_active:
		_move(get_global_transform()*event.position)
	elif event is InputEventKey and event.is_action_pressed("ui_accept") and not event.echo:
		activated.emit()
		accept_event()

func _draw() -> void:
	var frame = Glass.panel(Color("151720"),18,Glass.AMBER if current or has_focus() else Color("34394b"))
	draw_style_box(frame,Rect2(Vector2.ONE,size-Vector2.ONE*2))
	draw_line(Vector2(18,2),Vector2(size.x-18,2),Color(0.65,0.7,0.84,0.12),1,true)
	var font=ThemeDB.fallback_font
	draw_string(font,Vector2(22,58),"%02d"%(index+1),HORIZONTAL_ALIGNMENT_LEFT,-1,40,Glass.TEXT)
	if won: draw_string(font,Vector2(size.x-45,51),"✓",HORIZONTAL_ALIGNMENT_LEFT,-1,27,Glass.AMBER)
	for number in range(1,4):
		var at=Vector2(size.x/2+(number-2)*44,size.y-58)
		Glass.piece(self,Content.shape("core",32,38,0,0,number),at,1,false,false,number>best)
	var label = "COMPLETE" if won else "BEST %d / 3"%best
	var width=font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,18).x
	draw_string(font,Vector2((size.x-width)/2,size.y-18),label,HORIZONTAL_ALIGNMENT_LEFT,-1,18,Glass.SECONDARY)
