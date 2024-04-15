class_name UnitManager extends Node3D

static var _unit_manager_static : UnitManager
@onready var playerController := %PlayerController as PlayerController
@onready var opponentController := %OpponentController as OpponentController
@onready var terrain_gen := %TerrainGen as TerrainGenerator

@export var summon_default_position_left : Node3D
@export var summon_default_position_right : Node3D

var scene_basic_walker := preload("res://Scenes/Units/unit_basic_walker.tscn") as PackedScene
var scene_stationary_guard := preload("res://Scenes/Units/unit_stationary_guard.tscn") as PackedScene
var scene_flying_bomber := preload("res://Scenes/Units/unit_flying_bomber.tscn") as PackedScene

var summon_lock := false

static func get_all_units(on_team : Team = null) -> Array[UnitBase]:
	var children : Array[Node] = _unit_manager_static.get_children();
	var ret : Array[UnitBase] = [];
	for child in children:
		var unit := child as UnitBase;
		if not unit: continue;
		if (on_team) && (unit.team != on_team): continue;
		ret.push_back(unit);
	return ret;

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
				if key_event.physical_keycode == KEY_3:
					summon("stationaryGuard", {}, Vector2(0, 0), "Player")
				if key_event.physical_keycode == KEY_4:
					summon("flyingBomber", {}, Vector2(0, -50.0), "Player")
			summon_lock = true
		else:
			summon_lock = false


static func summonBasicWalker(spell_def : Dictionary, unit_position : Vector2, team : String):
	if is_instance_valid(_unit_manager_static):
		_unit_manager_static.summon("basicWalker", spell_def, unit_position, team)


static func summonStationaryGuard(spell_def : Dictionary, unit_position : Vector2, team : String):
	if is_instance_valid(_unit_manager_static):
		_unit_manager_static.summon("stationaryGuard", spell_def, unit_position, team)


static func summonFlyingBomber(spell_def : Dictionary, unit_position : Vector2, team : String):
	if is_instance_valid(_unit_manager_static):
		_unit_manager_static.summon("flyingBomber", spell_def, unit_position, team)


func summon(unitType : String, spell_def : Dictionary, unit_position : Vector2, team : String):
	var packed_scene : PackedScene = null
	match(unitType):
		"basicWalker":     packed_scene = scene_basic_walker
		"stationaryGuard": packed_scene = scene_stationary_guard
		"flyingBomber":    packed_scene = scene_flying_bomber

	if packed_scene == null:
		printerr("No such unit type \"" + unitType + "\"!")
		return
	
	var unit := packed_scene.instantiate() as UnitBase
	unit.consume_spell_def(spell_def)
	unit.position = Vector3(unit_position.x, -unit_position.y, 0.0)
	unit._lane_offset = Vector3(randi_range(-10, 10) * 0.1, 0.0, randi_range(-10, 10) * 0.1)
	unit.set_terrain_ref(terrain_gen)
	add_child(unit)
	unit.team_name = team


func _on_unit_kill_plane_left_body_entered(body : PhysicsBody3D):
	_do_kill_plane(body, playerController)


func _on_unit_kill_plane_right_body_entered(body : PhysicsBody3D):
	_do_kill_plane(body, opponentController)


func _do_kill_plane(body : PhysicsBody3D, target_caster : AbstractSpellCaster):
	var unit := body as UnitBase
	if not unit:
		return
	
	unit.do_kill_plane()
	target_caster.setHealth(target_caster.health - unit.reach_caster_damage)
