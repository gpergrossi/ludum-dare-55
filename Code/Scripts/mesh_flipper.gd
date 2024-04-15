@tool
class_name MeshFlipper extends Node3D

@export var input_mesh_instance : MeshInstance3D : set = set_input_mesh_instance
@export var output_mesh_instance : MeshInstance3D : set = set_output_mesh_instance
@export_enum("X", "Y", "Z") var flip_axis := "X" : set = set_flip_axis

var flip_vertex_vec : Vector3
var flip_normal_vec : Vector3


func _ready():
	print("MeshFlipper Running.")


func _set(property, value):
	print("Set " + property + " to " + str(value))
	if property == "input_mesh_instance" or property == "output_mesh_instance" or property == "flip_axis":
		do_mesh_flip()
	return false


func do_mesh_flip():
	if not is_instance_valid(input_mesh_instance): return
	if not is_instance_valid(output_mesh_instance): return
	
	var in_mesh := input_mesh_instance.mesh as ArrayMesh
	var out_mesh := output_mesh_instance.mesh as ArrayMesh
	if not is_instance_valid(in_mesh): return
	if not is_instance_valid(out_mesh): return
	
	print("Flipping " + flip_axis + " on " + str(in_mesh.get_surface_count()) + " surfaces")
	out_mesh.clear_surfaces()
	for i in range(in_mesh.get_surface_count()):
		var new_surface_arrays := flip_surface(in_mesh.surface_get_arrays(i))
		out_mesh.add_surface_from_arrays(in_mesh.surface_get_primitive_type(i), new_surface_arrays)
		
		# Copy materials
		out_mesh.surface_set_material(i, in_mesh.surface_get_material(i).duplicate())
		
		# Copy override materials
		if is_instance_valid(input_mesh_instance.get_surface_override_material(i)):
			output_mesh_instance.set_surface_override_material(i, input_mesh_instance.get_surface_override_material(i).duplicate())


func copy_surface_arrays(surface_arrays : Array) -> Array:
	# Deep copy all arrays to new arrays
	var new_arrays := [] as Array
	new_arrays.resize(Mesh.ARRAY_MAX)
	for i in range(Mesh.ARRAY_MAX):
		if surface_arrays[i] != null:
			new_arrays[i] = surface_arrays[i].duplicate()
	return new_arrays


func flip_surface(surface_arrays : Array) -> Array:
	var new_arrays := copy_surface_arrays(surface_arrays)
	
	if len(new_arrays[Mesh.ARRAY_VERTEX]) > 0:
		var verts := new_arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
		for i in range(len(verts)):
			verts[i] = (flip_vertex_vec * verts[i])
		new_arrays[Mesh.ARRAY_VERTEX] = verts
	
	if len(new_arrays[Mesh.ARRAY_NORMAL]) > 0:
		var normals := new_arrays[Mesh.ARRAY_NORMAL] as PackedVector3Array
		for i in range(len(normals)):
			normals[i] = (flip_normal_vec * normals[i]).normalized()
		new_arrays[Mesh.ARRAY_NORMAL] = normals
	
	return new_arrays


func set_flip_axis(axis : String):
	flip_axis = axis
	match(axis):
		"X": 
			flip_vertex_vec = Vector3(-1, 1, 1)
			flip_normal_vec = Vector3(1, -1, -1)
		"Y": 
			flip_vertex_vec = Vector3(1, 1, -1)
			flip_normal_vec = Vector3(-1, -1, 1)
		"Z": 
			flip_vertex_vec = Vector3(1, -1, 1)
			flip_normal_vec = Vector3(-1, 1, -1)
	do_mesh_flip()


func set_input_mesh_instance(mi : MeshInstance3D):
	input_mesh_instance = mi
	do_mesh_flip()


func set_output_mesh_instance(mi : MeshInstance3D):
	output_mesh_instance = mi
	do_mesh_flip()
