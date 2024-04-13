class_name ThirdPerson3D extends CharacterBody3D

# Pixels per degree
@export var mouse_sensitivity := 0.25
@export var invert_x_axis := false
@export var invert_y_axis := false
@export var kill_y := -20.0

@export var camera_min_zoom_distance := 2.0
@export var camera_max_zoom_distance := 12.0
@export var camera_zoom_step := 0.5
@onready var spring_arm := %SpringArm3D as SpringArm3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var camera_rotation_x := 0.0
var camera_rotation_y := 0.0
var current_zoom_distance : float

func _ready():
	# Enable input processing
	set_process_input(true)
	current_zoom_distance = spring_arm.spring_length
	current_zoom_distance = clampf(current_zoom_distance, camera_min_zoom_distance, camera_max_zoom_distance)


func _physics_process(delta : float):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	process_move_input()
	process_jump_input()
	process_camera_input(delta)
	move_and_slide()
	
	if global_position.y < kill_y:
		# Respawn
		global_position = Vector3(0, 4, 0)


func process_move_input():
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)


func process_jump_input():
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY


func process_camera_input(_delta : float):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if Input.is_action_just_pressed("zoom_in"):
		current_zoom_distance -= camera_zoom_step
		current_zoom_distance = clampf(current_zoom_distance, camera_min_zoom_distance, camera_max_zoom_distance)
	
	if Input.is_action_just_pressed("zoom_out"):
		current_zoom_distance += camera_zoom_step
		current_zoom_distance = clampf(current_zoom_distance, camera_min_zoom_distance, camera_max_zoom_distance)
	
	basis = Basis(Vector3.UP, camera_rotation_y)
	spring_arm.basis = Basis(Vector3.RIGHT, camera_rotation_x)
	spring_arm.spring_length = current_zoom_distance


func _input(event):
	# Check if the event is a mouse motion event
	if event is InputEventMouseMotion:
		# Get the raw mouse motion
		var mouse_motion := event as InputEventMouseMotion
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			var mouse_velocity := mouse_motion.relative
			camera_rotation_y -= mouse_velocity.x * (PI / 180.0) * mouse_sensitivity * (-1 if invert_x_axis else 1)
			camera_rotation_x -= mouse_velocity.y * (PI / 180.0) * mouse_sensitivity * (-1 if invert_y_axis else 1)
			camera_rotation_x = clampf(camera_rotation_x, -0.5 * PI, 0.5 * PI)
