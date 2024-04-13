class_name CameraControls extends Node3D

@export var scroll_speed := 50.0
@export var left_edge : Node3D
@export var right_edge : Node3D

@onready var mouse_capture_handler := %"UI Container" as MouseCaptureHandler


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta : float):
	if mouse_capture_handler.is_mouse_captured():
		if mouse_capture_handler.is_mouse_in_left_margin() or Input.is_key_pressed(KEY_LEFT):
			position.x -= scroll_speed * delta
			if is_instance_valid(left_edge):
				position.x = maxf(position.x, left_edge.position.x)
		
		if mouse_capture_handler.is_mouse_in_right_margin() or Input.is_key_pressed(KEY_RIGHT):
			position.x += scroll_speed * delta
			if is_instance_valid(right_edge):
				position.x = minf(position.x, right_edge.position.x)
