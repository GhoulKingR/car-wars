extends RigidBody2D

@export var direction: Vector2 = Vector2.ZERO
@export var from_entity: CharacterBody2D
@onready var contact_animation = $AnimatedSprite2D
const SPEED = 400

var exploding := false

func _physics_process(delta: float) -> void:
	if not exploding:
		var collision = move_and_collide(direction * delta * SPEED)
		
		if collision:
			contact_animation.frame = 0
			contact_animation.visible = true
			contact_animation.play("default")
			var collider = collision.get_collider()
			
			if collider is CharacterBody2D:
				if collider.hit(5):
					from_entity.kill(collider)
					collider.death(from_entity)
			
			$Sprite2D.visible = false
			$CollisionShape2D.set_deferred("disabled", true)
			$AudioStreamPlayer2D.play()
			exploding = true
			
			await contact_animation.animation_finished
			contact_animation.visible = false
			queue_free()
