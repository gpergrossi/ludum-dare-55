class_name UnitManager extends Node3D

static var _unit_manager_static : UnitManager

var scene_basic_walker := preload("res://Scenes/Units/unit_basic_walker.tscn") as PackedScene


func _ready():
	_unit_manager_static = self


func _input(event : InputEvent):
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.physical_keycode == KEY_1:
			summon("basicWalker", {}, Vector2(-200, 0), "Player")


static func summonBasicWalker(spell_def : Dictionary, position : Vector2, team : String):
	if is_instance_valid(_unit_manager_static):
		_unit_manager_static.summon("basicWalker", spell_def, position, team)


func summon(unitType : String, spell_def : Dictionary, position : Vector2, team : String):
	var packed_scene : PackedScene = null
	match(unitType):
		"basicWalker": packed_scene = scene_basic_walker
		_: 
			printerr("No such unit type \"" + unitType + "\"!")
			return
	
	var unit := packed_scene.instantiate() as UnitBase
	unit.team = team
	unit.position = Vector3(position.x, -position.y, 0.0)
	unit.consume_spell_def(spell_def)
	add_child(unit)
