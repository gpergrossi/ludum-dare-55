class_name MouseCaptureHandler extends PanelContainer

@export var scroll_margin := 50.0

var _is_mouse_scrolling_left := false
var _is_mouse_scrolling_right := false
var _is_captured := false
var _is_release_message_shown := false


func _process(_delta : float):
	if Input.is_action_just_pressed("escape"):
		release_mouse()


func _input(event : InputEvent):
	if event is InputEventMouseMotion:
		var mouseMotionEvent := event as InputEventMouseMotion
		var pos := mouseMotionEvent.position
		_is_mouse_scrolling_left = (pos.x < scroll_margin)
		_is_mouse_scrolling_right = (pos.x > get_viewport_rect().size.x - scroll_margin)
		
		if pos.y < scroll_margin and _is_captured:
			show_mouse_release_message(0.5)
	
	elif event is InputEventMouse:
		var mouseEvent := event as InputEventMouse
		if mouseEvent.is_pressed():
			capture_mouse()


func capture_mouse():
	_is_captured = true
	if Input.mouse_mode != Input.MOUSE_MODE_CONFINED:
		Input.mouse_mode = Input.MOUSE_MODE_CONFINED
		%"Edit Mouse Capture Message".visible = false
		show_mouse_release_message()


func release_mouse():
	_is_captured = false
	if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		%"Edit Mouse Capture Message".visible = true
		%"Press Escape To Release Mouse".visible = false


func show_mouse_release_message(duration := 2.5):
	if not _is_release_message_shown:
		_is_release_message_shown = true
		%"Press Escape To Release Mouse".visible = true
		var timer := get_tree().create_timer(duration)
		timer.timeout.connect(hide_esc_message)


func hide_esc_message():
	%"Press Escape To Release Mouse".visible = false
	_is_release_message_shown = false


func is_mouse_in_left_margin() -> bool:
	return _is_mouse_scrolling_left


func is_mouse_in_right_margin() -> bool:
	return _is_mouse_scrolling_right


func is_mouse_captured() -> bool:
	return _is_captured
