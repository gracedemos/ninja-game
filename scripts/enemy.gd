extends CharacterBody3D

@export var player: CharacterBody3D

@onready var timer = $Timer

var player_visible = false
var projectile = preload("res://scenes/projectile.tscn")

func _ready():
	timer.timeout.connect(_on_timer_timeout)
	timer.start()

func _physics_process(_delta):
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(global_transform.origin, player.global_transform.origin)
	var result = space.intersect_ray(query)
	var distance = (global_transform.origin - player.global_transform.origin).length()

	if result:
		if result.collider == player and distance <= 30.0:
			player_visible = true
		else:
			player_visible = false

func _on_timer_timeout():
	if player_visible:
		var instance = projectile.instantiate()
		add_child(instance)
