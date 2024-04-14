@tool
class_name GoogleyEyesPair extends Node3D

@export var radius_white := 0.25 : set = set_radius_white
@export var radius_black := 0.09 : set = set_radius_black

@export var spring_const := 5.0  : set = set_spring_const
@export var mass := 2.0          : set = set_mass
@export var dampening := 0.34    : set = set_dampening

@export var brow_visible := false  : set = set_brow_visible
@export var brow_tilt := 8.9       : set = set_brow_tilt
@export var brow_height := 0.25    : set = set_brow_height
@export var brow_thickness := 0.05 : set = set_brow_thickness

@onready var left_eye := $LeftEye as GoogleyEye
@onready var right_eye := $RightEye as GoogleyEye


func set_radius_white(r : float):
	radius_white = r
	if is_instance_valid(left_eye):
		left_eye.radius_white = r
	if is_instance_valid(right_eye):
		right_eye.radius_white = r


func set_radius_black(r : float):
	radius_black = r
	if is_instance_valid(left_eye):
		left_eye.radius_black = r
	if is_instance_valid(right_eye):
		right_eye.radius_black = r


func set_spring_const(k : float):
	spring_const = k
	if is_instance_valid(left_eye):
		left_eye.spring_const = k
	if is_instance_valid(right_eye):
		right_eye.spring_const = k


func set_mass(m : float):
	mass = m
	if is_instance_valid(left_eye):
		left_eye.mass = m
	if is_instance_valid(right_eye):
		right_eye.mass = m


func set_dampening(d : float):
	dampening = d
	if is_instance_valid(left_eye):
		left_eye.dampening = d
	if is_instance_valid(right_eye):
		right_eye.dampening = d


func set_brow_visible(b : bool):
	brow_visible = b
	if is_instance_valid(left_eye):
		left_eye.brow_visible = b
	if is_instance_valid(right_eye):
		right_eye.brow_visible = b


func set_brow_tilt(tilt : float):
	brow_tilt = tilt
	if is_instance_valid(left_eye):
		left_eye.brow_tilt = -tilt
	if is_instance_valid(right_eye):
		right_eye.brow_tilt = tilt


func set_brow_height(height : float):
	brow_height = height
	if is_instance_valid(left_eye):
		left_eye.brow_height = height
	if is_instance_valid(right_eye):
		right_eye.brow_height = height


func set_brow_thickness(thick : float):
	brow_thickness = thick
	if is_instance_valid(left_eye):
		left_eye.brow_thickness = thick
	if is_instance_valid(right_eye):
		right_eye.brow_thickness = thick
