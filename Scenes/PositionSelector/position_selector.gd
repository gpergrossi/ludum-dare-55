class_name PositionSelector extends Sprite2D

@onready var _camera : Camera3D = %MainCamera
signal _clicked_at(global_pos : Vector2)
var _in_use := false

func select_position() -> Vector2:
	assert(!_in_use, "PositionSelector already in use")
	_in_use = true
	show()
	
	var global_pos = await _clicked_at
	
	var ray_origin := _camera.project_ray_origin(global_pos)
	var ray_dir := _camera.project_ray_normal(global_pos)
	
	var intersect_xy := Vector2(ray_origin.x, ray_origin.y) - (ray_origin.z / ray_dir.z) * Vector2(ray_dir.x, ray_dir.y)
	
	intersect_xy.y = -intersect_xy.y
	
	_in_use = false
	hide()
	return intersect_xy


func _input(event : InputEvent):
	var mouse_motion := event as InputEventMouseMotion
	if mouse_motion and _in_use:
		global_position = mouse_motion.global_position
		
	var mouse_click := event as InputEventMouseButton
	if mouse_click and _in_use and mouse_click.pressed and mouse_click.button_index == MOUSE_BUTTON_LEFT:
		_clicked_at.emit(mouse_click.global_position)
		get_viewport().set_input_as_handled()
