extends CanvasLayer

@onready var sprite : TextureRect = $"Outro Image";
const azra_victory_image : Texture2D = preload("res://Assets/Images/azra_outro_unfinished.png");
#const rory_victory_image : Texture2D = preload("res://Assets/Images/rory_outro.png");

# Configuration constants
const start_scroll_delay := 3000;
const scroll_acceleration_duration := 10000;
const scroll_speed := 50; # pixels / sec

# Derived constants
const scroll_acceleration_start := start_scroll_delay;
const scroll_acceleration_end := scroll_acceleration_start + scroll_acceleration_duration;

# Instance variables
var start_time : int;
var scroll_end_y : float;
var done := false;

func _ready():
	setImage(azra_victory_image);
	start_time = Time.get_ticks_msec();

func setImage(image : Texture2D):
	var viewport_size = get_viewport().get_size();
	var size := image.get_size();
	var aspect := size.x / size.y;
	
	# Make sprite as wide as viewport, preserve aspect ratio.
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
