class_name Player
extends RigidBody3D


@export var move_speed = 0.5
@export var jump_force = 10
@export var booster_force = 30
@export var max_health = 100
@export var max_fuel = 100


var score = 0


@export var health = max_health:
	set(val):
		val = clamp(val, 0, max_health)
		$CanvasLayer/HealthBar.value = val
		health = val
		if health == 0:
			queue_free()
		

var fuel = max_fuel:
	set(val):
		val = clamp(val, 0, max_fuel)
		$CanvasLayer/FuelBar.value = val
		fuel = val

var gravity_center_exists = false
var current_gravity_center = Vector3.ZERO

var y_rotation_amt = 0

var forward_direction = Vector3.FORWARD
var gravity_direction = Vector3.DOWN
var target_basis : Basis

var is_on_floor = false
var can_try_boosting = false

var hurt_time = 1


func _input(event):
	
	if is_multiplayer_authority():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		#Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		if event is InputEventMouseMotion:
			#forward_direction = forward_direction.rotated(transform.basis.y, -event.relative.x * 0.5)
			var sensitivity = 0.005
			if $Camera3D.fov == 40:
				sensitivity *= 0.5
			y_rotation_amt = -event.relative.x * sensitivity
			$Camera3D.rotate_x(-event.relative.y * sensitivity)


func _ready():
	
	health = max_health
	fuel = max_fuel
	$CanvasLayer/HealthBar.max_value = max_health
	$CanvasLayer/HealthBar/DifferenceBar.max_value = max_health
	$CanvasLayer/FuelBar.max_value = max_fuel
	
	set_multiplayer_authority(str(name).to_int())
	
	# Set correct multiplayer authority visibility
	$CharacterModel.visible = !is_multiplayer_authority()
	$CanvasLayer/HealthBar.visible = is_multiplayer_authority()
	$CanvasLayer/YourScore.visible = is_multiplayer_authority()
	$CanvasLayer/Vignette.visible = is_multiplayer_authority()
	$CanvasLayer/FuelBar.visible = is_multiplayer_authority()
	$Camera3D.current = is_multiplayer_authority()


func _process(delta):
	
	hurt_time = clamp(hurt_time - 0.4 * delta, 0, 1)
	var vig = $CanvasLayer/Vignette.material as ShaderMaterial
	
	if hurt_time < 0.4:
			var model = get_node("CharacterModel/Armature/Skeleton3D/Body") as MeshInstance3D
			model.material_overlay.albedo_color.a = 0
	
	if hurt_time < 0.2:
		$CanvasLayer/HealthBar/DifferenceBar.value = lerp($CanvasLayer/HealthBar/DifferenceBar.value, $CanvasLayer/HealthBar.value, 0.05)
	
	if is_multiplayer_authority():
		
		if Input.is_action_just_pressed("ui_cancel"):
			rpc("take_damage", get_path(), max_health)
		
		vig.set_shader_parameter("scale", 1.0 - hurt_time)
		
		$Camera3D.rotation.x = clamp($Camera3D.rotation.x, -PI/2, PI/2)
		
		if gravity_center_exists:
			if global_position.distance_to(current_gravity_center) < 50:
				gravity_direction = global_position.direction_to(current_gravity_center)
		
		if $RayCast3D.is_colliding() && linear_velocity.dot(transform.basis.y) < 5:
			is_on_floor = true
		else:
			is_on_floor = false
		
		
		if Input.is_action_pressed("scope"):
			$Camera3D.fov = 40
		else:
			$Camera3D.fov = 75
		
	else:
		
		$CanvasLayer/HealthBar.position = get_viewport().get_camera_3d().unproject_position(global_position + basis.y * 3) - Vector2($CanvasLayer/HealthBar.size.x / 2, $CanvasLayer/HealthBar.size.y )
		if hurt_time < 0.001:
			$CanvasLayer/HealthBar.visible = false
		
		


func _physics_process(delta):
	
	if is_multiplayer_authority():
		var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		var oriented_input_dir = transform.basis * Vector3(input_dir.x, 0, input_dir.y)
		
		forward_direction = transform.basis.z
		
		if is_on_floor:
			
			if input_dir:
				apply_central_impulse(oriented_input_dir * move_speed)
				$CharacterModel/AnimationPlayer.play("run_forward")
			else:
				$CharacterModel/AnimationPlayer.play("idle")
			
			if Input.is_action_just_pressed("jump"):
				can_try_boosting = false
				apply_central_impulse(transform.basis.y * jump_force)
			
			fuel += 10
			
		else:
			
			if fuel > 0:
				if input_dir:
					apply_central_force(oriented_input_dir * booster_force * 0.25)
					fuel -= 0.25
				
				if Input.is_action_pressed("jump"):
					if Input.is_action_just_pressed("jump"):
						can_try_boosting = true
					if can_try_boosting:
						apply_central_force(transform.basis.y * booster_force)
						fuel -= 1
		
		if Input.is_action_just_pressed("shoot"):
			check_hitscan()


func _integrate_forces(state):
	
	var left_axis = -gravity_direction.cross(forward_direction)
	target_basis = Basis(left_axis, -gravity_direction, forward_direction).orthonormalized()
	state.transform.basis = state.transform.basis.slerp(target_basis.get_rotation_quaternion(), 0.1)
	
	state.transform.basis = state.transform.basis.rotated(transform.basis.y, y_rotation_amt)
	y_rotation_amt = 0
	

func check_hitscan():
	
	var hs = $Camera3D/Hitscan as RayCast3D
	hs.force_raycast_update()
	
	var b = "res://Bullet.tscn"
	rpc_id(1, "spawn_instance", b, hs.global_position, hs.global_transform.basis)
	
#	$CharacterModel/Armature/Skeleton3D/BoneAttachment3D/MeshInstance3D.visible = false
#	$CharacterModel/Armature/Skeleton3D/BoneAttachment3D/MeshInstance3D2.visible = true
#	await get_tree().create_timer(2).timeout
#	$CharacterModel/Armature/Skeleton3D/BoneAttachment3D/MeshInstance3D.visible = true
#	$CharacterModel/Armature/Skeleton3D/BoneAttachment3D/MeshInstance3D2.visible = false
		
	if !hs.is_colliding():
		return
	
	if hs.get_collider() is Player:
		# Hitbox
#		var hb = load("res://Hitbox.tscn").instantiate()
#		get_tree().root.get_child(0).add_child(hb, true)
#		hb.global_position = hs.get_collision_point()
#		hb.damage = 10
		rpc("take_damage", hs.get_collider().get_path(), 30)
		if hs.get_collider().health == 0:
			score += 1
			$CanvasLayer/YourScore.text = "Score: " + str(score)
		
	
	else:
		# Bullethole
		
		#get_parent().get_node("MultiplayerSpawner").set_multiplayer_authority(get_multiplayer_authority())
		var bh = "res://BulletHole.tscn"
		
		#get_tree().root.get_child(0).get_node("NetworkedNodes").add_child(bh, true)
		
		
		var orig = hs.get_collision_point() + hs.get_collision_normal() * 0.1
		var norm = hs.get_collision_normal()
		var flip_norm = Vector3(norm.z, norm.y, -norm.x)
		var bas = Basis(norm.cross(flip_norm), norm, flip_norm).orthonormalized()
		
		rpc_id(1, "spawn_instance", bh, orig, bas)


@rpc (call_local)
func take_damage(path, dmg):
	var entity = get_node(path)
	entity.health -= dmg
	entity.hurt_time = 0.5
	
	entity.get_node("CanvasLayer/HealthBar").visible = true
	
	var model = entity.get_node("CharacterModel/Armature/Skeleton3D/Body") as MeshInstance3D
	model.material_overlay.albedo_color.a = 1
	


@rpc (call_local)
func spawn_instance(path, orig, bas):
	var inst = load(path).instantiate()
	get_parent().add_child(inst, true)
	inst.global_transform.origin = orig
	inst.global_transform.basis = bas
