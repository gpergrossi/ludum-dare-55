extends CanvasLayer

func _ready():
	%TitleScreen.advance_page.connect(show_first_story_page);
	%StoryPage1.advance_page.connect(show_second_story_page);
	%StoryPage2.advance_page.connect(show_character_select_page);
	%CharacterSelect.advance_page.connect(start_game);

func show_first_story_page():
	var viewport_size = get_viewport().get_size()
	%VBoxContainer.position.y = -viewport_size.y;

func show_second_story_page():
	var viewport_size = get_viewport().get_size()
	%VBoxContainer.position.y = -2 * viewport_size.y;

func show_character_select_page():
	var viewport_size = get_viewport().get_size()
	%VBoxContainer.position.y = -3 * viewport_size.y;

func start_game():
	get_tree().change_scene_to_file("res://Scenes/Main.tscn");
