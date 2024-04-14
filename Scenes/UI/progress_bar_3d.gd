@tool
class_name Progressbar3d extends Node3D

@onready var foreground := $Foreground

@export_range(0.0, 1.0) var fraction := 1.0:
	set(new_fraction):
		fraction = new_fraction
		if foreground:
			_resize_foreground()

func _ready():
	_resize_foreground()

func _resize_foreground():
		foreground.scale.x = fraction
		# Keep left side of the foreground bar on the left.
		foreground.position.x = fraction * 0.5 - 0.5
