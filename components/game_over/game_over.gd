extends CanvasLayer

func write_leaderboard(leaderboard_data : Array[LeaderboardItem]):
	$Leaderboard.write_leaderboard(leaderboard_data)

signal quit
signal restart
@export var main: Node = null

func _unpause():
	main.get_tree().paused = false
	main.set_process_input(true)
	main.set_process_unhandled_input(true)
	main.remove_child(self)

func _on_restart_pressed() -> void:
	_unpause()
	restart.emit()

func _on_quit_pressed() -> void:
	_unpause()
	quit.emit()
