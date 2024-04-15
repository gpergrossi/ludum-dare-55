@tool
class_name TeamSprite extends Node3D

@export var team_color := Team.TeamColor.GREEN : set = set_team_color

@export_enum(
	"brocolli_sprite",
	"brocolli_spear_sprite",

	"lettuce_sprite",

	"crow_sprite",
	"egg_sprite",
	"egg_splat_sprite",

	"carrot_sprite",
	"falling_carrot_sprite",

	"corn_sprite",
	"corn_projectile_sprite",
	"popcorn_grenade_sprite",
	"popcorn_sprite",

	"pumpkin_sprite",

	"tomato_sprite",
	"tomato_projectile_sprite",
	"tomato_splat_sprite",
)
var asset_var_name : String = "brocolli_sprite" : set = set_asset_var_name

var team_assets := Team.green_assets
var sprite_instance : MeshInstance3D
@export var color_tint := Color.WHITE : set = set_color_tint

@export_category("Damage Flash")
@export var damage_flash_time := 0.3
@export var damage_flash_intensity := 0.3
@export var damage_flash_color := Color.RED
@export var test_damage_flash := false : set = set_test_damage_flash
var _damage_flash_time_remaining := 0.0

@export_category("Rendering Tweaks")
@export var sort_offset := 0.0


func _ready():
	regenerate()


func _physics_process(delta : float):
	if is_instance_valid(sprite_instance):
		update_mesh_albedo(delta)


func do_damage_flash():
	_damage_flash_time_remaining = damage_flash_time


func set_test_damage_flash(b : bool):
	if not b: return
	do_damage_flash()


func set_team_color(color : Team.TeamColor):
	team_color = color
	match(team_color):
		Team.TeamColor.GREEN:
			team_assets = Team.green_assets
		Team.TeamColor.RED:
			team_assets = Team.red_assets
		_:
			printerr("No such team color!")
	
	if is_node_ready():
		regenerate()


func set_asset_var_name(name):
	asset_var_name = name
	if is_node_ready():
		regenerate()


func regenerate():
	_cleanup_instance()
	_generate_instance()


func _cleanup_instance():
	for child in get_children():
		var meshInst := child as MeshInstance3D
		if is_instance_valid(meshInst):
			meshInst.name = "GARBAGE" + str(randi())
			meshInst.queue_free()


func _generate_instance():
	var sprite_scene := team_assets.get(asset_var_name) as PackedScene
	if is_instance_valid(sprite_scene):
		var inst := sprite_scene.instantiate() as MeshInstance3D
		add_child(inst)
		inst.owner = self.owner
		sprite_instance = inst
		sprite_instance.sorting_offset = sort_offset


func set_color_tint(color : Color):
	color_tint = color
	update_mesh_albedo(0.0, true)


func update_mesh_albedo(delta := 0.0, force := false):
	# Animate color flash from damage
	if _damage_flash_time_remaining > 0.0 or force:
		_damage_flash_time_remaining -= delta
		var intensity := get_damage_flash_intensity()
		set_color_tint_on_mesh(sprite_instance, color_tint.lerp(damage_flash_color, intensity))


func get_damage_flash_intensity() -> float:
	if is_zero_approx(damage_flash_time):
		return 0.0
	return lerpf(0.0, damage_flash_intensity, clampf(_damage_flash_time_remaining / damage_flash_time, 0.0, 1.0))


func set_color_tint_on_mesh(meshInst : MeshInstance3D, color : Color):
	var material := sprite_instance.mesh.surface_get_material(0) as ShaderMaterial
	var curr_color := material.get_shader_parameter("albedo") as Color
	
	if absf(color.r - curr_color.r) > 0.01 or absf(color.g - curr_color.g) > 0.01 or absf(color.b - curr_color.b) > 0.01:
		material.set_shader_parameter("albedo", color)
