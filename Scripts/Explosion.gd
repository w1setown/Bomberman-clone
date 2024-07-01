extends Node2D
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var collision_shape_2d = $Area2D/CollisionShape2D
var player_damaged = false  # Flag to track if the player has already taken damage

func _ready():
	$AnimatedSprite2D.play("explode")
	$AnimatedSprite2D.connect("animation_finished", Callable(self, "_on_animation_finished"))
	if not $Area2D.is_connected("body_entered", Callable(self, "_on_body_entered")):
		$Area2D.connect("body_entered", Callable(self, "_on_body_entered"))

func _on_animation_finished():
	# Reset the player's damage flag when the explosion animation finishes
	for player in get_tree().get_nodes_in_group("players"):
		player.damaged_by_explosion = false
	queue_free()

func _on_body_entered(body):
	if body.name == "Player" and not player_damaged:
		body.take_damage(1)
		player_damaged = true  # Set the flag to true to prevent further damage
	if body.name == "Player2" and not player_damaged:
		body.take_damage(1)
		player_damaged = true  # Set the flag to true to prevent further damage
	if body.name == "Player3" and not player_damaged:
		body.take_damage(1)
		player_damaged = true  # Set the flag to true to prevent further damage
	if body.name == "Player4" and not player_damaged:
		body.take_damage(1)
		player_damaged = true  # Set the flag to true to prevent further damage
	elif body.name == "Wall":
		queue_free()

