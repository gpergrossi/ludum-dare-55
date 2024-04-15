@tool
class_name ConcaveMeshRipper extends CollisionShape3D

@export var meshInstance : MeshInstance3D

@export var rip_mesh := false : set = _do_rip_mesh


func _ready():
	var coll := shape as ConcavePolygonShape3D
	if Engine.is_editor_hint():
		_do_rip_mesh(true)
	else:
		coll.set_faces([] as PackedVector3Array)


func _do_rip_mesh(val : bool):
	if not val: return
	var coll := shape as ConcavePolygonShape3D
	
	var arrays := meshInstance.mesh.surface_get_arrays(0)
	var vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	var indices := arrays[Mesh.ARRAY_INDEX] as PackedInt32Array
	
	print("Ripping quad vertices...")
	print("Found " + str(len(indices)) + " indices referencing up to " + str(len(vertices)) + " vertices.")
	var triangle_vertices = [] as PackedVector3Array
	for i in range(0, len(indices), 3):
		triangle_vertices.append(transform_vertex(vertices[indices[i+0]]))
		triangle_vertices.append(transform_vertex(vertices[indices[i+1]]))
		triangle_vertices.append(transform_vertex(vertices[indices[i+2]]))
	
	print("Completed with " + str(len(triangle_vertices)) + " vertices.")
	
	coll.set_faces(triangle_vertices)


func transform_vertex(in_vec : Vector3) -> Vector3:
	var out_vec := in_vec * 0.01
	out_vec = out_vec.rotated(Vector3.RIGHT, 0.5 * PI)
	return out_vec

