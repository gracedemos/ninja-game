extends Area3D

@export var projectile_speed = 80.0
@export var max_distance = 30.0

var direction = Vector3.ZERO
var start_position = Vector3.ZERO
var player: CharacterBody3D
var deflected = false

func _ready():
	player = get_node("/root/World/Stage/Player")
	body_entered.connect(_on_projectile_body_entered)
	direction = (player.global_transform.origin - global_transform.origin).normalized()
	start_position = global_transform.origin

func _physics_process(delta):
	position += direction * projectile_speed * delta

	var travel_distance = (global_transform.origin - start_position).length()
	if travel_distance >= max_distance:
		queue_free()

func _on_projectile_body_entered(body):
	match body:
		player:
			get_tree().call_deferred("reload_current_scene")

	if body == get_parent() and deflected:
		get_parent().queue_free()

	if body != get_parent():
		queue_free()

func deflect():
	deflected = true
	direction = -direction
