extends VBoxContainer

func _ready():
	# Get the viewport's size
	var viewport_size = get_viewport().get_size()
	
	# Set the VBoxContainer's height to 4x the viewport height
	size.y = viewport_size.y * 4
