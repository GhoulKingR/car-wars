extends CharacterBody2D

signal shoot(global_direction: Vector2, global_start: Vector2, from: CharacterBody2D)
signal respawn(entity: CharacterBody2D)
signal event(content: String)
const SPEED = 100.0

@onready var initial_position = global_position
@onready var sprite = $Sprite2D
@onready var turrent = $Turrent
@onready var turrent_sprite = $Turrent/Sprite2D
@onready var nav_agent = $NavigationAgent2D
@onready var health_bar = $Health
@onready var name_tag = $NameTag
@onready var spawn_fader = $AnimationPlayer
@onready var healthbar_distance = global_position.distance_to(health_bar.global_position)
@onready var nametag_distance = global_position.distance_to(name_tag.global_position)
@onready var explosion_animation = $Explosion
@onready var collision_box = $CollisionShape2D
@onready var movement_sound = $AudioStreamPlayer2D
@export var targets : Array[CharacterBody2D] = []

var dying = false
var nickname := ""
var health := 100
var kill_count := 0
var death_count := 0
var just_spawned := false

func _ready() -> void:
	$NameTag/Label.text = nickname
	_delay_spawn()

func _delay_spawn():
	spawn_fader.play("just_spawned")
	just_spawned = true
	await get_tree().create_timer(3).timeout
	spawn_fader.stop()
	just_spawned = false

func hit(point: int) -> bool:
	if not just_spawned:
		health -= point
		health_bar.frame = ceil((health / 100.0) * 5.0)
		
		return health == 0
	return false

func _dying_squence():
	dying = true
	collision_box.set_deferred("disabled", true)
	sprite.hide()
	turrent.hide()
	name_tag.hide()
	health_bar.hide()
	explosion_animation.frame = 0
	explosion_animation.show()
	explosion_animation.play("default")
	
	await explosion_animation.animation_finished
	
	explosion_animation.hide()
	dying = false
	collision_box.set_deferred("disabled", false)
	sprite.show()
	name_tag.show()
	health_bar.show()
	turrent.show()

func set_nickname(n: String):
	nickname = n

func get_nickname():
	return nickname

func get_score():
	var score := (kill_count * 10) - (death_count * 5)
	return score if score > 0 else 0

func get_killcount():
	return kill_count

func get_deathcount():
	return death_count

func death(_from: CharacterBody2D):
	$AudioManager/Explosion.play()
	await _dying_squence()
	respawn.emit(self)
	_delay_spawn()
	health = 100
	health_bar.frame = 5.0
	death_count += 1

func kill(enemy: CharacterBody2D):
	kill_count += 1
	event.emit("%s -x-> %s" % [get_nickname(), enemy.get_nickname()])

func rotate_to_direction(direction: Vector2):
	if direction == Vector2(-1, 0): #left
		rotation_degrees = -90
		sprite.frame = 0
		turrent_sprite.frame = 0
	elif direction == Vector2(1, 0): # right
		rotation_degrees = 90
		sprite.frame = 0
		turrent_sprite.frame = 0
	elif direction == Vector2(0, -1): # top
		rotation_degrees = 0
		sprite.frame = 0
		turrent_sprite.frame = 0
	elif direction == Vector2(0, 1): # down
		rotation_degrees = 180
		sprite.frame = 0
		turrent_sprite.frame = 0
	elif direction == Vector2(-1, -1): # top-left
		rotation_degrees = -90
		sprite.frame = 1
		turrent_sprite.frame = 1
	elif direction == Vector2(-1, 1): # down-left
		rotation_degrees = 180
		sprite.frame = 1
		turrent_sprite.frame = 1
	elif direction == Vector2(1, -1): # top-right
		rotation_degrees = 0
		sprite.frame = 1
		turrent_sprite.frame = 1
	elif direction == Vector2(1, 1): # down-right
		rotation_degrees = 90
		sprite.frame = 1
		turrent_sprite.frame = 1
	
	health_bar.global_position = global_position + (Vector2.DOWN * healthbar_distance)
	health_bar.global_rotation = 0
	name_tag.global_position = global_position + (Vector2.DOWN * nametag_distance)
	name_tag.global_rotation = 0

var target: CharacterBody2D = null
var target_position: Vector2 = Vector2.INF
func _physics_process(_delta: float) -> void:
	if not dying:
		if !nav_agent.is_navigation_finished():
			var next_pos = nav_agent.get_next_path_position()
			var direction = global_position.direction_to(next_pos)
			var angle = direction.angle()
			var angle_clip = roundf(angle / (PI/4)) * (PI/4)
			var dir = Vector2.RIGHT.rotated(angle_clip)
			
			var look_direction = dir
			look_direction.x = roundf(look_direction.x)
			look_direction.y = roundf(look_direction.y)
			rotate_to_direction(look_direction)
				
			#if not movement_sound.playing:
				#movement_sound.play()
				
			velocity = direction * SPEED
			move_and_slide()
		
		#else:
			#if movement_sound.playing:
				#movement_sound.stop()
			
		if target != null:
			var angle = global_position.direction_to(target_position).angle() - (PI/2)
			var closest = roundf(angle / (PI/4)) * (PI/4)
			
			var turrent_direction = Vector2.DOWN.rotated(closest)
			turrent_direction.x = roundf(turrent_direction.x)
			turrent_direction.y = roundf(turrent_direction.y)
			turrent.direction = turrent_direction
			
		else:
			turrent.direction = Vector2.ZERO

func _on_turrent_shoot(global_direction: Vector2, global_start: Vector2) -> void:
	shoot.emit(global_direction, global_start, self)

func _on_raycast_timer_timeout() -> void:
	var space_state = get_world_2d().direct_space_state
	var from = global_position
	var aim_for: CharacterBody2D = null
	var distance := 0.0
	
	for _target in targets:
		var to = _target.global_position
		var d = from.distance_to(to)
		var query = PhysicsRayQueryParameters2D.create(from, to, 0x00000006)
		var result = space_state.intersect_ray(query)
		
		if result:
			var collider: Node2D = result.collider
			if not collider.is_in_group("terrain") and collider is CharacterBody2D:
				if aim_for == null or d < distance:
					aim_for = collider
					distance = d
	
	target = aim_for


func _on_path_tracing_timer_timeout() -> void:	
	if target != null:
		# try to keep some distance while getting into an angle
		# with good aim
		var desired_distance = 400.0 
		var path_goal: Vector2
		
		if target_position.is_equal_approx(target.global_position): # Stalemate: Flank
			var angle = target_position.direction_to(global_position).angle()
			var closest = roundf(angle / (PI/4)) * (PI/4)
			var next_angle = closest + ((1 if randf() < 0.5 else -1) * (PI/4) * randi_range(0, 4))
			path_goal = Vector2.RIGHT.rotated(next_angle).normalized() * desired_distance
			
		else:
			target_position = target.global_position
			var angle = target_position.direction_to(global_position).angle()
			var closest = roundf(angle / (PI/4)) * (PI/4)
			path_goal = Vector2.RIGHT.rotated(closest) * desired_distance
		
		nav_agent.target_position = path_goal + target_position
		
		
	else:
		# seek out the nearest player
		var closest_target : CharacterBody2D = null
		for _target in targets:
			if closest_target == null or (
				_target.global_position.distance_to(global_position) <
				closest_target.global_position.distance_to(global_position)
			):
				closest_target = _target
		
		nav_agent.target_position = closest_target.global_position
