@tool
class_name StuffSpreader extends Node3D

const MAX_FAILS := 500
const MAX_RAYS_PER_CYCLE := 50

@export_category("Spawning")
@export var spawnables : Array[PackedScene]
@export var names : Array[String]
@export var rarity_curve := 1.0   # The weight of each spawnable in the list will be multiplied by pow(rarity_curve, index).
@export var spawn_seed : int

@export_category("Spawn Amount")
@export var amount_min : int = 3
@export var amount_max : int = 7

@export_category("Spawn Position")
@export var throw_vector := Vector3.DOWN
@export var spread_distance : float = 0.1      # Margin around each spawned object.

@export_category("Spawn Rotation")
@export var min_angle_y : int = -180
@export var max_angle_y : int = 180
@export var match_normal := true
@export var weaken_normal := 0.0
@export var discard_angle := 90.0

@export_category("Spawn Size")
@export var base_size := 1.0
@export var grow_chance := 0.2
@export var grow_factor := 1.5
@export var max_size := 10.0

@export_category("Buttons")
@export var do_spawn := false : set = set_do_spawn

@onready var _spawn_parent := %SpawnParent as Node3D

var _random : RandomNumberGenerator
var _avoid_spheres : Array[CollisionShape3D]
var _target_count := 0
var _fail_count := 0
var _normalized_spawnable_odds : PackedFloat32Array
var _spawning_done := true
var _spawned_object_count := 0

# Called when the node enters the scene tree for the first time.
func _ready():
	_random = RandomNumberGenerator.new()


func _physics_process(_delta : float):
	if _spawning_done: return
	
	if _spawned_object_count < _target_count and _fail_count < MAX_FAILS:
		var rays_this_cycle := 0
		while rays_this_cycle < MAX_RAYS_PER_CYCLE and _spawned_object_count < _target_count and _fail_count < MAX_FAILS:
			rays_this_cycle += 1
			var space_state := get_world_3d().direct_space_state as PhysicsDirectSpaceState3D
			var success := try_spawn_shape(find_child_collision_shape(self), space_state)
			if not success:
				_fail_count += 1
			else:
				_spawned_object_count += 1
				_fail_count = 0
	else:
		if not _spawning_done:
			_spawning_done = true
			if _fail_count == MAX_FAILS:
				print("Reached max fail count.")
			else:
				print("Placed all intended instances.")


func set_do_spawn(val : bool):
	if not val: return
	cleanup()
	spawn_stuff()


func cleanup():
	for i in range(_spawn_parent.get_child_count()):
		var child = _spawn_parent.get_child(i)
		child.name = "GARBAGE" + str(randi_range(0, 999999999))
		child.queue_free()
	_spawned_object_count = 0


func spawn_stuff():
	var collision := find_child_collision_shape(self)
	if not is_instance_valid(collision) or not is_instance_valid(collision.shape):
		printerr("No valid child SpawnArea or collision shape in StuffSpreader " + name + "!")
		return
	
	# Clear the seed on our RNG object
	_random.seed = spawn_seed
	
	_avoid_spheres = get_all_avoid_spheres(collision)
	_target_count = _random.randi_range(amount_min, amount_max)
	_fail_count = 0
	
	# Determine normalized (all total to 1.0) odds for each spawnable
	_normalized_spawnable_odds = [] as PackedFloat32Array
	var total := 0.0
	var rarity := 1.0
	for i in range(len(spawnables)):
		_normalized_spawnable_odds.append(rarity)
		total += rarity
		rarity *= rarity_curve
	for i in range(len(spawnables)):
		_normalized_spawnable_odds[i] /= total
		print("Odds of " + str(spawnables[i]) + " is " + str(_normalized_spawnable_odds[i]))
		
	_spawning_done = false
 

func try_spawn_shape(collider : CollisionShape3D, space_state : PhysicsDirectSpaceState3D) -> bool:
	if not is_instance_valid(collider):
		printerr("Found missing SpawnArea in StuffSpreader " + name + "!")
		return false
	elif collider.shape is BoxShape3D:
		return try_spawn_box(collider.global_transform, collider.shape as BoxShape3D, space_state)
	elif collider.shape is SphereShape3D:
		return try_spawn_sphere(collider.global_transform, collider.shape as SphereShape3D, space_state)
	else:
		printerr("Found unsupported SpawnArea shape " + str(typeof(collider.shape)) + " in StuffSpreader " + name + "!")
		return false


func try_spawn_box(spawn_transform : Transform3D, spawn_box : BoxShape3D, space_state : PhysicsDirectSpaceState3D):
	# Find a random location in the box
	var x := (_random.randf() - 0.5) * spawn_box.size.x
	var y := (_random.randf() - 0.5) * spawn_box.size.y
	var z := (_random.randf() - 0.5) * spawn_box.size.z
	var location := Vector3(x, y, z)
	location = spawn_transform * location
	return try_spawn_location(location, space_state)


func try_spawn_sphere(spawn_transform : Transform3D, spawn_sphere : SphereShape3D, space_state : PhysicsDirectSpaceState3D) -> bool:
	# Find a random location in the box
	var location := random_point_in_sphere() * spawn_sphere.radius
	location = spawn_transform * location
	return try_spawn_location(location, space_state)


func try_spawn_location(location : Vector3, space_state : PhysicsDirectSpaceState3D) -> bool:
	#print("Trying to spawn starting at " + str(location) + ".")
	
	# Choose a spawnable
	var spawnable_roll := _random.randf()
	print("Rolled " + str(spawnable_roll))
	var selected : PackedScene = null
	var selected_name := ""
	for i in range(len(spawnables)):
		if spawnable_roll >= 0 and spawnable_roll <= _normalized_spawnable_odds[i]:
			selected = spawnables[i]
			if i < len(names):
				selected_name =  names[i]
		spawnable_roll -= _normalized_spawnable_odds[i]
	if selected == null:
		printerr("No spawnables roll result!")
		return false
	
	# Instantiate one
	var instance := selected.instantiate() as Node3D
	instance.name = selected_name + " (" + str(_spawn_parent.get_child_count()) + ")"
	_spawn_parent.add_child(instance)
	instance.owner = owner
	
	# Check if it fits
	var success := try_spawn_location_instance(location, instance, space_state)
	if not success:
		_spawn_parent.remove_child(instance)
		instance.queue_free()
	return success


func try_spawn_location_instance(location : Vector3, instance : Node3D, space_state : PhysicsDirectSpaceState3D) -> bool:
	# Choose size
	var size := base_size
	while size < max_size and _random.randf() <= grow_chance:
		size *= grow_factor
	size = minf(size, max_size)
	
	# Raycast to find a position on the ground / wall
	var max_throw_dist := 0.0
	var spawn_aabb := get_transformed_aabb(find_child_collision_shape(self))
	max_throw_dist = spawn_aabb.size.length()
	if not throw_vector.is_normalized():
		throw_vector = throw_vector.normalized()
	var query := PhysicsRayQueryParameters3D.create(location, location + throw_vector * max_throw_dist)
	var result := space_state.intersect_ray(query)
	
	if result.is_empty():
		#print("Discarded due to ray cast miss!")
		return false
	
	var _position := result["position"] as Vector3
	var _normal := result["normal"] as Vector3
	
	# Discard based on normal
	if _normal.angle_to(-throw_vector) > (discard_angle * PI / 180.0):
		#print("Discarded due to normal angle!")
		return false
	
	# Set instance location
	instance.global_position = _position
	
	# Set instance rotation to normal
	if match_normal:
		var cross := _normal.cross(-throw_vector)
		if cross.is_zero_approx():
			cross = Vector3(-throw_vector.y, -throw_vector.z, -throw_vector.x)
		cross = cross.normalized()
		instance.basis = instance.basis.rotated(cross, (-throw_vector).signed_angle_to(_normal, cross) * (1.0 - weaken_normal))
	
	# Roll rotation angle
	var angle_y := _random.randf_range(min_angle_y, max_angle_y)
	instance.basis = instance.basis.rotated(instance.basis.y, angle_y * PI / 180.0)
	
	# Set instance size
	instance.basis = instance.basis.scaled(Vector3(size, size, size))
	
	# Get new spawn sphere
	var new_sphere := find_child_sphere_collider(instance)
	var new_sphere_radius := (new_sphere.shape as SphereShape3D).radius * size
	
	# Check for intersection with existing spheres
	var intersect := false
	for sphere in _avoid_spheres:
		var delta := new_sphere.global_position - sphere.global_position
		var radius := sphere.global_basis.get_scale().x * (sphere.shape as SphereShape3D).radius
		if delta.length() <= (radius + new_sphere_radius + spread_distance):
			intersect = true
			break
	
	if not intersect:
		# Check for intersection with recently spawned spheres
		for sphere in find_avoid_spheres(self):
			if sphere != new_sphere:
				var delta := new_sphere.global_position - sphere.global_position
				var radius := sphere.global_basis.get_scale().x * (sphere.shape as SphereShape3D).radius
				if delta.length() <= (radius + new_sphere_radius + spread_distance):
					intersect = true
					break
	
	if not intersect:
		# Found a valid location!
		return true
	else:
		#print("Discarded due to intersection with existing spawnable!")
		return false


func random_point_in_circle() -> Vector2:
	var x := (_random.randf() - 0.5) * 2.0
	var y := (_random.randf() - 0.5) * 2.0
	while (x * x + y * y) > 1.0:
		x = (_random.randf() - 0.5) * 2.0
		y = (_random.randf() - 0.5) * 2.0
	return Vector2(x, y)
	

func random_point_in_sphere() -> Vector3:
	var x := (_random.randf() - 0.5) * 2.0
	var y := (_random.randf() - 0.5) * 2.0
	var z := (_random.randf() - 0.5) * 2.0
	while (x * x + y * y + z * z) > 1.0:
		x = (_random.randf() - 0.5) * 2.0
		y = (_random.randf() - 0.5) * 2.0
		z = (_random.randf() - 0.5) * 2.0
	return Vector3(x, y, z)
	

func get_all_avoid_spheres(spawn_area_collider : CollisionShape3D) -> Array[CollisionShape3D]:
	var avoid_spheres := [] as Array[CollisionShape3D]
	var other_spreaders := get_tree().get_nodes_in_group("stuff_spreaders")
	for other in other_spreaders:
		if other == self: continue
		for sphere in find_avoid_spheres(other):
			if might_intersect(sphere, spawn_area_collider):
				avoid_spheres.append(sphere)
	return avoid_spheres


func find_avoid_spheres(node : Node3D) -> Array[CollisionShape3D]:
	var avoid_spheres := [] as Array[CollisionShape3D]
	var spawn_parent := node.find_child("SpawnParent") as Node3D
	if not is_instance_valid(spawn_parent):
		return avoid_spheres
	
	for i in range(spawn_parent.get_child_count()):
		var child := spawn_parent.get_child(i)
		if not child is Node3D: continue
		if child.name.begins_with("GARBAGE"): continue
		
		var collider := find_spawn_radius_collider(child)
		if is_instance_valid(collider):
			avoid_spheres.append(collider)
		else:
			printerr("Found spawnable " + child.name + " with missing or incorrectly-defined SpawnRadius shape.")
	
	return avoid_spheres


func find_spawn_radius_collider(node : Node3D) -> CollisionShape3D:
	var collider := find_child_sphere_collider(node)
	if is_instance_valid(collider):
		return collider
	return null


func might_intersect(a : CollisionShape3D, b : CollisionShape3D) -> bool:
	var aabb_a = get_transformed_aabb(a)
	var aabb_b = get_transformed_aabb(b)
	return aabb_a.intersects(aabb_b)


func get_transformed_aabb(collider : CollisionShape3D) -> AABB:
	var ext := Vector3.ZERO
	if collider.shape is SphereShape3D:
		ext = Vector3(1,1,1) * (collider.shape as SphereShape3D).radius
	elif collider.shape is BoxShape3D:
		ext = (collider.shape as BoxShape3D).size * 0.5
	else:
		printerr("Spawn Area collision shape type not supported: " + str(typeof(collider.shape)) + " on StuffSpreader " + name + ".")
		return AABB(collider.global_position, Vector3.ZERO)
	
	if ext.is_zero_approx():
		return AABB(collider.global_position, Vector3.ZERO)
	
	var corners := [] as PackedVector3Array
	corners.append(Vector3(1,1,1) * ext)
	corners.append(Vector3(-1,1,1) * ext)
	corners.append(Vector3(1,-1,1) * ext)
	corners.append(Vector3(-1,-1,1) * ext)
	corners.append(Vector3(1,-1,-1) * ext)
	corners.append(Vector3(-1,-1,-1) * ext)
	var minX := INF; var maxX := -INF;
	var minY := INF; var maxY := -INF;
	var minZ := INF; var maxZ := -INF;
	for i in range(len(corners)):
		corners[i] = collider.global_transform * corners[i]
		minX = minf(minX, corners[i].x)
		maxX = maxf(maxX, corners[i].x)
		minY = minf(minY, corners[i].y)
		maxY = maxf(maxY, corners[i].y)
		minZ = minf(minZ, corners[i].z)
		maxZ = maxf(maxZ, corners[i].z)
	var minPt := Vector3(minX, minY, minZ)
	var maxPt := Vector3(maxX, maxY, maxZ)
	return AABB(minPt, maxPt - minPt)
	

func find_child_sphere_collider(node : Node) -> CollisionShape3D:
	var area := node.find_child("SpawnRadius") as Area3D
	if is_instance_valid(area):
		for i in range(area.get_child_count()):
			var shape := area.get_child(i) as CollisionShape3D
			if is_instance_valid(shape) and (shape.shape is SphereShape3D):
				return shape
	return null


func find_child_collision_shape(node : Node3D) -> CollisionShape3D:
	for i in range(node.get_child_count()):
		var area := node.get_child(i) as Area3D
		if is_instance_valid(area):
			for j in range(area.get_child_count()):
				var shape := area.get_child(i) as CollisionShape3D
				if is_instance_valid(shape):
					return shape
	return null
