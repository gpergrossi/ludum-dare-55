class_name UnitManager extends Node3D

static var _unit_manager_static : UnitManager
@onready var playerController := %PlayerController as PlayerController
@onready var opponentController := %OpponentController as OpponentController
@onready var terrain_gen := %TerrainGen as TerrainGenerator

@export var summon_default_position_left : Node3D
@export var summon_default_position_right : Node3D

var scene_basic_walker := load("res://Scenes/Units/unit_basic_walker.tscn") as PackedScene
var scene_stationary_guard := load("res://Scenes/Units/unit_stationary_guard.tscn") as PackedScene
var scene_flying_bomber := load("res://Scenes/Units/unit_flying_bomber.tscn") as PackedScene
var scene_egg_projectile := load("res://Scenes/Units/unit_egg_projectile.tscn") as PackedScene
var scene_tomato_plant := load("res://Scenes/Units/unit_tomato_plant.tscn") as PackedScene
var scene_tomato_projectile := load("res://Scenes/Units/unit_tomato_projectile.tscn") as PackedScene

var summon_lock := false

static func get_all_units(on_team : Team = null) -> Array[UnitBase]:
	var children : Array[Node] = _unit_manager_static.get_children()
	var ret : Array[UnitBase] = []
	for child in children:
		var unit := child as UnitBase
		if not unit:  continue
		if (on_team) && (unit.team != on_team):  continue
		ret.push_back(unit)
	return ret

func _ready():
	_unit_manager_static = self


func _input(event : InputEvent):
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if event.is_pressed():
			if not summon_lock:
				if key_event.physical_keycode == KEY_1:
					summon("basicWalker", {}, Vector2(summon_default_position_left.global_position.x, 0), Team.PLAYER_TEST)
				if key_event.physical_keycode == KEY_2:
					summon("basicWalker", {}, Vector2(summon_default_position_right.global_position.x, 0), Team.ENEMY_TEST)
				if key_event.physical_keycode == KEY_3:
					summon("stationaryGuard", {}, Vector2(0, 0), Team.PLAYER_TEST)
				if key_event.physical_keycode == KEY_4:
					summon("flyingBomber", {}, Vector2(0, 50.0), Team.PLAYER_TEST)
				if key_event.physical_keycode == KEY_5:
					summon("tomatoPlant", {}, Vector2(0.0, 0.0), Team.ENEMY_TEST)
			summon_lock = true
		else:
			summon_lock = false


static func summonBasicWalker(spell_def : Dictionary, unit_position : Vector2, team : Team):
	if is_instance_valid(_unit_manager_static):
		_unit_manager_static.summon("basicWalker", spell_def, unit_position, team)


static func summonStationaryGuard(spell_def : Dictionary, unit_position : Vector2, team : Team):
	if is_instance_valid(_unit_manager_static):
		_unit_manager_static.summon("stationaryGuard", spell_def, unit_position, team)


static func summonFlyingBomber(spell_def : Dictionary, unit_position : Vector2, team : Team):
	if is_instance_valid(_unit_manager_static):
		_unit_manager_static.summon("flyingBomber", spell_def, unit_position, team)


static func summonEggProjectile(spell_def : Dictionary, unit_position : Vector2, team : Team):
	if is_instance_valid(_unit_manager_static):
		_unit_manager_static.summon("eggProjectile", spell_def, unit_position, team)


static func summonTomatoPlant(spell_def : Dictionary, unit_position : Vector2, team : Team):
	if is_instance_valid(_unit_manager_static):
		_unit_manager_static.summon("tomatoPlant", spell_def, unit_position, team)


static func summonTomatoProjectile(spell_def : Dictionary, unit_position : Vector2, team : Team):
	if is_instance_valid(_unit_manager_static):
		_unit_manager_static.summon("tomatoProjectile", spell_def, unit_position, team)


func summon(unitType : String, spell_def : Dictionary, unit_position : Vector2, team : Team):
	var packed_scene : PackedScene = null
	match(unitType):
		"basicWalker":       packed_scene = scene_basic_walker
		"stationaryGuard":   packed_scene = scene_stationary_guard
		"flyingBomber":      packed_scene = scene_flying_bomber
		"eggProjectile":     packed_scene = scene_egg_projectile
		"tomatoPlant":       packed_scene = scene_tomato_plant
		"tomatoProjectile":  packed_scene = scene_tomato_projectile

	if packed_scene == null:
		printerr("No such unit type \"" + unitType + "\"!")
		return
	
	var unit := packed_scene.instantiate() as UnitBase
	unit.consume_spell_def(spell_def)
	unit._manager = self
	unit._terrain = terrain_gen
	unit._position = Vector2(unit_position.x, unit_position.y)
	unit.team = team
	unit._lane_offset = Vector3(randi_range(0, 10) * 0.05, 0.0, randi_range(-40, 40) * 0.05)
	unit.unit_at_opponents_building.connect(do_kill_plane)
	add_child(unit)


func get_left_map_edge_x() -> float:
	return summon_default_position_left.global_position.x


func get_right_map_edge_x() -> float:
	return summon_default_position_right.global_position.x


func do_kill_plane(unit : UnitBase):
	var target_caster : AbstractSpellCaster
	
	match(unit.team.controller):
		Team.TeamController.AI: target_caster = playerController
		Team.TeamController.PLAYER: target_caster = opponentController
	
	target_caster.setHealth(target_caster.health - unit.reach_caster_damage)
