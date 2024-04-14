extends Node

@onready var scene_root = $"../..";

func _ready():
	self.pressed.connect(next_page);

func next_page():
	scene_root.advance_page.emit();
