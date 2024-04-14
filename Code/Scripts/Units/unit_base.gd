class_name UnitBase extends CharacterBody3D

enum UnitState {
	MOVING,
	ATTACKING
}

static var next_uid := 0

const LAYER_WORLD := 1
const LAYER_PLAYER := 2
const LAYER_ENEMY := 3

@export_enum("Player", "Enemy") var team := "Player" : set = set_team_str
var team_def : Team

@export var unit_name : String

@export_category("Movement")
@export var top_speed := 10
@export var move_accel := 100.0
@export var gravity := 40.0

@export_category("Health")
@export var max_health := 100.0

@export_category("Attack")
@export var attack_range := 2.0
@export var damage := 30.0

@export_category("Rendering")
@export var damage_tint := 0.0 : set = set_damage_tint

@onready var _targeting_timer := %TargetingTimer as Timer
@onready var _ouch_animation := %OuchAnimation as AnimationPlayer

var _target_speed : float
var _health : float

var _id := 0
var _is_dead := false
var _state := UnitState.MOVING
var _target : UnitBase = null

signal state_changed(new_state : UnitState)


func _ready():
	_id = next_uid
	next_uid += 1
	
	_target_speed = top_speed
	_health = max_health
	set_team_str(team)
	state_changed.connect(on_state_changed)
	state_changed.emit(UnitState.MOVING)
	_targeting_timer.timeout.connect(_find_target)


func _physics_process(delta : float):
	var teamMoveX := team_def.get_team_move_x()
	
	if not is_on_floor():
		velocity += Vector3.DOWN * gravity * delta
	
	if absf(velocity.x - teamMoveX * _target_speed) > 0.0:
		var target_move_x := teamMoveX * _target_speed
		velocity.x = move_toward(velocity.x, target_move_x, move_accel * delta)
	
	move_and_slide()


func _find_target() -> void:
	if is_instance_valid(_target):
		# Current target is fine
		return
	
	var enemy := find_nearest_enemy(attack_range)
	if enemy:
		_target = enemy
		if _state != UnitState.ATTACKING:
			state_changed.emit(UnitState.ATTACKING)
	else:
		_target = null
		if _state != UnitState.MOVING:
			state_changed.emit(UnitState.MOVING)


func set_team_str(val : String):
	team = val
	team_def = TeamDefs.FromName(team)
	on_team_change(team_def)


# Override if you want to pull stats from the spell definition dictionary
func consume_spell_def(_spell_def : Dictionary):
	pass


func on_team_change(new_team_def : Team):
	var team_layer : int
	var other_team_layer : int
	match new_team_def.team_name:
		"Player": 
			team_layer = LAYER_PLAYER
			other_team_layer = LAYER_ENEMY
			show_green_art(true)
			show_red_art(false)
		"Enemy": 
			team_layer = LAYER_ENEMY
			other_team_layer = LAYER_PLAYER
			show_red_art(true)
			show_green_art(false)
		_: assert(false, "Bad team!")
	
	# Assign to own team layer + world objects layer
	set_collision_layer_value(LAYER_WORLD, false)
	set_collision_layer_value(team_layer, true)
	set_collision_layer_value(other_team_layer, false)
	
	# Collide with other team layer + world objects layer
	set_collision_mask_value(LAYER_WORLD, true)
	set_collision_mask_value(other_team_layer, true)
	set_collision_mask_value(team_layer, false)
	
	# Make sure art is facing the right way
	var art_node := find_child("Art2D") as Node3D
	if is_instance_valid(art_node):
		art_node.scale.x = new_team_def.get_team_move_x()


func show_red_art(val : bool):
	for child in find_children("*Red"):
		child.visible = val


func show_green_art(val : bool):
	for child in find_children("*Green"):
		child.visible = val


func find_nearest_enemy(max_range : float) -> UnitBase:
	var nearest_enemy : UnitBase = null
	var nearest_distance_squared = max_range * max_range
	
	var other_units := get_tree().get_nodes_in_group(&"units")
	
	for in_group in other_units:  # Could speed up with 1d tree even.
		var candidate_unit = in_group as UnitBase
		assert(candidate_unit, "All units should be UnitBase")
		if team_def == candidate_unit.team_def:
			continue
		if candidate_unit._is_dead:
			continue
		
		var distance_squared = global_position.distance_squared_to(candidate_unit.global_position)
		if distance_squared < nearest_distance_squared:
			nearest_enemy = candidate_unit
			nearest_distance_squared = distance_squared
	
	if is_instance_valid(nearest_enemy):
		print(to_string() + " found target " + nearest_enemy.to_string() + " at distance " + str(sqrt(nearest_distance_squared)))
	return nearest_enemy


func on_state_changed(new_state : UnitState):
	var unit_anims := find_child("UnitAnimations") as AnimationPlayer
	match(new_state):
		UnitState.MOVING: 
			print("Unit " + to_string() + " is now moving")
			_target_speed = top_speed
			if is_instance_valid(unit_anims):
				unit_anims.play("walk")
		UnitState.ATTACKING:
			print("Unit " + to_string() + " is now attacking")
			_target_speed = 0.0
			if is_instance_valid(unit_anims):
				unit_anims.play("attack")


func _to_string():
	return unit_name + " #" + str(_id) + " (" + team_def.team_name + ")"


# Call this from animation sequence to actually deal damage at the right time.
func damage_target():
	if is_instance_valid(_target):
		var dist := global_position.distance_to(_target.global_position)
		
		# Current swing is still allowed to hit up to 2x attack range
		if dist < attack_range * 2:
			# Apply damage
			_target.take_damage(damage)
			if _target._is_dead:
				_target = null
		
		# But the target will still be dropped afterward if out of attack range.
		if dist > attack_range:
			_target = null
	
	if not is_instance_valid(_target):
		state_changed.emit(UnitState.MOVING)


func take_damage(damage : float) -> void:
	_health -= damage
	_ouch_animation.play("ouch")
	velocity += Vector3(-team_def.get_team_move_x(), 0.5, 0).normalized() * 10.0
	if _health < 0:
		die()


func die() -> void:
	_is_dead = true
	queue_free()


func set_damage_tint(amount : float):
	var render_children := find_children("*Red")
	render_children.append_array(find_children("*Green"))
	for child in render_children:
		var meshInst := child as MeshInstance3D
		if is_instance_valid(meshInst):
			if meshInst.visible:
				set_damage_tint_on(meshInst, amount)


func set_damage_tint_on(meshInst : MeshInstance3D, amount : float):
	var material := meshInst.mesh.surface_get_material(0) as ShaderMaterial
	material.set_shader_parameter("albedo", Color.WHITE.lerp(Color.RED, amount))
