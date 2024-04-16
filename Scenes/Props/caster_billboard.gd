extends Sprite3D

@export var is_left_side : bool

@export var azra_texture : Texture
@export var rory_texture : Texture

# Called when the node enters the scene tree for the first time.
func _ready():
	if is_left_side:
		if CharacterSelected.name == 'Azra':
			texture = azra_texture
		else:
			texture = rory_texture
	else:
		if CharacterSelected.name == 'Azra':
			texture = rory_texture
		else:
			texture = azra_texture
