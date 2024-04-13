class_name ProceduralTreeShapeReward extends ProceduralTreeReward

var _shape : ShapeCast3D
var _query_func : Callable

func _init(shape : ShapeCast3D):
	_shape = shape
	super._init()   # Super class attempts to build, do this last.


func build() -> bool:
	if _shape.shape is BoxShape3D:
		var box := _shape.shape as BoxShape3D
		var box_origin := _shape.global_position + _shape.target_position * _shape.global_basis
		var inv_xform := Transform3D(_shape.global_basis.inverse(), -box_origin)
		_query_func = func(query_pt : Vector3) -> Vector4:
			return query_box(query_pt, inv_xform, box.size * 0.5, _shape.margin + box.margin)
		return true
	
	elif _shape.shape is SphereShape3D:
		var sphere := _shape.shape as SphereShape3D
		var sphere_origin := _shape.global_position + _shape.target_position * _shape.global_basis
		var inv_xform := Transform3D(_shape.global_basis.inverse(), -sphere_origin)
		_query_func = func(query_pt : Vector3) -> Vector4:
			return query_sphere(query_pt, inv_xform, sphere.radius, _shape.margin + sphere.margin)
		return true
	
	elif _shape.shape is WorldBoundaryShape3D:
		var boundary := _shape.shape as WorldBoundaryShape3D
		var plane := boundary.plane.normalized()
		var boundary_origin := _shape.global_position + (_shape.target_position + plane.get_center()) * _shape.global_basis
		var inv_xform := Transform3D(_shape.global_basis.inverse(), -boundary_origin)
		_query_func = func(query_pt : Vector3) -> Vector4:
			return query_world_boundary(query_pt, inv_xform, plane.normal, _shape.margin + boundary.margin)
		return true
	
	else:
		printerr("RewardShape does not support type " + str(typeof(_shape.shape)) + ".")
		return false


func query_pt(pt : Vector3) -> Vector4:
	return _query_func.call(pt)


func get_local_weight_factor(_pt : Vector3, query_result : Vector4) -> float:
	var signed_dist = query_result.w
	if signed_dist <= 0.0:
		return 1.0  # Everything inside has a weight of 1.
	else:
		return 0.0  # Everything outside has a weight of 0.


static func query_box(query_pt : Vector3, inv_xform : Transform3D, extent : Vector3, margin : float) -> Vector4:
	query_pt = inv_xform * query_pt
	
	var margin_vec := Vector3(margin, margin, margin)
	var min_pt := -extent - margin_vec
	var max_pt := extent + margin_vec
	var x_sign := _get_dimension_sign(query_pt.x, min_pt.x, max_pt.x)
	var y_sign := _get_dimension_sign(query_pt.y, min_pt.y, max_pt.y)
	var z_sign := _get_dimension_sign(query_pt.z, min_pt.z, max_pt.z)
	
	var corner_pt := (extent + margin_vec) * Vector3(x_sign, y_sign, z_sign)
	var out_pt := query_pt
	if x_sign != 0: out_pt.x = corner_pt.x
	if y_sign != 0: out_pt.y = corner_pt.y
	if z_sign != 0: out_pt.z = corner_pt.z
	
	var signed_dist := query_pt.distance_to(out_pt)
	if is_zero_approx(signed_dist):
		# Inside the box, compute negative distance instead
		var x_signed_dist := _get_dimension_signed_dist(query_pt.x, min_pt.x, max_pt.x)
		var y_signed_dist := _get_dimension_signed_dist(query_pt.y, min_pt.y, max_pt.y)
		var z_signed_dist := _get_dimension_signed_dist(query_pt.z, min_pt.z, max_pt.z)
		var min_dim := minf(minf(-x_signed_dist, -y_signed_dist), -z_signed_dist)
		signed_dist = -min_dim
	
	return Vector4(out_pt.x, out_pt.y, out_pt.z, signed_dist)


static func _get_dimension_sign(value : float, minBound : float, maxBound : float) -> int:
	if value < minBound:
		return -1
	if value > maxBound:
		return 1
	return 0


static func _get_dimension_signed_dist(value : float, minBound : float, maxBound : float) -> int:
	if value < minBound:
		return value - minBound
	if value > maxBound:
		return value - maxBound
	return -minf(value - minBound, maxBound - value)


static func query_sphere(query_pt : Vector3, inv_xform : Transform3D, radius : float, margin : float) -> Vector4:
	query_pt = inv_xform * query_pt
	radius += margin
	var dir := query_pt.normalized()
	var out_pt := dir * radius
	var signed_dist := query_pt.length() - radius
	return Vector4(out_pt.x, out_pt.y, out_pt.z, signed_dist)


static func query_world_boundary(query_pt : Vector3, inv_xform : Transform3D, normal : Vector3, margin : float) -> Vector4:
	query_pt = inv_xform * query_pt
	var dot := query_pt.dot(normal)
	var out_pt := query_pt - (normal * dot)
	var signed_dist = dot
	return Vector4(out_pt.x, out_pt.y, out_pt.z, signed_dist)
