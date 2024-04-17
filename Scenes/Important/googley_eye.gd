@tool
class_name GoogleyEye extends Node3D

@export var radius_white := 0.25 : set = set_radius_white
@export var radius_black := 0.09 : set = set_radius_black

@export var spring_const := 5.0
@export var mass := 2.0
@export var dampening := 0.34

@export var brow_visible := false : set = set_brow_visible
@export var brow_tilt := 8.9 : set = set_brow_tilt
@export var brow_height := 0.25 : set = set_brow_height
@export var brow_thickness := 0.05 : set = set_brow_thickness

@onready var brow_front := %Brow as MeshInstance3D
@onready var brow_back := %Brow2 as MeshInstance3D
@onready var black_part_front := %BlackPart as MeshInstance3D
@onready var black_part_back  := %BlackPart2 as MeshInstance3D
@onready var pupils  := %Pupils as Node3D
@onready var white_part := %WhitePart as MeshInstance3D



var pupil_vel := Vector2.ZERO
var pupil_pos := Vector2.ZERO

var prev_pupil_pos := Vector3.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	# Make sure all appearance updates have been made
	set_radius_white(radius_white)
	set_radius_black(radius_black)
	set_brow_visible(brow_visible)
	set_brow_tilt(brow_tilt)
	set_brow_height(brow_height)
	set_brow_thickness(brow_thickness)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta : float):
	# Spring force
	var spring_length := pupil_pos.length()
	var spring_dir := -pupil_pos.normalized()
	var spring_force := spring_const * spring_length
	pupil_vel += spring_force / mass * spring_dir
	
	# Gravity
	pupil_vel.y -= 9.0 * delta
	
	# Apply motion
	pupil_pos += pupil_vel * delta
	
	# Dampening
	pupil_vel = pupil_vel * pow(dampening, delta / 0.1)
	
	# Enforce position limit
	var dist := pupil_pos.length()
	if not is_zero_approx(dist):
		var max_dist := radius_white - radius_black
		if dist > max_dist:
			dist = max_dist
			pupil_pos = pupil_pos.normalized() * dist
			
			# Reflect outward velocity
			var norm := pupil_pos.normalized()
			var outward_vel := maxf(0.0, norm.dot(pupil_vel)) * norm
			pupil_vel -= outward_vel
	
	# Actually move the black part
	pupils.position.x = pupil_pos.x
	pupils.position.y = pupil_pos.y
	
	# Pull toward previous world position
	var pull := (white_part.global_position - prev_pupil_pos) * 0.5
	pupil_pos.x -= pull.dot(white_part.global_basis.x)
	pupil_pos.y -= pull.dot(-white_part.global_basis.z)
	prev_pupil_pos = white_part.global_position


func set_radius_white(r : float):
	radius_white = r
	if is_instance_valid(white_part):
		var sphere := white_part.mesh as SphereMesh
		sphere.radius = r


func set_radius_black(r : float):
	radius_black = r
	if is_instance_valid(black_part_front):
		var sphere := black_part_front.mesh as SphereMesh
		sphere.radius = r
	if is_instance_valid(black_part_back):
		var sphere := black_part_back.mesh as SphereMesh
		sphere.radius = r
	

func set_brow_visible(b : bool):
	brow_visible = b
	if is_instance_valid(brow_front):
		brow_front.visible = b
	if is_instance_valid(brow_back):
		brow_back.visible = b


func set_brow_tilt(tilt : float):
	brow_tilt = tilt
	if is_instance_valid(brow_front):
		brow_front.rotation_degrees.z = tilt
	if is_instance_valid(brow_back):
		brow_back.rotation_degrees.z = tilt


func set_brow_height(height : float):
	brow_height = height
	if is_instance_valid(brow_front):
		brow_front.position.y = height
	if is_instance_valid(brow_back):
		brow_back.position.y = height


func set_brow_thickness(thick : float):
	brow_thickness = thick
	if is_instance_valid(brow_front):
		(brow_front.mesh as QuadMesh).size.y = thick
	if is_instance_valid(brow_back):
		(brow_back.mesh as QuadMesh).size.y = thick
	
