class_name BulletHole
extends Node3D


var normal := Vector3.UP:
	set(val):
		var flip_norm = Vector3(val.z, val.y, -val.x)
		basis = Basis(val.cross(flip_norm), val, flip_norm).orthonormalized()


func _on_timer_timeout():
	pass
	#queue_free()
