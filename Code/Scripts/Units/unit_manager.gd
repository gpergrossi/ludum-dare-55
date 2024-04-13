class_name UnitManager extends Node3D

static var _unit_manager_static : UnitManager
@onready var playerController : PlayerController = %PlayerController;

@export var summon_default_position_left : Node3D
@export var summon_default_position_right : Node3D

var scene_basic_walker := preload("res://Scenes/Units/unit_basic_walker.tscn") as PackedScene

var summon_lock := false

func _ready():
	_unit_manager_static = self


func _input(event : InputEvent):
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if event.is_pressed():
			if not summon_lock:
				if key_event.physical_keycode == KEY_1:
					playerController.cast(Spells.summonBasicWalker);
				if key_event.physical_keycode == KEY_2:
					summon("basicWalker", {}, Vector2(summon_default_position_right.global_position.x, 0), "Enemy")
			summon_lock = true
		else:
			summon_lock = false


static func summonBasicWalker(spell_def : Dictionary, unit_position : Vector2, team : String):
	if is_instance_valid(_unit_manager_static):
		_unit_manager_static.summon("basicWalker", spell_def, unit_position, team)


func summon(unitType : String, spell_def : Dictionary, unit_position : Vector2, team : String):
	var packed_scene : PackedScene = null
	match(unitType):
		"basicWalker": packed_scene = scene_basic_walker
		_:
			printerr("No such unit type \"" + unitType + "\"!")
			return
	
	var unit := packed_scene.instantiate() as UnitBase
	unit.team = team	
	unit.position = Vector3(unit_position.x, -unit_position.y, 0.0)
	unit.consume_spell_def(spell_def)
	add_child(unit)


func _on_unit_kill_plane_left_body_entered(body : PhysicsBody3D):
	if body is UnitBase:
		print("Unit killed")
		body.queue_free()


func _on_unit_kill_plane_right_body_entered(body : PhysicsBody3D):
	if body is UnitBase:
		print("Unit killed")
		body.queue_free()
