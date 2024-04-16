class_name UnitManager extends Node3D

static var _unit_manager_static : UnitManager
static var _custom_static_init_done := false

static func static_summon(unitType : UnitTypeDefs.UnitType, spell_def : Dictionary, unit_position : Vector2, team : Team):
	if is_instance_valid(UnitManager._unit_manager_static):
		UnitManager._unit_manager_static.summon(unitType, spell_def, unit_position, team)


var scene_basic_walker := preload("res://Scenes/Units/UnitBrocolliInfantry/unit_basic_walker.tscn") as PackedScene
var scene_stationary_guard = preload("res://Scenes/Units/UnitLettuceWall/unit_stationary_guard.tscn") as PackedScene
var scene_flying_bomber := preload("res://Scenes/Units/UnitCrowBomber/unit_flying_bomber.tscn") as PackedScene
var scene_egg_projectile := preload("res://Scenes/Units/UnitEggProjectile/unit_egg_projectile.tscn") as PackedScene
var scene_tomato_plant := preload("res://Scenes/Units/UnitTomatoPlant/unit_tomato_plant.tscn") as PackedScene
var scene_tomato_projectile := preload("res://Scenes/Units/UnitTomatoProjectile/unit_tomato_projectile.tscn") as PackedScene
var scene_pumpkin_boulder := preload("res://Scenes/Units/UnitPumpkinBoulder/unit_pumpkin.tscn") as PackedScene

func get_unit_packed_scene(type : UnitTypeDefs.UnitType) -> PackedScene:
	var packed_scene : PackedScene = null 
	match(type):
		UnitTypeDefs.UnitType.BROCOLLI:           packed_scene = scene_basic_walker
		UnitTypeDefs.UnitType.LETTUCE:            packed_scene = scene_stationary_guard
		UnitTypeDefs.UnitType.CROW:               packed_scene = scene_flying_bomber
		UnitTypeDefs.UnitType.CROW_EGG:           packed_scene = scene_egg_projectile
		UnitTypeDefs.UnitType.TOMATO_PLANT:       packed_scene = scene_tomato_plant
		UnitTypeDefs.UnitType.TOMATO_PROJECTILE:  packed_scene = scene_tomato_projectile
		UnitTypeDefs.UnitType.PUMPKIN:            packed_scene = scene_pumpkin_boulder
	assert(packed_scene != null, "Failed to load unit scene for type " + UnitTypeDefs.get_unit_name(type))
	return packed_scene



@onready var playerController := %PlayerController as PlayerController
@onready var opponentController := %OpponentController as OpponentController
@onready var terrain_gen := %TerrainGen as TerrainGenerator

@export var summon_default_position_left : Node3D
@export var summon_default_position_right : Node3D



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
		if key_event.is_pressed():
			if not summon_lock:
				#if key_event.physical_keycode == KEY_1:
				#	summon("basicWalker", {}, Vector2(summon_default_position_left.global_position.x, 0), Team.PLAYER_TEST)
				#if key_event.physical_keycode == KEY_2:
				#	summon("basicWalker", {}, Vector2(summon_default_position_right.global_position.x, 0), Team.ENEMY_TEST)
				#if key_event.physical_keycode == KEY_3:
				#	summon("stationaryGuard", {}, Vector2(0, 0), Team.PLAYER_TEST)
				#if key_event.physical_keycode == KEY_4:
				#	summon("flyingBomber", {}, Vector2(0, 50.0), Team.PLAYER_TEST)
				#if key_event.physical_keycode == KEY_5:
				#	summon("tomatoPlant", {}, Vector2(0.0, 0.0), Team.ENEMY_TEST)
				pass
			summon_lock = true
		else:
			summon_lock = false


func summon(unitType : UnitTypeDefs.UnitType, spell_def : Dictionary, unit_position : Vector2, team : Team):
	var packed_scene := get_unit_packed_scene(unitType)
	var unit := packed_scene.instantiate() as UnitBase
	unit.consume_spell_def(spell_def)
	unit._manager = self
	unit._terrain = terrain_gen
	unit._position = Vector2(unit_position.x, unit_position.y)
	unit.team = team
	unit._lane_offset = Vector3(randi_range(0, 10) * 0.05, 0.0, randi_range(-30, 30) * 0.05)
	unit.unit_at_opponents_building.connect(do_unit_hurt_opponent_caster)
	unit.correct_spawn_position()
	add_child(unit)


func get_left_map_edge_x() -> float:
	return summon_default_position_left.global_position.x


func get_right_map_edge_x() -> float:
	return summon_default_position_right.global_position.x


func do_unit_hurt_opponent_caster(unit : UnitBase):
	var target_caster : AbstractSpellCaster
	
	match(unit.team.controller):
		Team.TeamController.AI: target_caster = playerController
		Team.TeamController.PLAYER: target_caster = opponentController
	
	target_caster.setHealth(target_caster.health - unit.reach_caster_damage)
