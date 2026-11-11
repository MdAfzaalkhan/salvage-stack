extends Node2D
const Glass = preload("res://scripts/glass.gd")
var spec: Dictionary
func _draw() -> void:
	if not spec.is_empty(): Glass.piece(self,spec)
