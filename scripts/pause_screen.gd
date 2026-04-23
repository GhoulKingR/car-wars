extends Node

const settings_scene = preload("res://components/Settings/Settings.tscn")
signal quit

@export var main: Node = null
@onready var settings = settings_scene.instantiate()

func _ready() -> void:
	settings.quit_settings.connect(_settings_quit)

func _unpause():
	main.get_tree().paused = false
	main.set_process_input(true)
	main.set_process_unhandled_input(true)
	main.remove_child(self)
	
func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_pause"):
		_unpause()

func _on_resume_pressed() -> void:
	_unpause()

func _on_quit_pressed() -> void:
	_unpause()
	quit.emit()

func _settings_quit():
	$CanvasLayer.remove_child(settings)

func _on_settings_pressed() -> void:
	$CanvasLayer.add_child(settings)
