extends Node2D

@export var interaction_distance : float
@export var snap_distance : float
@export var vertices : Array[SigilVertex] = []

signal rune_drawn(rune : Rune)

@onready var _line : Line2D = $SigilLine
var _current_path : Array[int] = []

# Called when the node enters the scene tree for the first time.
func _ready():
	_line.clear_points()

func _input(event : InputEvent) -> void:
	var mouse_event := event as InputEventMouse
	if not mouse_event:
		return
	
	var nearest_vertex_idx := -1
	var nearest_vertex_distance := interaction_distance
	for i in range(vertices.size()):
		var distance = vertices[i].position.distance_to(mouse_event.position)  # could be dist^2.
		if distance < nearest_vertex_distance:
			nearest_vertex_idx = i
			nearest_vertex_distance = distance
			
	# Release sigil if we're distance from any vertex or have released the mosue.
	if nearest_vertex_idx == -1 or mouse_event.button_mask & MOUSE_BUTTON_MASK_LEFT == 0:
		if not _current_path.is_empty():
			_release_sigil()
			get_viewport().set_input_as_handled()
		return
		
	if nearest_vertex_distance < snap_distance:
		_maybe_add_to_path(nearest_vertex_idx)

	if _line.get_point_count() == _current_path.size():
		# Create initial endpoint. This is awful.
		_line.add_point(mouse_event.position)
	else:
		_line.set_point_position(_current_path.size(), mouse_event.position)

	get_viewport().set_input_as_handled()
	

func _maybe_add_to_path(vertex_idx : int) -> void:
	if not _current_path.is_empty() and _current_path.back() == vertex_idx:
		return  # TODO also forbid repeat edges.
	_current_path.push_back(vertex_idx)
	_line.show()
	_line.add_point(vertices[vertex_idx].position, _current_path.size() - 1)

func _release_sigil() -> void:
	_line.hide()  # TODO fun animation instead.
	rune_drawn.emit(Rune.new(_current_path))
	_current_path.clear()
	_line.clear_points()