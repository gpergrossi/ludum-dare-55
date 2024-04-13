@tool
class_name ProceduralTreeReward extends Object

enum BlendingMode {
	AVERAGE,
	GEOM_AVG,
	LINEAR_ADD,
	LINEAR_SUBTRACT,
	MULTIPLY,
	MAX,
	MIN
}

@export_category("Procedural Tree Reward")
@export var priority := 0          # When multiple Shape3Ds overlap, equal priority shapes will stack (adding / subtracting weight). However, a higher priority reward will overwrite the weight of all lower priority reward.
@export var blending_mode := BlendingMode.AVERAGE
@export var blend_weight := 1.0    # Multiplier on the influence of this reward shape when blending with equal priority reward shapes. Only used by AVERAGE and GEOM_AVG blending modes.

# Overlapping shapes of the same priority blend density values based on their weights at a sampled position.
@export var density := 1.0         # How far apart (world_units ^ -1) should reward points be within this reward shape?
@export var base_value := 1.0      # How much value is given to reward points spawned within this reward shape?
@export var growth_chance := 0.2   # Chance to add extra value to a point
@export var growth_factor := 1.5   # Multiplier to base_value per consecutive successful growth_chance roll.
@export var max_growth := 3        # Puts a max on how many times a growth roll can be made.

var _valid := false


func _init():
	_valid = build()


func is_valid() -> bool:
	return _valid


# Override This
func build() -> bool:
	return false


# Override This
func query_pt(pt : Vector3) -> Vector4:
	# Return nearest point to pt. W component is signed distance.
	var distance := 0.0
	return Vector4(pt.x, pt.y, pt.z, distance)


# Override This
func get_local_weight_factor(_pt : Vector3, _query_result : Vector4) -> float:
	var signed_dist = _query_result.w
	if signed_dist <= 0.0:
		return 1.0  # Everything inside has a weight of 1.
	else:
		return 0.0  # Everything outside has a weight of 0.
