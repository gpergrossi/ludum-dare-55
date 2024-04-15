extends Node

var current_level := 1

var _main_packed_scene := load("res://Scenes/Main.tscn")

func load_level(new_level : int):
	current_level = new_level
	get_tree().change_scene_to_packed(_main_packed_scene)
