extends Node3D


var holder : Player


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if is_instance_valid(holder):
		global_position = holder.global_position
		global_transform.basis = holder.global_transform.basis


func _on_area_3d_body_entered(body):
	if !holder && body is Player:
		holder = body
