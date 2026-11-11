extends Control
const Glass = preload("res://scripts/glass.gd")
var spec: Dictionary = {}
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	if spec.is_empty(): return
	var factor=minf((size.x-14)/float(spec.w),(size.y-14)/float(spec.h))
	Glass.piece(self,spec,size/2,factor)
