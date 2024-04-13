extends Sprite2D

var angle := 0.0
@export var spin := 0.1


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	angle += spin * delta
	scale.x = cos(angle)
	scale.y = 1.0
