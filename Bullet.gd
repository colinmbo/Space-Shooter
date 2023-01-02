extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	global_position -= global_transform.basis.z * 0.7
	pass


func _on_timer_timeout():
	queue_free()
