class_name ProjectileManager extends Node3D

static var singleton : ProjectileManager;

func _ready():
	ProjectileManager.singleton = self;
