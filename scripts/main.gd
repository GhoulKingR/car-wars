extends Node

const game_scene = preload("res://Scenes/game.tscn")
const pause_scene = preload("res://Scenes/pause_screen.tscn")
const gameover_scene = preload("res://components/game_over/game_over.tscn")

@onready var start_screen = $start_screen
@onready var game = game_scene.instantiate()
@onready var pause_menu = pause_scene.instantiate()
@onready var gameover = gameover_scene.instantiate()
var game_running = false

func _ready() -> void:
	game.gameover.connect(_game_over)
	gameover.main = self
	gameover.quit.connect(_game_quit)
	gameover.restart.connect(_game_restart)
	pause_menu.main = self
	pause_menu.quit.connect(_game_quit)

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_select"):
		start_screen.visible = false
		game_running = true
		add_child(game)
	
	if Input.is_action_just_pressed("ui_pause") and game_running:
		set_process_input(false)
		set_process_unhandled_input(false)
		add_child(pause_menu)
		get_tree().paused = true

func _game_over(leaderboard: Array[LeaderboardItem]):
	set_process_input(false)
	set_process_unhandled_input(false)
	add_child(gameover)
	gameover.write_leaderboard(leaderboard)
	get_tree().paused = true

func _game_quit():
	if game_running:
		game.get_tree().reload_current_scene()
		remove_child(game)
		start_screen.visible = true
		game_running = false

func _game_restart():
	remove_child(game)
	game.queue_free()
	game = game_scene.instantiate()
	game.gameover.connect(_game_over)
	add_child(game)

func _exit_tree() -> void:
	game.queue_free()
	pause_menu.queue_free()
	gameover.queue_free()
