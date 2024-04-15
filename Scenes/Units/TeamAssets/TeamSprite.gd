@tool
class_name TeamSprite extends Node3D

@export_enum("Green", "Red") var team_color := "Green" : set = set_team_color
var _team_color := Team.TeamColor.GREEN
var _team_assets := Team.green_assets

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


func _ready():
	regenerate()


func set_team_color(color_name : String):
	team_color = color_name
	match(color_name):
		"Green": 
			print("Team is GREEN")
			_team_color = Team.TeamColor.GREEN
			_team_assets = Team.green_assets
		"Red": 
			print("Team is RED")
			_team_color = Team.TeamColor.RED
			_team_assets = Team.red_assets
		_:
			printerr("No such team color!")
	regenerate()


func set_asset_var_name(name):
	asset_var_name = name
	regenerate()


func cleanup():
	for child in get_children():
		var meshInst := child as MeshInstance3D
		if is_instance_valid(meshInst):
			meshInst.name = "GARBAGE" + str(randi())
			meshInst.queue_free()


func regenerate():
	cleanup()
	
	var sprite_scene := _team_assets.get(asset_var_name) as PackedScene
	if is_instance_valid(sprite_scene):
		var inst := sprite_scene.instantiate() as MeshInstance3D
		add_child(inst)
		inst.owner = self.owner
		print("Instantiated " + inst.name)
	
