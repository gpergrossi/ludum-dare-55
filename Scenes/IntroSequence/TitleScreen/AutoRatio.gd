extends AspectRatioContainer

func _ready():
	update_ratio();

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	update_ratio();

func update_ratio():
	var view_size = get_viewport().get_size();
	var view_ratio = view_size.x as float / view_size.y;
	if view_ratio != ratio: ratio = view_ratio;
