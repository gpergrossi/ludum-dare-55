class_name CameraControls extends Node3D

@export var scroll_speed := 50.0
@export var left_edge : Node3D
@export var right_edge : Node3D

@onready var mouse_capture_handler := %"UI Container" as MouseCaptureHandler
@onready var zoom_node := %"Camera Offset" as Node3D
@onready var terrain := %TerrainGen as TerrainGenerator

@export var max_zoom_dist := 150.0
@export var min_zoom_dist := 20.0

var _current_zoom_distance : float


func _ready():
	_current_zoom_distance = max_zoom_dist
	zoom_node.position.z = _current_zoom_distance


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta : float):
	var shift_multiplier := (0.5 if Input.is_key_pressed(KEY_SHIFT) else 1.0)
	
	if mouse_capture_handler.is_mouse_captured():
		if mouse_capture_handler.is_mouse_in_left_margin() or Input.is_action_pressed("move_left"):
			position.x -= scroll_speed * delta * shift_multiplier
			if is_instance_valid(left_edge):
				position.x = maxf(position.x, left_edge.position.x)
				position.y = maxf(position.y, terrain.get_height(position.x))
		
		if mouse_capture_handler.is_mouse_in_right_margin() or Input.is_action_pressed("move_right"):
			position.x += scroll_speed * delta * shift_multiplier
			if is_instance_valid(right_edge):
				position.x = minf(position.x, right_edge.position.x)
				position.y = maxf(position.y, terrain.get_height(position.x))
				
		if Input.is_action_pressed("move_up"):
			position.y += scroll_speed * delta * shift_multiplier
			position.y = minf(position.y, 20.0)
			
		if Input.is_action_pressed("move_down"):
			position.y -= scroll_speed * delta * shift_multiplier
			position.y = maxf(position.y, 0.0)
	
	if Input.is_action_just_pressed("zoom_in"):
		_current_zoom_distance -= 10.0 * shift_multiplier
		_current_zoom_distance = maxf(_current_zoom_distance, min_zoom_dist)
		zoom_node.position.z = _current_zoom_distance
	
	if Input.is_action_just_pressed("zoom_out"):
		_current_zoom_distance += 10.0 * shift_multiplier
		_current_zoom_distance = minf(_current_zoom_distance, max_zoom_dist)
		zoom_node.position.z = _current_zoom_distance
