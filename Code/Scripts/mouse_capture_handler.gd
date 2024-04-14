class_name MouseCaptureHandler extends PanelContainer

@export var scroll_margin := 50.0
@export var release_margin_y := 10.0

var _is_mouse_scrolling_left := false
var _is_mouse_scrolling_right := false
var _is_captured := false
var _is_release_message_shown := false

@onready var camera := %MainCamera as Camera3D


func _process(_delta : float):
	if Input.is_action_just_pressed("escape"):
		release_mouse()


func _input(event : InputEvent):
	if event is InputEventMouseMotion:
		var mouseMotionEvent := event as InputEventMouseMotion
		var pos := mouseMotionEvent.position
		_is_mouse_scrolling_left = (pos.x < scroll_margin)
		_is_mouse_scrolling_right = (pos.x > get_viewport_rect().size.x - scroll_margin)
		
		if _is_captured and (pos.y < release_margin_y or (pos.y > get_viewport_rect().size.y - release_margin_y)):
			release_mouse()
		else:
			capture_mouse()
	
	elif event is InputEventMouse:
		var mouseEvent := event as InputEventMouse
		if mouseEvent.is_pressed():
			var ray_origin := camera.project_ray_origin(mouseEvent.position)
			var ray_dir := camera.project_ray_normal(mouseEvent.position)
			
			var intersect_xy := Vector2(ray_origin.x, ray_origin.y) - (ray_origin.z / ray_dir.z) * Vector2(ray_dir.x, ray_dir.y)
			print("Your ray hit the world XY plane at: " + str(intersect_xy))


func capture_mouse():
	_is_captured = true
	if Input.mouse_mode != Input.MOUSE_MODE_CONFINED:
		Input.mouse_mode = Input.MOUSE_MODE_CONFINED


func release_mouse():
	_is_captured = false
	if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func is_mouse_in_left_margin() -> bool:
	return _is_mouse_scrolling_left


func is_mouse_in_right_margin() -> bool:
	return _is_mouse_scrolling_right


func is_mouse_captured() -> bool:
	return _is_captured
