@tool
class_name TerrainGenerator extends Node3D

@export var profile_curve : Curve       : set = _set_profile_curve
@export var foreground_z_curve : Curve  : set = _set_foreground_z_curve
@export var lane_z_curve : Curve        : set = _set_lane_z_curve
@export var background_z_curve : Curve  : set = _set_background_z_curve

@export var width := 50               : set = _set_width
@export var height := 20              : set = _set_height
@export var flat_margins := 5         : set = _set_flat_margins
@export var lane_depth := 2           : set = _set_lane_depth
@export var foreground_depth := 10    : set = _set_foreground_depth
@export var background_depth := 10    : set = _set_background_depth

@export var resolution := 1    : set = _set_resolution

@onready var terrain_mesh_instance := %Terrain as MeshInstance3D
@onready var collision_heightmap := %CollisionHeightmap as CollisionShape3D
@onready var material_lane := preload("res://Scenes/Terrain/terrain_gen_lane.material") as StandardMaterial3D
@onready var material_ground := preload("res://Scenes/Terrain/terrain_gen_ground.material") as StandardMaterial3D

var _dirty = true

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if _dirty:
		rebuild_mesh()
		_dirty = false


func get_height(x : float) -> float:
	var total_width := width + 2 * flat_margins
	x += 0.5 * total_width
	if x < flat_margins:
		return 0.0
	elif x > total_width - flat_margins:
		return 0.0
	else:
		return profile_curve.sample_baked(clampf((x - flat_margins) / width, 0.0, 1.0)) * height


func get_slope(x : float, epsilon := 0.1) -> float:
	return (get_height(x + epsilon) - get_height(x - epsilon)) / (2 * epsilon)





func rebuild_mesh():
	var array_mesh := terrain_mesh_instance.mesh as ArrayMesh
	array_mesh.clear_surfaces()
	
	generate_mesh_background(array_mesh)
	generate_mesh_lane(array_mesh)
	generate_mesh_foreground(array_mesh)
	
	generate_heightmap_collisions()


func generate_mesh_background(array_mesh : ArrayMesh):
	var divs := Vector2i(width + 2 * flat_margins, background_depth + flat_margins) * resolution
	var index_begin := Vector2i(flat_margins, flat_margins) * resolution
	var index_end := Vector2i(divs.x - flat_margins * resolution, divs.y)
	var offset := Vector3(-0.5 * width, 0.0, -0.5 * lane_depth - background_depth) - Vector3(flat_margins, 0, flat_margins)
	var size := Vector3(width + 2 * flat_margins, height, background_depth + flat_margins)
	generate_mesh_section(array_mesh, background_z_curve, divs, offset, size, material_ground, "background", index_begin, index_end)


func generate_mesh_lane(array_mesh : ArrayMesh):
	var divs := Vector2i(width + 2 * flat_margins, lane_depth) * resolution
	var index_begin := Vector2i(flat_margins * resolution, 0)
	var index_end := Vector2i(divs.x - flat_margins * resolution, divs.y)
	var offset := Vector3(-0.5 * width, 0.0, -0.5 * lane_depth) - Vector3(flat_margins, 0, 0)
	var size := Vector3(width + 2 * flat_margins, height, lane_depth)
	generate_mesh_section(array_mesh, lane_z_curve, divs, offset, size, material_lane, "lane", index_begin, index_end)


func generate_mesh_foreground(array_mesh : ArrayMesh):
	var divs := Vector2i(width + 2 * flat_margins, foreground_depth + flat_margins) * resolution
	var index_begin := Vector2i(flat_margins * resolution, 0)
	var index_end := Vector2i(divs.x - flat_margins * resolution, divs.y - flat_margins * resolution)
	var offset := Vector3(-0.5 * width, 0.0, 0.5 * lane_depth) - Vector3(flat_margins, 0, 0)
	var size := Vector3(width + 2 * flat_margins, height, foreground_depth + flat_margins)
	generate_mesh_section(array_mesh, foreground_z_curve, divs, offset, size, material_ground, "foreground", index_begin, index_end)


func generate_mesh_section(array_mesh : ArrayMesh, z_curve : Curve, divs : Vector2i, offset : Vector3, size : Vector3, material : Material, surface_name : String, index_begin : Vector2i, index_end : Vector2i):
	var vertices := [] as PackedVector3Array
	var normals := [] as PackedVector3Array
	var uvs := [] as PackedVector2Array
	var indices := [] as PackedInt32Array
	var curr_index := 0
	
	for z in range(divs.y + 1):
		var v := float(z) / divs.y
		var curve_v := clampf(float(z - index_begin.y) / float(index_end.y - index_begin.y), 0.0, 1.0)
		var height_multiplier_z_curve := z_curve.sample_baked(curve_v)
		
		for x in range(divs.x + 1):
			var u := float(x) / divs.x
			var curve_u := clampf(float(x - index_begin.x) / float(index_end.x - index_begin.x), 0.0, 1.0)
			
			uvs.append(Vector2(u, v))
			
			var profile_y := profile_curve.sample_baked(curve_u)
			var world_x := size.x * u + offset.x
			var world_z := size.z * v + offset.z
			var world_y := size.y * height_multiplier_z_curve * profile_y + offset.y
			vertices.append(Vector3(world_x, world_y, world_z))
			
			var u_left := maxf(0.0, curve_u - 0.01)
			var u_right := minf(1.0, curve_u + 0.01)
			var world_y_left := profile_curve.sample_baked(u_left) * size.y * height_multiplier_z_curve
			var world_y_right := profile_curve.sample_baked(u_right) * size.y * height_multiplier_z_curve
			var slope_dydx := (world_y_right - world_y_left) / ((u_right - u_left) * size.x * (float(index_end.x - index_begin.x) / divs.x))
			var normal_dydx := Vector2(1.0, slope_dydx).normalized().rotated(0.5 * PI)
			var angle_dydx := Vector2.UP.angle_to(normal_dydx)
			
			var v_forward := maxf(0.0, curve_v - 0.01)
			var v_backward := minf(1.0, curve_v + 0.01)
			var world_y_foreward := z_curve.sample_baked(v_forward) * size.y * profile_y
			var world_y_backward := z_curve.sample_baked(v_backward) * size.y * profile_y
			var slope_dydz := (world_y_backward - world_y_foreward) / ((v_backward - v_forward) * size.z * (float(index_end.y - index_begin.y) / divs.y))
			var normal_dydz := Vector2(1.0, slope_dydz).normalized().rotated(0.5 * PI)
			var angle_dydz := Vector2.UP.angle_to(normal_dydz)
			
			normals.append(Vector3.UP.rotated(Vector3.RIGHT, angle_dydz).rotated(Vector3.BACK, angle_dydx))
			
			if z > 0 and x > 0:
				var scansize := divs.x + 1
				indices.append(curr_index)
				indices.append(curr_index - scansize - 1)
				indices.append(curr_index - scansize)
				
				indices.append(curr_index - 1)
				indices.append(curr_index - scansize - 1)
				indices.append(curr_index)
			
			curr_index += 1
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	
	var surface_index = array_mesh.get_surface_count()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	array_mesh.surface_set_name(surface_index, surface_name)
	array_mesh.surface_set_material(surface_index, material)


func generate_heightmap_collisions():
	var margin_divs := flat_margins * resolution
	var x_divs := width * resolution + 2 * margin_divs
	var z_divs_lane := lane_depth * resolution
	var z_divs_foreground := foreground_depth * resolution
	var z_divs_background := background_depth * resolution
	
	var heightmap := collision_heightmap.shape as HeightMapShape3D
	var z_divs_total := z_divs_lane + z_divs_foreground + z_divs_background + 2 * margin_divs
	heightmap.map_width = x_divs + 1
	heightmap.map_depth = z_divs_total + 1
	heightmap.map_data.resize(heightmap.map_width * heightmap.map_depth)
	
	var curr_index := 0
	for z in range(z_divs_total + 1):
		var height_multiplier_z_curve := 0.0
		var sample_z := z
		
		sample_z -= margin_divs
		
		if sample_z >= 0 and sample_z < z_divs_background:
			var v = float(sample_z) / z_divs_background
			height_multiplier_z_curve = background_z_curve.sample_baked(v)
		sample_z -= z_divs_background
		
		if sample_z >= 0 and sample_z < z_divs_lane:
			var v = float(sample_z) / z_divs_lane
			height_multiplier_z_curve = lane_z_curve.sample_baked(v)
		sample_z -= z_divs_lane
		
		if sample_z >= 0 and sample_z < z_divs_foreground:
			var v = float(sample_z) / z_divs_foreground
			height_multiplier_z_curve = foreground_z_curve.sample_baked(v)
		sample_z -= z_divs_foreground
		
		for x in range(x_divs + 1):
			var u := clampf(float(x - margin_divs) / (x_divs - 2 * margin_divs), 0.0, 1.0)
			var profile_y := profile_curve.sample_baked(u)
			var world_y := height * height_multiplier_z_curve * profile_y
			heightmap.map_data[curr_index] = world_y * resolution
			curr_index += 1
	
	var s := 1.0 / resolution
	collision_heightmap.scale = Vector3(s, s, s)
	collision_heightmap.position = Vector3(0, 0, (background_depth + lane_depth + foreground_depth) * 0.5 - background_depth - lane_depth * 0.5)













##############################################################################################
##############################################################################################
##############################################################################################

func _set_profile_curve(val : Curve):
	if profile_curve == val:
		return  # No change, actually.
	
	# Unregister curve change listeners
	if is_instance_valid(profile_curve):
		profile_curve.changed.disconnect(on_curve_change)
		profile_curve.range_changed.disconnect(on_curve_change)
	
	profile_curve = val
	
	# Register curve change listeners
	if is_instance_valid(profile_curve):
		profile_curve.changed.connect(on_curve_change)
		profile_curve.range_changed.connect(on_curve_change)

func _set_foreground_z_curve(val : Curve):
	if foreground_z_curve == val:
		return  # No change, actually.
	
	# Unregister curve change listeners
	if is_instance_valid(foreground_z_curve):
		foreground_z_curve.changed.disconnect(on_curve_change)
		foreground_z_curve.range_changed.disconnect(on_curve_change)
	
	foreground_z_curve = val
	
	# Register curve change listeners
	if is_instance_valid(foreground_z_curve):
		foreground_z_curve.changed.connect(on_curve_change)
		foreground_z_curve.range_changed.connect(on_curve_change)


func _set_lane_z_curve(val : Curve):
	if lane_z_curve == val:
		return  # No change, actually.
	
	# Unregister curve change listeners
	if is_instance_valid(lane_z_curve):
		lane_z_curve.changed.disconnect(on_curve_change)
		lane_z_curve.range_changed.disconnect(on_curve_change)
	
	lane_z_curve = val
	
	# Register curve change listeners
	if is_instance_valid(lane_z_curve):
		lane_z_curve.changed.connect(on_curve_change)
		lane_z_curve.range_changed.connect(on_curve_change)


func _set_background_z_curve(val : Curve):
	if background_z_curve == val:
		return  # No change, actually.
	
	# Unregister curve change listeners
	if is_instance_valid(background_z_curve):
		background_z_curve.changed.disconnect(on_curve_change)
		background_z_curve.range_changed.disconnect(on_curve_change)
	
	background_z_curve = val
	
	# Register curve change listeners
	if is_instance_valid(background_z_curve):
		background_z_curve.changed.connect(on_curve_change)
		background_z_curve.range_changed.connect(on_curve_change)

func on_curve_change():
	_dirty = true

func _set_width(val : int):
	width = val
	_dirty = true
	
func _set_height(val : int):
	height = val
	_dirty = true

func _set_flat_margins(val : int):
	flat_margins = val
	_dirty = true

func _set_lane_depth(val : int):
	lane_depth = val
	_dirty = true

func _set_foreground_depth(val : int):
	foreground_depth = val
	_dirty = true
	
func _set_background_depth(val : int):
	background_depth = val
	_dirty = true

func _set_resolution(val : int):
	resolution = val
	_dirty = true
