class_name UnitBase extends CharacterBody3D

@export_enum("Player", "Enemy") var team := "Player" : set = set_team_str
var team_def : Team

@export var unit_name : String
@export var top_speed := 50
@export var move_accel := 20.0
@export var gravity := 20.0

var _target_speed : float

func _ready():
	_target_speed = top_speed


func _physics_process(delta : float):
	var teamMoveX := team_def.get_team_move_x()
	
	if not is_on_floor():
		velocity += Vector3.DOWN * gravity * delta
	
	if absf(velocity.x - teamMoveX * _target_speed) > 0.0:
		var target_move_x := teamMoveX * _target_speed
		velocity.x = move_toward(velocity.x, target_move_x, move_accel * delta)
	
	print("Updating unit. Move dir = " + str(teamMoveX) + ", Velocity = " + str(velocity))
	move_and_slide()


func set_team_str(val : String):
	team = val
	team_def = TeamDefs.FromName(team)


# Override if you want to pull stats from the spell definition dictionary
func consume_spell_def(spell_def : Dictionary):
	pass
