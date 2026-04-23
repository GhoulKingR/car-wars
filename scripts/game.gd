extends Node

const bullet_scene = preload("res://objects/bullet.tscn")
const enemy_scene = preload("res://objects/enemy.tscn")

@onready var player := $Player
@onready var terrain := $Terrain/TileMapLayer
@onready var leaderboard := $HUD/Leaderboard
@onready var counter := $HUD/Counter
@onready var events_elements := $HUD/Events
@onready var background_sound := $AudioManager/BackgroundSound
@onready var names = JSON.parse_string(
	FileAccess.get_file_as_string("res://assets/names.json")
)
@export var enemy_count: int = 20

signal gameover(leaderboard: Array[LeaderboardItem])

var players: Array[CharacterBody2D] = []
var timer := 300

func create_spawn_vec() -> Vector2:
	var spawnable = false
	var spawn_vec: Vector2
	
	while not spawnable:
		spawn_vec = Vector2(
			randf_range(64.0, 2432.0),
			randf_range(64.0, 1984.0)
		)
		var map_pos = terrain.local_to_map(terrain.to_local(spawn_vec))
		var tile_data: TileData = terrain.get_cell_tile_data(map_pos)
		if tile_data:
			spawnable = tile_data.get_custom_data("spawnable")
			
	return spawn_vec

func _ready() -> void:
	# check for tutorial file and begin countdown to hide
	if not FileAccess.file_exists("user://tutorial.dat"):
		$HUD/Tutorial.show()
		FileAccess.open("user://tutorial.dat", FileAccess.WRITE).store_string("done")
		get_tree().create_timer(10).timeout.connect(
			func():
				$HUD/Tutorial.hide()
		)
	
	background_sound.play()
	players.append(player)
	
	player.global_position = create_spawn_vec()
	var enemies: Array[CharacterBody2D] = []
	
	for i in range(enemy_count):
		var nickname = names.pick_random()
		var enemy: CharacterBody2D = enemy_scene.instantiate()
		enemy.set_nickname(nickname)
		enemy.global_position = create_spawn_vec()
		enemies.append(enemy)
		add_child(enemy)
		enemy.shoot.connect(on_shoot)
		enemy.respawn.connect(respawn)
		enemy.event.connect(_game_event)
	
	players.append_array(enemies)
	
	for i in range(enemy_count):
		var enemy = enemies[i]
		
		enemy.targets.append(player)
		for j in range(enemy_count):
			if i == j: continue
			enemy.targets.append(enemies[j])

func _exit_tree() -> void:
	background_sound.stop()

var events: Array[String] = []
func _game_event(content: String):
	while len(events) > 5:
		events.pop_front()
	events.push_back(content)
	
	# display content
	events_elements.text = "\n".join(events)

func on_shoot(global_direction: Vector2, global_start: Vector2, from: CharacterBody2D) -> void:
	var bullet = bullet_scene.instantiate()
	bullet.from_entity = from
	bullet.direction = global_direction
	bullet.position = global_start
	add_child(bullet)

func respawn(entity: CharacterBody2D):
	entity.global_position = create_spawn_vec()

func sort_players(a, b) -> bool:
	return a.get_score() > b.get_score()

func _game_over():
	var contenders = players
	contenders.sort_custom(sort_players)
	var leads: Array[LeaderboardItem] = []
	
	for c in contenders:
		var item = LeaderboardItem.new()
		item.nickname = c.get_nickname()
		item.deaths = c.get_deathcount()
		item.kills = c.get_killcount()
		item.score = c.get_score()
		leads.append(item)
		
	gameover.emit(leads)

func _on_timer_timeout() -> void:
	# decrement the timer
	if timer > 0:
		timer -= 1
		_write_timer()
	else:
		_game_over()
	
	# calculate leaderboard
	var top_contenders: Array[CharacterBody2D] = players.duplicate()
	top_contenders.sort_custom(sort_players)
	top_contenders = top_contenders
	var text = "Leaderboard (Top 5):\n"
	var player_found := false
	
	for i in range(5):
		var p = top_contenders[i]
		text += "{0}. {1} ({2})\n".format([i+1, p.get_nickname(), p.get_score()])
		if p == player:
			player_found = true
	
	if not player_found:
		text += "...\n"
		var player_pos = top_contenders.find(player)
		text += "{0}. {1} ({2})\n".format([
			player_pos+1, player.get_nickname(), player.get_score()
		])
		
	leaderboard.text = text

func _write_timer():
	var mins = int(timer / 60.0)
	var secs = int(timer % 60)
	counter.text = "%02d:%02d" % [mins, secs]
	
	if timer <= 10:
		counter.label_settings.font_color = Color.RED
		counter.label_settings.outline_color = Color.DARK_RED
	
	if timer == 0:
		$AudioManager/FinalBeep.play()
	elif timer <= 3:
		$AudioManager/TimerBeep.play()
