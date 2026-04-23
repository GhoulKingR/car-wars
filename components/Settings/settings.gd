extends Control

signal quit_settings

@onready var sfx_slider = $SFXSlider
@onready var sfx_bus = AudioServer.get_bus_index("SoundFX")
@onready var music_slider = $MusicSlider
@onready var music_bus = AudioServer.get_bus_index("Music")
@onready var ambientfx_slider = $AmbientSlider
@onready var ambientfx_bus = AudioServer.get_bus_index("AmbientFX")
const VOLUME_CONFIGS = "user://volume_configs.json"

func _ready() -> void:
	if not FileAccess.file_exists(VOLUME_CONFIGS):
		sfx_slider.value = AudioServer.get_bus_volume_linear(sfx_bus) * 100.0
		music_slider.value = AudioServer.get_bus_volume_linear(music_bus) * 100.0
		ambientfx_slider.value = AudioServer.get_bus_volume_linear(ambientfx_bus) * 100.0
		
	else:
		var file = FileAccess.open(VOLUME_CONFIGS, FileAccess.READ)
		var content = file.get_as_text()
		file.close()
		
		var data = JSON.parse_string(content)
		if data != null:
			sfx_slider.value = data["sfx_volume"]
			music_slider.value = data["music_volume"]
			ambientfx_slider.value = data["ambientfx_volume"]

func _on_close_settings_pressed() -> void:
	var file = FileAccess.open(VOLUME_CONFIGS, FileAccess.WRITE)
	var data = {
		"sfx_volume": sfx_slider.value,
		"music_volume": music_slider.value,
		"ambientfx_volume": ambientfx_slider.value
	}
	file.store_string(JSON.stringify(data))
	file.close()
	quit_settings.emit()

func _on_sfx_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(sfx_bus, value / (100.0 * 3))

func _on_ambient_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(ambientfx_bus, value / 100.0)

func _on_music_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(music_bus, value / 100.0)
