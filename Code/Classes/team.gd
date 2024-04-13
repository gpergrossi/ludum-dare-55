class_name Team extends Resource

var team_name : String   : set = set_team_name
var team_number : int    : set = set_team_number
var team_color : Color   : set = set_team_color
var team_side : int      : set = set_team_side
var _initialized := false

func _init(name : String, number : int, color : Color, side : int):
	team_name = name
	team_number = number
	team_color = color
	team_side = side
	_initialized = true

func set_team_name(val : String):
	# Ignore setter after initialization
	if _initialized: return
	team_name = val

func set_team_number(val : int):
	# Ignore setter after initialization
	if _initialized: return
	team_number = val

func set_team_color(val : Color):
	# Ignore setter after initialization
	if _initialized: return
	team_color = val

func set_team_side(val : int):
	# Ignore setter after initialization
	if _initialized: return
	team_side = val

func get_team_move_x() -> float:
	return -team_side
