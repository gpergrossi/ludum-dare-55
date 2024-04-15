class_name MouseCaptureHandler extends PanelContainer

@export var scroll_margin := 50.0
@export var release_margin_y := 10.0

var _is_mouse_scrolling_left := false
var _is_mouse_scrolling_right := false
var _is_captured := false

@onready var camera := %MainCamera as Camera3D

var _release_time := 0

func _ready():
	_release_time = Time.get_ticks_msec() - 3001


func _process(_delta : float):
	if Input.is_action_just_pressed("escape"):
		_release_time = Time.get_ticks_msec()
		release_mouse()


func _input(event : InputEvent):
	if event is InputEventMouseMotion:
		var mouseMotionEvent := event as InputEventMouseMotion
		var pos := mouseMotionEvent.position
		_is_mouse_scrolling_left = (pos.x < scroll_margin)
		_is_mouse_scrolling_right = (pos.x > get_viewport_rect().size.x - scroll_margin)
		
		if _is_captured and (pos.y < release_margin_y or (pos.y > get_viewport_rect().size.y - release_margin_y)):
			release_mouse()
		elif Time.get_ticks_msec() > _release_time + 3000:
			capture_mouse()


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
