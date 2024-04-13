class_name SigilController extends Node2D

@export var interaction_distance : float
@export var snap_distance : float
@export var vertices : Array[SigilVertex] = []

signal rune_drawn(rune : Rune)

@onready var _line : Line2D = $SigilLine
var _current_path : Array[int] = []

# Called when the node enters the scene tree for the first time.
func _ready():
	_line.clear_points()

func getNearestSigilVertexTo(target_position : Vector2):
	var nearest_vertex_idx := -1
	var nearest_vertex_distance := interaction_distance
	for i in range(vertices.size()):
		var distance = vertices[i].get_global_position().distance_to(target_position)  # could be dist^2.
		if distance < nearest_vertex_distance:
			nearest_vertex_idx = i
			nearest_vertex_distance = distance
	return {
		'index': nearest_vertex_idx,
		'distance': nearest_vertex_distance,
	};

func _input(event : InputEvent) -> void:
	var mouse_event := event as InputEventMouse
	if not mouse_event: return;
	
	var nearest = getNearestSigilVertexTo(mouse_event.position);
			
	# Release sigil if we're distance from any vertex or have released the mosue.
	if nearest['index'] == -1 or mouse_event.button_mask & MOUSE_BUTTON_MASK_LEFT == 0:
		if not _current_path.is_empty():
			_release_sigil()
			get_viewport().set_input_as_handled()
		return
		
	if nearest['distance'] < snap_distance:
		_maybe_add_to_path(nearest['index'])

	# Account for Sigil position and scale
	var pos = (mouse_event.position - get_global_position()) / transform.get_scale()

	if _line.get_point_count() == _current_path.size():
		# Create initial endpoint. This is awful.
		_line.add_point(pos)
	else:
		_line.set_point_position(_current_path.size(), pos)

	get_viewport().set_input_as_handled()
	

func _maybe_add_to_path(vertex_idx : int) -> void:
	# Edges must be between different vertices.
	if not _current_path.is_empty() and _current_path.back() == vertex_idx:
		return
	
	# Edges must not already be in the path.
	for i in range(_current_path.size() - 1):
		var new_from : int = _current_path.back()
		var existing_from := _current_path[i]
		var existing_to := _current_path[i+1]
		if (new_from == existing_from and vertex_idx == existing_to) or (new_from == existing_to and vertex_idx == existing_from):
			return
	
	_current_path.push_back(vertex_idx)
	_line.show()
	_line.add_point(vertices[vertex_idx].position, _current_path.size() - 1)
	vertices[vertex_idx].visible = true;

func _release_sigil() -> void:
	_line.hide()  # TODO fun animation instead.
	rune_drawn.emit(Rune.new(_current_path))
	_current_path.clear()
	_line.clear_points()
	for vert in vertices:
		vert.visible = false;
