class_name CameraFollow extends Camera3D

@export var follow_target : Node3D


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta : float):
	if is_instance_valid(follow_target):
		var lerp_amount := 1.0 - pow(0.01, delta)
		global_position = global_position.lerp(follow_target.global_position, lerp_amount)
		global_basis = Basis(global_basis.get_rotation_quaternion().slerp(follow_target.global_basis.get_rotation_quaternion(), lerp_amount))
