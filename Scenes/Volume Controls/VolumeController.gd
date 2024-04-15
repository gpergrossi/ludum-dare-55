class_name VolumeController extends AudioStreamPlayer

static var volume: float;
const minDb = -15;
const maxDb = +20;
static var db : float;

@onready var label = %"Volume Label";
@onready var originalLabelText = label.text;

func _ready():
	VolumeController.setVolume(0.15);
	%"Volume Slider".value_changed.connect(_on_value_changed);

func _on_value_changed (value):
	VolumeController.setVolume(value / 100.0);
	var busIndex = AudioServer.get_bus_index(bus);
	
	if volume > 0:
		AudioServer.set_bus_mute(busIndex, false);
		AudioServer.set_bus_volume_db(busIndex, db);
		if !is_playing():
			play();
		label.text = originalLabelText;
	else:
		AudioServer.set_bus_mute(busIndex, true);
		if is_playing():
			stop();
		label.text = originalLabelText + " (Muted)";

static func setVolume (newVolume: float):
	volume = newVolume;
	db = lerp(minDb, maxDb, volume);
