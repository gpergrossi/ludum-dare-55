class_name UnitTargeting extends Node3D

enum Algorithm {
	NEAREST,      # Prefers targets that are the nearest.
	FARTHEST,     # Prefers targets that are the farthest away.
	LOW_HEALTH,   # Prefers targets with lower current health
	HIGH_HEALTH,  # Prefers targets with higher current health
	HIGH_DAMAGE,  # Prefers targets with higher DPS.
	CLUSTER       # Uses splash_radius to find max selection of multiple enemies.
}

enum UnitTargetGroup {
	# UPDATES HERE SHOULD BE MANUALLY COPPIED TO THE export_flags BELOW
	# UPDATES HERE SHOULD BE MANUALLY COPPIED TO THE export_flags BELOW
	# UPDATES HERE SHOULD BE MANUALLY COPPIED TO THE export_flags BELOW
	NONE = 0,
	PROJECTILE = 0,
	
	# UPDATES HERE SHOULD BE MANUALLY COPPIED TO THE export_flags BELOW
	# UPDATES HERE SHOULD BE MANUALLY COPPIED TO THE export_flags BELOW
	# UPDATES HERE SHOULD BE MANUALLY COPPIED TO THE export_flags BELOW
	BROCOLLI = 1,
	CROW = 2,
	TOMATO = 4,
	LETTUCE = 8,
	PUMPKIN = 16,
	CARROT = 32,
	CORN = 64,
	POTATO = 128,
	
	# UPDATES HERE SHOULD BE MANUALLY COPPIED TO THE export_flags BELOW
	# UPDATES HERE SHOULD BE MANUALLY COPPIED TO THE export_flags BELOW
	# UPDATES HERE SHOULD BE MANUALLY COPPIED TO THE export_flags BELOW
	ALL = 255,
	ALL_FLYING = CROW,
	ALL_GROUND = ALL - ALL_FLYING,
}

static func get_group_from_type(type : UnitTypeDefs.UnitType) -> UnitTargetGroup:
	match(type):
		UnitTypeDefs.UnitType.BROCOLLI:     return UnitTargetGroup.BROCOLLI
		UnitTypeDefs.UnitType.CROW:         return UnitTargetGroup.CROW
		UnitTypeDefs.UnitType.TOMATO_PLANT: return UnitTargetGroup.TOMATO
		UnitTypeDefs.UnitType.LETTUCE:      return UnitTargetGroup.LETTUCE
		UnitTypeDefs.UnitType.PUMPKIN:      return UnitTargetGroup.PUMPKIN
		UnitTypeDefs.UnitType.CARROT:       return UnitTargetGroup.CARROT
		UnitTypeDefs.UnitType.CORN_PLANT:   return UnitTargetGroup.CORN
		UnitTypeDefs.UnitType.POTATO:       return UnitTargetGroup.POTATO
		
		UnitTypeDefs.UnitType.CROW_EGG:           return UnitTargetGroup.PROJECTILE
		UnitTypeDefs.UnitType.TOMATO_PROJECTILE:  return UnitTargetGroup.PROJECTILE
		
		_: assert(false, "Could not identify unit type " + str(type)); return UnitTargetGroup.NONE


@export_category("Range")
@export var min_forward_range := 0.0
@export var max_forward_range := 2.0

@export var min_backward_range := 0.0
@export var max_backward_range := 0.0

@export var min_vertical_range := 0.0
@export var max_vertical_range := 2.0

@export var splash_radius := 0.0



@export_category("Target Selection")
@export var target_scan_interval := 0.25
@export var max_targets := 1

@export var target_allies_instead := false

@export var algorithm := Algorithm.NEAREST

@export_flags(
	"Brocolli:1",
	"Crow:2",
	"Tomato:4",
	"Lettuce:8",
	"Pumpkin:16",
	"Carrot:32",
	"Corn:64",
	"Potato:128",
) var targeting_mask : int = UnitTargetGroup.ALL

@export var predicate : Callable = predicate_always

func predicate_always(_target_candidate : UnitBase) -> bool:
	return true



signal target_acquired(new_target : UnitBase, new_target_count : int)
signal target_lost(lost_target : UnitBase, new_target_count : int)
signal target_killed(killed_target : UnitBase, new_target_count : int)



var _current_targets := [] as Array[UnitBase]
@onready var _timer := $Timer as Timer
@onready var _parent_unit := get_parent() as UnitBase


func get_targets() -> Array[UnitBase]:
	return _current_targets

func pause():
	_timer.paused = true

func resume():
	_timer.paused = false

func _ready():
	_current_targets.clear()
	
	_timer.timeout.connect(_on_timer)
	_timer.wait_time = target_scan_interval
	_timer.start()


func _on_timer():
	search_now()
	_try_resume_targeting_timer()


func internal_add_target(new_target : UnitBase):
	if len(_current_targets) < max_targets:
		_current_targets.append(new_target)
		new_target.state_changed.connect(internal_check_target_dead)
		target_acquired.emit(new_target, len(_current_targets))


func internal_after_remove_target(removed_target : UnitBase):
	removed_target.state_changed.disconnect(internal_check_target_dead)
	if is_instance_valid(removed_target) and (removed_target._state == UnitTypeDefs.UnitState.DEAD):
		target_killed.emit(removed_target, len(_current_targets))
	else:
		target_lost.emit(removed_target, len(_current_targets))


func internal_check_target_dead(me : UnitBase, new_state : UnitTypeDefs.UnitState, _old_state : UnitTypeDefs.UnitState):
	if new_state == UnitTypeDefs.UnitState.DEAD:
		var target := me
		var index := _current_targets.find(me)
		if index != -1:
			_current_targets.remove_at(index)
			internal_after_remove_target(target)


func find_targets_by_distance(candidates : Array[UnitBase], max_count := -1, farthest_first := false) -> Array[UnitBase]:
	if _parent_unit == null or not is_instance_valid(_parent_unit): return candidates
	var candidate_distances := [] as PackedFloat32Array
	for unit in candidates:
		if unit == null or not is_instance_valid(unit):
			candidate_distances.append(NAN)
		else:
			var distance_squared := _parent_unit.global_position.distance_squared_to(unit.global_position)
			candidate_distances.append(distance_squared)
	return _find_targets_by_sorted_key(candidates, candidate_distances, max_count, farthest_first)


func find_targets_by_health(candidates : Array[UnitBase], max_count := -1, highest_first := false) -> Array[UnitBase]:
	if _parent_unit == null or not is_instance_valid(_parent_unit): return candidates
	var candidate_healths := [] as PackedFloat32Array
	for unit in candidates:
		if unit == null or not is_instance_valid(unit):
			candidate_healths.append(NAN)
		else:
			candidate_healths.append(unit._health)
	return _find_targets_by_sorted_key(candidates, candidate_healths, max_count, highest_first)


func find_targets_by_damage(candidates : Array[UnitBase], max_count := -1, highest_first := false) -> Array[UnitBase]:
	if _parent_unit == null or not is_instance_valid(_parent_unit): return candidates
	var candidate_damages := [] as PackedFloat32Array
	for unit in candidates:
		if unit == null or not is_instance_valid(unit):
			candidate_damages.append(NAN)
		else:
			candidate_damages.append(unit.damage)
	return _find_targets_by_sorted_key(candidates, candidate_damages, max_count, highest_first)


func find_targets_by_cluster_score(candidates : Array[UnitBase], max_count := -1, highest_first := false) -> Array[UnitBase]:
	if _parent_unit == null or not is_instance_valid(_parent_unit): return candidates
	var candidate_cluster_scores := [] as PackedFloat32Array
	candidate_cluster_scores.resize(len(candidates))
	candidate_cluster_scores.fill(1.0)
	
	var splash_radius_squared := splash_radius * splash_radius
	
	for i in range(len(candidates)-1):
		var candidate_i := candidates[i]
		if candidate_i == null or not is_instance_valid(candidate_i):
			candidate_cluster_scores[i] = NAN
		else:
			for j in range(i+1, len(candidates)):
				var candidate_j := candidates[j]
				if candidate_j == null or not is_instance_valid(candidate_j):
					candidate_cluster_scores[j] = NAN
				elif candidate_i.global_position.distance_squared_to(candidate_j.global_position) < splash_radius_squared:
					candidate_cluster_scores[i] += 1.0
					candidate_cluster_scores[j] += 1.0
	
	return _find_targets_by_sorted_key(candidates, candidate_cluster_scores, max_count, highest_first)


func _find_targets_by_sorted_key(candidates : Array[UnitBase], candidate_keys : PackedFloat32Array, max_count := -1, reverse_sort := false):
	if len(candidates) == 0:
		return [] as Array[UnitBase]
	if max_count == -1: 
		max_count = len(candidates)
	
	# Building an indices array
	var nan_count := 0
	var candidate_indices := [] as Array
	for i in range(len(candidates)):
		candidate_indices.append(i)
		if is_nan(candidate_keys[i]):
			nan_count += 1
	
	# Remove NANs from possible results
	max_count = mini(max_count, len(candidates) - nan_count)
	if max_count == 0: 
		return [] as Array[UnitBase]
	
	# Sort indices by key
	candidate_indices.sort_custom(
		func custom_distance_sort(a, b) -> bool: 
			if reverse_sort:
				# NANs to the end
				if is_nan(candidate_keys[a]): return false
				if is_nan(candidate_keys[b]): return true
				# Larger values first
				return candidate_keys[a] > candidate_keys[b]
			else:
				# NANs to the end
				if is_nan(candidate_keys[a]): return false
				if is_nan(candidate_keys[b]): return true
				# Smaller values first
				return candidate_keys[a] < candidate_keys[b]
	)
	
	# Order results according to sorted indices
	var results := [] as Array[UnitBase]
	for j in range(len(candidate_indices)):
		results.append(candidates[candidate_indices[j]])
		if max_count > 0 and len(results) > max_count:
			break
	
	return results


func get_possible_targets() -> Array[UnitBase]:
	var candidates = [] as Array[UnitBase]
	var group_list := get_tree().get_nodes_in_group("units")
	for unit in group_list:  # Could speed up with 1d tree even.
		if not _current_targets.has(unit) and is_valid_target(unit):
			candidates.append(unit)
	return candidates


func clean_target_list():
	if _parent_unit == null or not is_instance_valid(_parent_unit): return
	var i := 0
	while i < len(_current_targets):
		var unit := _current_targets[i]
		if unit == null:
			_current_targets.remove_at(i)
		elif not is_valid_target(unit):
			var target_removed := _current_targets[i]
			_current_targets.remove_at(i)
			internal_after_remove_target(target_removed)
		else:
			i += 1
	
	_try_resume_targeting_timer()


func _try_resume_targeting_timer():
	if len(_current_targets) < max_targets:
		_timer.wait_time = target_scan_interval + randf() * 0.2
		_timer.start()


func is_valid_target(candidate : UnitBase) -> bool:
	if _parent_unit == null or not is_instance_valid(_parent_unit): return false
	if not is_instance_valid(candidate):
		return false
	
	if candidate._state == UnitTypeDefs.UnitState.DEAD:
		return false
	
	var facing_x := _parent_unit.get_facing_x()
	var dx := candidate.global_position.x - _parent_unit.global_position.x
	var dy := candidate.global_position.y - _parent_unit.global_position.y
	
	# Forward / Backward range
	var dist_forward := dx * facing_x
	if dist_forward > 0:
		if dist_forward < min_forward_range or dist_forward > max_forward_range:
			return false
	else:
		var dist_backward := -dist_forward
		if dist_backward < min_backward_range or dist_backward > max_backward_range:
			return false
	
	# Vertical range
	var dist_vertical := absf(dy)
	if dist_vertical < min_vertical_range:
		return false
	elif dist_vertical > max_vertical_range:
		return false 
	
	# Unit type mask
	if (targeting_mask & UnitTargeting.get_group_from_type(candidate.unit_type)) == 0:
		return false
	
	# Team
	if target_allies_instead and candidate.team != _parent_unit.team:
		return false  # Dont target enemy team
	elif not target_allies_instead and candidate.team == _parent_unit.team:
		return false  # Dont target same team
	
	# Generic predicate function
	if not predicate.call(candidate):
		return false
	
	return true


func search_now():
	if _parent_unit == null or not is_instance_valid(_parent_unit): return
	clean_target_list()
	
	var max_target_count := max_targets - len(_current_targets)
	var new_targets := [] as Array[UnitBase]
	
	if max_target_count > 0:
		var candidates := get_possible_targets();
		match(algorithm):
			Algorithm.NEAREST:      new_targets = find_targets_by_distance(candidates, max_targets)
			Algorithm.FARTHEST:     new_targets = find_targets_by_distance(candidates, max_targets, true)
			Algorithm.LOW_HEALTH:   new_targets = find_targets_by_health(candidates, max_targets)
			Algorithm.HIGH_HEALTH:  new_targets = find_targets_by_health(candidates, max_targets, true)
			Algorithm.HIGH_DAMAGE:  new_targets = find_targets_by_damage(candidates, max_targets, true)
			Algorithm.CLUSTER:      new_targets = find_targets_by_cluster_score(candidates, max_targets)
	
	for target in new_targets:
		internal_add_target(target)
