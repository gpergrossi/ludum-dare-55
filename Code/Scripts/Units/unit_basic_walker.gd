class_name UnitBasicWalker extends UnitBase

func _ready() -> void:
	super._ready()


# Need to expose this here so an animation sequence can call it.
func damage_target():
	super.damage_target()
