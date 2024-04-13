class_name UnitBase extends CharacterBody3D

const LAYER_WORLD := 1
const LAYER_PLAYER := 2
const LAYER_ENEMY := 3

@export_enum("Player", "Enemy") var team := "Player" : set = set_team_str
var team_def : Team

@export var unit_name : String
@export var top_speed := 10
@export var move_accel := 100.0
@export var gravity := 40.0

@onready var body := %Body as MeshInstance3D
@onready var animation_player := %AnimationPlayer as AnimationPlayer

var _target_speed : float


func _ready():
	_target_speed = top_speed
	set_team_str(team)
	animation_player.play("walk")


func _physics_process(delta : float):
	var teamMoveX := team_def.get_team_move_x()
	
	if not is_on_floor():
		velocity += Vector3.DOWN * gravity * delta
	
	if absf(velocity.x - teamMoveX * _target_speed) > 0.0:
		var target_move_x := teamMoveX * _target_speed
		velocity.x = move_toward(velocity.x, target_move_x, move_accel * delta)
	
	move_and_slide()


func set_team_str(val : String):
	team = val
	team_def = TeamDefs.FromName(team)
	on_team_change(team_def)


# Override if you want to pull stats from the spell definition dictionary
func consume_spell_def(spell_def : Dictionary):
	pass


func on_team_change(team : Team):
	if is_instance_valid(body):
		var mat := body.mesh.surface_get_material(0) as StandardMaterial3D
		if is_instance_valid(team):
			mat.albedo_color = team.team_color
		else:
			mat.albedo_color = Color.GRAY
	
	var team_layer : int
	var other_team_layer : int
	match team.team_name:
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
	var art_node := %Art2D as Node3D
	if is_instance_valid(art_node):
		art_node.scale.x = team.get_team_move_x()


func show_red_art(val : bool):
	for child in find_children("*Red"):
		child.visible = val


func show_green_art(val : bool):
	for child in find_children("*Green"):
		child.visible = val
