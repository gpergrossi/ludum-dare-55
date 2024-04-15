class_name SigilController extends Node2D

@export var is_interactable : bool
@export var playback_per_edge_s : float
@export var playback_release_after_s : float
@export var interaction_distance : float
@export var snap_distance : float
@export var vertices : Array[SigilVertex] = []

signal rune_drawn(rune : Rune)

@onready var _line : Line2D = $SigilLine
var _current_path : Array[int] = []

# Called when the node enters the scene tree for the first time.
func _ready():
	_line.clear_points()
	assert(vertices.size() == 5, "did we lose vertices set on the Sigil node again?")


func getNearestSigilVertexTo(pos : Vector2):
	var nearest_vertex_idx := -1
	var nearest_vertex_distance := interaction_distance
	for i in range(vertices.size()):
		var distance = vertices[i].get_global_position().distance_to(pos)  # could be dist^2.
		if distance < nearest_vertex_distance:
			nearest_vertex_idx = i
			nearest_vertex_distance = distance
	return {
		'index': nearest_vertex_idx,
		'distance': nearest_vertex_distance,
	};

func _input(event : InputEvent) -> void:
	if not is_interactable:
		return
	
	var mouse_event := event as InputEventMouse
	if not mouse_event: return;
	
	var nearest = getNearestSigilVertexTo(mouse_event.position);
			
	# End the rune if we're distance from any vertex or have released the mosue.
	if nearest['index'] == -1 or mouse_event.button_mask & MOUSE_BUTTON_MASK_LEFT == 0:
		if not _current_path.is_empty():
			_release_rune()
			get_viewport().set_input_as_handled()
		return
		
	if nearest['distance'] < snap_distance:
		_maybe_add_to_path(nearest['index'])

	# Account for Sigil position and scale
	var pos = (mouse_event.position - get_global_position()) / transform.get_scale()
	_set_path_display_endpoint(pos)

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
	
func _set_path_display_endpoint(pos : Vector2) -> void:
	if _line.get_point_count() == _current_path.size():
		# Create initial endpoint. This is awful.
		_line.add_point(pos)
	else:
		_line.set_point_position(_current_path.size(), pos)

func _release_rune() -> void:
	_line.hide()  # TODO fun animation instead.
	rune_drawn.emit(Rune.new(_current_path))
	_current_path.clear()
	_line.clear_points()
	for vert in vertices:
		vert.visible = false;

func play_rune(rune : Rune) -> void:
	assert(!rune.path.is_empty(), "Can't play an empty rune!")
	await get_tree().create_timer(4.0).timeout
	
	_current_path.clear()
	var start_ticks_ms := Time.get_ticks_msec()
	var shown_path_idx := -1
	while shown_path_idx < rune.path.size() - 1:
		var current_path_idx := (Time.get_ticks_msec() - start_ticks_ms) / (playback_per_edge_s * 1000.0)
		while floor(current_path_idx) > shown_path_idx && shown_path_idx + 1 < rune.path.size():
			_maybe_add_to_path(rune.path[shown_path_idx + 1])
			shown_path_idx += 1
		if shown_path_idx >= 0 and shown_path_idx < rune.path.size() - 1:
			var endpoint_pos = vertices[rune.path[shown_path_idx]].position.lerp(vertices[rune.path[shown_path_idx + 1]].position, fmod(current_path_idx, 1.0))
			_set_path_display_endpoint(endpoint_pos)
		await get_tree().process_frame
		if not is_inside_tree():
			return
	
	await get_tree().create_timer(playback_release_after_s).timeout
	if not is_inside_tree():
		return
	_release_rune()
