extends Node2D

signal shoot(global_direction: Vector2, global_start: Vector2)
@onready var sprite = $Sprite2D
@onready var gunTimer = $Timer
@onready var shoot_animation = $AnimatedSprite2D
@onready var shoot_sound = $AudioStreamPlayer2D
@onready var entry_distance = global_position.distance_to(shoot_animation.global_position)
@export var direction = Vector2.ZERO

func rotate_to_direction(dir: Vector2):
	if dir == Vector2(-1, 0): #left
		sprite.global_rotation = -(PI/2)
		sprite.frame = 0

	elif dir == Vector2(1, 0): # right
		sprite.global_rotation = (PI/2)
		sprite.frame = 0

	elif dir == Vector2(0, -1): # top
		sprite.global_rotation = 0
		sprite.frame = 0

	elif dir == Vector2(0, 1): # down
		sprite.global_rotation = PI
		sprite.frame = 0

	elif dir == Vector2(-1, -1): # top-left
		sprite.global_rotation = -(PI/2)
		sprite.frame = 1

	elif dir == Vector2(-1, 1): # down-left
		sprite.global_rotation = PI
		sprite.frame = 1

	elif dir == Vector2(1, -1): # top-right
		sprite.global_rotation = 0
		sprite.frame = 1

	elif dir == Vector2(1, 1): # down-right
		sprite.global_rotation = (PI/2)
		sprite.frame = 1

	if sprite.frame == 1:
		shoot_animation.global_position = global_position + (
			Vector2.UP.rotated(sprite.global_rotation + (PI/4)) * entry_distance)
		shoot_animation.global_rotation = sprite.global_rotation + (PI/4)
	else:
		shoot_animation.global_position = global_position + (
			Vector2.UP.rotated(sprite.global_rotation) * entry_distance)
		shoot_animation.global_rotation = sprite.global_rotation

var shooting := false
func _process(_delta: float) -> void:
	rotate_to_direction(direction)
	direction = direction.normalized()
	
	if direction:
		if not shooting:
			shooting = true
			gunTimer.start()
	else:
		if shooting:
			gunTimer.stop()
			shooting = false

func _on_timer_timeout() -> void:
	shoot_animation.visible = true
	shoot_animation.frame = 0
	shoot_animation.play("default")
	shoot_sound.play()
	
	var start = global_position + (direction * 20)
	shoot.emit(direction, start)
	
	await shoot_animation.animation_finished
	shoot_animation.visible = false
