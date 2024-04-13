@tool
class_name ProceduralTree extends Node3D

@export_category("Buttons")
@export var do_check_inputs := false : set = set_do_check_inputs


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func set_do_check_inputs(val : bool):
	if not val: return
	var branch_rewards := generate_reward_objects(%Branches)
	var root_rewards := generate_reward_objects(%Roots)


func generate_reward_objects(container : Node3D) -> Array[ProceduralTreeReward]:
	var rewards := [] as Array[ProceduralTreeReward]
	recursive_generate_reward_objects(container, rewards)
	return rewards


func recursive_generate_reward_objects(container : Node3D, results : Array[ProceduralTreeReward]):
	var rewards := [] as Array[ProceduralTreeReward]
	for i in range(container.get_child_count()):
		var child := container.get_child(i)
		
		if child is RewardSpaceScript:
			var script := child as RewardSpaceScript
			results.append(script.get_reward_object())
		
		# TODO: Add other reward types
		
		if child.get_child_count() > 0:
			recursive_generate_reward_objects(child, results)
	return rewards
