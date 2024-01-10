extends CharacterBody3D

@export var walk_speed = 5.0
@export var sprint_speed = 10.0
@export var jump_velocity = 10.0
@export var dash_velocity = 40.0
@export var mouse_sensitivity = 0.1

@onready var head = $Head
@onready var deflect_area = $DeflectArea

var dashing = false

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(event.relative.x * -mouse_sensitivity))
		head.rotate_x(deg_to_rad(event.relative.y * -mouse_sensitivity))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89.0), deg_to_rad(89.0))

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("move-l", "move-r", "move-f", "move-b")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction and Input.is_action_just_pressed("dash") and not dashing:
		dashing = true
		await get_tree().create_timer(0.25).timeout
		dashing = false
	elif dashing:
		velocity.x = direction.x * dash_velocity
		velocity.z = direction.z * dash_velocity
	elif direction and Input.is_action_pressed("sprint"):
		velocity.x = direction.x * sprint_speed
		velocity.z = direction.z * sprint_speed
	elif direction:
		velocity.x = direction.x * walk_speed
		velocity.z = direction.z * walk_speed
	else:
		velocity.x = move_toward(velocity.x, 0, walk_speed)
		velocity.z = move_toward(velocity.z, 0, walk_speed)

	move_and_slide()

	var areas = deflect_area.get_overlapping_areas()
	for area in areas:
		if area.get_name() == "Projectile":
			if Input.is_action_just_pressed("deflect"):
				area.deflect()

func _process(_delta):
	if Input.is_action_pressed("quit"):
		get_tree().quit()

	if Input.is_action_pressed("reload"):
		get_tree().reload_current_scene()

func _on_death_trigger_body_entered(_body):
	position = Vector3.ZERO
	rotation = Vector3.ZERO
