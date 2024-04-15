@tool
class_name Team

static func _static_init():
	green_assets = load("res://Scenes/Units/TeamAssets/Green/TeamAssetsGreen.tres") as TeamAssets
	red_assets = load("res://Scenes/Units/TeamAssets/Red/TeamAssetsRed.tres") as TeamAssets
	PLAYER_TEST = Team.new(TeamColor.GREEN, TeamSide.LEFT, TeamCharacter.AZRA, TeamController.PLAYER)
	ENEMY_TEST = Team.new(TeamColor.RED, TeamSide.RIGHT, TeamCharacter.RORY, TeamController.AI)

static var green_assets : TeamAssets
static var red_assets : TeamAssets

static var PLAYER_TEST : Team
static var ENEMY_TEST : Team

enum TeamColor {
	GREEN,
	RED
}

enum TeamSide {
	LEFT,
	RIGHT
}

enum TeamCharacter {
	AZRA,
	RORY
}

enum TeamController {
	PLAYER,
	AI
}

var color : TeamColor
var side : TeamSide
var character : TeamCharacter
var controller : TeamController

func _init(color_ : TeamColor, side_ : TeamSide, character_ : TeamCharacter, controller_ : TeamController):
	color = color_
	side = side_
	character = character_
	controller = controller_

func get_assets() -> TeamAssets:
	match(color):
		TeamColor.GREEN:  return green_assets
		TeamColor.RED:  return red_assets
		_:  assert(false, ":(");  return null

func get_barn_asset() -> PackedScene:
	var assets := get_assets()
	match(side):
		TeamSide.LEFT:  return assets.barn_asset_left
		TeamSide.RIGHT:  return assets.barn_asset_right
		_:  assert(false, ":(");  return null

func get_move_direction_x() -> int:
	match(side):
		TeamSide.LEFT:  return 1
		TeamSide.RIGHT:  return -1
		_:  assert(false, ":(");  return 0

func get_character_name() -> String:
	match(character):
		TeamCharacter.AZRA:  return "Azra"
		TeamCharacter.RORY:  return "Rory"
		_:  assert(false, ":(");  return ""

func get_controlled_by_name() -> String:
	match(controller):
		TeamController.PLAYER:  return "Player"
		TeamController.AI:  return "AI"
		_:  assert(false, ":(");  return ""


func get_opposed_team() -> Team:
	if self == PLAYER_TEST:
		return ENEMY_TEST
	if self == ENEMY_TEST:
		return PLAYER_TEST
	assert(false)
	return null
