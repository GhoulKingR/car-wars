extends Node

signal quit
@export var main: Node = null

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
