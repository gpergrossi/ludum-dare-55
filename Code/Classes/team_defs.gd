class_name TeamDefs

static var Player := Team.new("Player", 0, Color.BLUE, -1)
static var Enemy := Team.new("Enemy", 0, Color.DARK_RED, 1)

static func FromName(name : String) -> Team:
	match(name):
		"Player": return Player
		"Enemy": return Enemy
	assert(false, "Unknown team name \"" + name + "\"!")
	return null

static func get_opposed_team(team : Team) -> Team:
	if (team == Player): return Enemy;
	if (team == Enemy): return Player;
	return null;
