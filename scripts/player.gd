extends CharacterBody3D

@export var walk_speed = 12.0
@export var slow_walk_speed = 5.0
@export var jump_velocity = 20.0
@export var double_jump_velocity = 15.0
@export var dash_velocity = 80.0
@export var dash_time = 0.25
@export var dash_acceleration = 4.0
@export var decceleration = 15.0
@export var wall_gravity = 100.0
@export var mouse_sensitivity = 0.1

@onready var head = $Head
@onready var deflect_area = $DeflectArea
@onready var animation_player = $AnimationPlayer

var dashing = false
var can_double_jump = true
var can_dash = true

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(event.relative.x * -mouse_sensitivity))
		head.rotate_x(deg_to_rad(event.relative.y * -mouse_sensitivity))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89.0), deg_to_rad(89.0))

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	if is_on_wall():
		velocity.y = max(velocity.y, -wall_gravity * delta)

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	elif Input.is_action_just_pressed("jump") and can_double_jump:
		velocity.y = double_jump_velocity
		can_double_jump = false
		can_dash = true

	if not can_double_jump and is_on_floor():
		can_double_jump = true

	if not can_dash and is_on_floor():
		can_dash = true

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("move-l", "move-r", "move-f", "move-b")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction and Input.is_action_just_pressed("dash") and not dashing and can_dash:
		dashing = true
		can_dash = false
		await get_tree().create_timer(dash_time).timeout
		dashing = false
	elif dashing:
		var new_velocity = velocity.lerp(direction * dash_velocity, dash_acceleration * delta)
		velocity.x = new_velocity.x
		velocity.z = new_velocity.z
	elif direction and Input.is_action_pressed("slow"):
		velocity.x = direction.x * slow_walk_speed
		velocity.z = direction.z * slow_walk_speed
	elif direction:
		velocity.x = direction.x * walk_speed
		velocity.z = direction.z * walk_speed
	else:
		var new_velocity = velocity.lerp(Vector3.ZERO, decceleration * delta)
		velocity.x = new_velocity.x
		velocity.z = new_velocity.z
	
	move_and_slide()

	var areas = deflect_area.get_overlapping_areas()
	for area in areas:
		if area.get_name() == "Projectile":
			if Input.is_action_just_pressed("attack"):
				area.deflect()

	var bodies = deflect_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("Enemies"):
			if Input.is_action_just_pressed("attack") and is_enemy_visible():
				body.queue_free()

func _process(_delta):
	if Input.is_action_pressed("quit"):
		get_tree().quit()

	if Input.is_action_pressed("reload"):
		get_tree().reload_current_scene()

	if Input.is_action_just_pressed("attack"):
		animation_player.play("sword_swing")

func _on_death_trigger_body_entered(_body):
	get_tree().call_deferred("reload_current_scene")

func is_enemy_visible() -> bool:
	var ray_cast = head.get_node("RayCast3D")
	var collider = ray_cast.get_collider()

	if collider:
		if collider.is_in_group("Enemies"):
			return true
	
	return false
