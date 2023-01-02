extends Area3D


func _on_body_entered(body):
	if "current_gravity_center" in body:
		body.gravity_center_exists = true
		body.current_gravity_center = global_position + gravity_point_center
