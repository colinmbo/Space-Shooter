class_name Hitbox
extends Area3D


@export var damage = 10


func _on_body_entered(body):
	if body is Player:
		body.health -= damage
	queue_free()
