extends CanvasLayer

@onready var sprite : TextureRect = $"Outro Image";
const azra_victory_image : Texture2D = preload("res://Assets/Images/azrawinscredits.png");
const rory_victory_image : Texture2D = preload("res://Assets/Images/rorywinscredits.png");

# Configuration constants
const start_scroll_delay := 2000;
const scroll_acceleration_duration := 8000;
const scroll_speed := 70; # pixels / sec

# Derived constants
const scroll_acceleration_start := start_scroll_delay;
const scroll_acceleration_end := scroll_acceleration_start + scroll_acceleration_duration;

# Instance variables
var start_time : int;
var scroll_end_y : float;
var done := false;

func _ready():
	var char = CharacterSelected.name;
	var outcome = CharacterSelected.outcome;
	
	print('Character: ', char, ", Outcome: ", outcome);
	
	if (char == "Azra" && outcome == "Win") || (char == "Rory" && outcome == "Lose"):
		print('Showing Azra-wins credits.');
		setImage(azra_victory_image);
	else:
		print('Showing Rory-wins credits.');
		setImage(rory_victory_image);
	start_time = Time.get_ticks_msec();

func setImage(image : Texture2D):
	sprite.texture = image;
	
	# Make sprite as wide as viewport, preserve aspect ratio.
	var viewport_size = get_viewport().get_size();
	var size := image.get_size();
	var aspect := size.x / size.y;
	sprite.size.x = viewport_size.x;
	sprite.size.y = viewport_size.x / aspect;
	
	# Precalculate where to stop scrolling, based on the size.
	scroll_end_y = viewport_size.y - sprite.size.y;

func _process(delta : float):
	if (done): return;
	
	# Scroll
	var time := Time.get_ticks_msec();
	var elapsed := time - start_time;
	var move := delta * scroll_speed * getScrollSpeedFactor(elapsed);
	sprite.position.y -= move;
	
	# Stop at end of image
	if (sprite.position.y <= scroll_end_y):
		sprite.position.y = scroll_end_y;
		done = true;

func getScrollSpeedFactor(time : int) -> float:
	
	# Don't scroll for a few seconds at the start
	if (time < start_scroll_delay): return 0;
	
	# Slowly build up speed
	if (scroll_acceleration_start <= time) && (time <= scroll_acceleration_end):
		return (time - scroll_acceleration_start) as float / scroll_acceleration_duration;
	
	return 1;
