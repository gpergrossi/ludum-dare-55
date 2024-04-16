extends Node

var current_level := 1

var _main_packed_scene := load("res://Scenes/Main.tscn")
var _outro_packed_scene := load("res://Scenes/OutroSequence/OutroSequence.tscn")

func load_level(new_level : int):
	current_level = new_level
	if (current_level >= len(Constants.manaByLevel)): return load_outro("Win");
	get_tree().change_scene_to_packed(_main_packed_scene)

func load_outro(winLose : String):
	CharacterSelected.outcome = winLose;
	get_tree().change_scene_to_packed(_outro_packed_scene);
