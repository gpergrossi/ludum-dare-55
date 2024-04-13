class_name RewardSpaceScript extends ShapeCast3D

var _tree_reward : ProceduralTreeShapeReward

# Called when the node enters the scene tree for the first time.
func _ready():
	build_tree_reward_object()


func get_reward_object() -> ProceduralTreeReward:
	return _tree_reward


func build_tree_reward_object():
	_tree_reward = ProceduralTreeShapeReward.new(self)
