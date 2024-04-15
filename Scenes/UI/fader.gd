class_name Fader extends ColorRect

@onready var fade_in_player := $AnimationPlayer
@onready var all_3d_ui : Node3D = get_tree().current_scene
@onready var all_2d_ui : Control = %"UI Container"

# Called when the node enters the scene tree for the first time.
func _ready():
	fade_in_player.play_backwards("fade_in")
	await get_tree().create_timer(0.1).timeout
	all_3d_ui.show()
	all_2d_ui.show()
	await fade_in_player.animation_finished

func fade_in():
	fade_in_player.play("fade_in")
	await fade_in_player.animation_finished
