class_name UnitTypeDefs

# This mask is used for unit targeting.
enum UnitType {
	BROCOLLI,
	CROW,
	CROW_EGG,
	TOMATO_PLANT,
	TOMATO_PROJECTILE,
	LETTUCE,
	PUMPKIN,
	CARROT,
	CORN_PLANT,
	POTATO,
}

static func get_unit_name(type : UnitType) -> String:
	match(type):
		UnitType.BROCOLLI:           return "Brocolli"
		UnitType.CROW:               return "Crow"
		UnitType.CROW_EGG:           return "Crow Egg"
		UnitType.TOMATO_PLANT:       return "Tomato Plant"
		UnitType.TOMATO_PROJECTILE:  return "Tomato Projectile"
		UnitType.LETTUCE:            return "Lettuce"
		UnitType.PUMPKIN:            return "Pumpkin"
		UnitType.CARROT:             return "Carrot"
		UnitType.CORN_PLANT:         return "Corn Plant"
		UnitType.POTATO:             return "Potato"
		_:  assert(false); return "UNKNOWN_TYPE"

# Common list of states, not all states used in a given unit class.
enum UnitState {
	UNINITIALIZED,
	INITIALIZE,
	MOVING,
	ATTACKING,
	DEFENDING,
	DEAD
}

static func get_state_name(state : UnitState) -> String:
	match(state):
		UnitState.UNINITIALIZED:  return "Uninitialized"
		UnitState.INITIALIZE:     return "Initialize"
		UnitState.MOVING:         return "Moving"
		UnitState.ATTACKING:      return "Attacking"
		UnitState.DEFENDING:      return "Defending"
		UnitState.DEAD:           return "Dead"
		_:  assert(false); return "UNKNOWN_STATE"

# Used for turning collision with enemies on and off.
enum UnitMoveType {
	GROUND,
	FLYING,
	ROLLING
}

static func get_move_type_name(move_type : UnitMoveType) -> String:
	match(move_type):
		UnitMoveType.GROUND:  return "Ground"
		UnitMoveType.FLYING:  return "Flying"
		UnitMoveType.ROLLING: return "Rolling"
		_:  assert(false); return "UNKNOWN_MOVE_TYPE"

# Which way to flip the art
enum UnitFacing {
	LEFT,
	RIGHT
}

static func get_facing_name(facing : UnitFacing) -> String:
	match(facing):
		UnitFacing.LEFT:   return "Left"
		UnitFacing.RIGHT:  return "Right"
		_:  assert(false); return "UNKNOWN_FACING"

static func get_facing_x(facing : UnitFacing) -> int:
	match(facing):
		UnitFacing.LEFT:   return -1
		UnitFacing.RIGHT:  return 1
		_:  assert(false); return 0

