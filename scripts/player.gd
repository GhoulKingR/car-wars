extends CharacterBody2D

signal shoot(global_direction: Vector2, global_start: Vector2, from: CharacterBody2D)
signal respawn(entity: CharacterBody2D)
signal event(content: String)

const SPEED = 200.0

@export var health_bar: CanvasGroup
@export var score_element: Label
@onready var sprite = $Sprite2D
@onready var turrent = $Turrent
@onready var spawn_fader = $AnimationPlayer
@onready var turrent_sprite = $Turrent/Sprite2D
@onready var explosion_animation = $Explosion
@onready var collision_box = $CollisionShape2D
@onready var rattling_movement = $AudioManager/RattlingMovement
@onready var hit_sound = $AudioManager/HitSound

var just_spawned = true
var dying = false
var health := 100
var kill_count := 0
var death_count := 0
var turrent_direction := Vector2.ZERO

func _ready() -> void:
	$Camera2D.make_current()
	_delay_spawn()

func _delay_spawn():
	spawn_fader.play("just_spawned")
	just_spawned = true
	await get_tree().create_timer(3).timeout
	spawn_fader.stop()
	just_spawned = false

func _dying_squence():
	dying = true
	collision_box.set_deferred("disabled", true)
	sprite.hide()
	turrent.hide()
	explosion_animation.frame = 0
	explosion_animation.show()
	explosion_animation.play("default")
	
	await explosion_animation.animation_finished
	
	explosion_animation.hide()
	dying = false
	collision_box.set_deferred("disabled", false)
	sprite.show()
	turrent.show()

func hit(point: int) -> bool:
	if not just_spawned:
		health -= point
		health_bar.write_health(health)
		health_bar.set_bar(ceilf((health / 100.0) * 5.0))
		health_bar.shake()
		
		hit_sound.play()
		
		return health == 0
	return false
	
func get_nickname():
	return "you"

func get_killcount():
	return kill_count

func get_deathcount():
	return death_count

func get_score():
	var score := (kill_count * 10) - (death_count * 5)
	return score if score > 0 else 0

func death(_from: CharacterBody2D):
	$AudioManager/Explosion.play()
	await _dying_squence()
	respawn.emit(self)
	_delay_spawn()
	health = 100
	health_bar.write_health(health)
	health_bar.set_bar(5.0)
	death_count += 1
	score_element.set_score(get_score())

func kill(enemy: CharacterBody2D):
	kill_count += 1
	score_element.set_score(get_score())
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
	
	$AudioListener2D.global_rotation = 0

func _process(delta: float) -> void:
	if not dying:
		var direction := Vector2(
			Input.get_axis("move_left", "move_right"),
			Input.get_axis("move_up", "move_down")
		)
		rotate_to_direction(direction)
		direction = direction.normalized()
		
		if direction:
			if not rattling_movement.playing:
				rattling_movement.play()
		else:
			if rattling_movement.playing:
				rattling_movement.stop()
			
		
		turrent_direction = Vector2(
			Input.get_axis("shoot_left", "shoot_right"),
			Input.get_axis("shoot_up", "shoot_down")
		)
		turrent.direction = turrent_direction

		move_and_collide(direction * delta * SPEED)


func _on_turrent_shoot(global_direction: Vector2, global_start: Vector2) -> void:
	shoot.emit(global_direction, global_start, self)
