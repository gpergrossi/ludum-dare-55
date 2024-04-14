extends VBoxContainer

func _ready():
	resize();

func _process(delta):
	var view_size = get_viewport().get_size();
	if size.x != view_size.x || size.y != view_size.y: resize();

func resize():
	var view_size = get_viewport().get_size();
	var children : Array = get_children();
	
	size.x = view_size.x;
	size.y = view_size.y * children.size();
	for child in children:
		var child_size = child.get_size();
		child_size.x = view_size.x;
		child_size.y = view_size.y;
