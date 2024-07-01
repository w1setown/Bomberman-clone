extends CharacterBody2D

@export var player_id = 1
@onready var animation_player = $"../Health/AnimationPlayer"
@onready var monkeyhead_brown = $"../Health/Sprite2D"

@onready var tile_map = $"../TileMap"
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var collision_shape_2d = $CollisionShape2D
@onready var bomb_scene = preload("res://Scenes/bomb.tscn")
@onready var bomb_spawn_cooldown_timer = $BombSpawnCooldownTimer  # New timer for bomb spawn cooldown

var bomb  # bomb

var health = 1
var is_moving = false
var speed = 75  # Adjust this value to control the player's speed
var target_position = Vector2()  # Target position for movement
var respawn_position = Vector2(24, 24)
var damaged_by_explosion = false  # Flag to track if the player has already taken damage from the current explosion

func _ready():
	add_to_group("players")
	if not bomb_spawn_cooldown_timer.is_connected("timeout", Callable(self, "_on_bomb_spawn_cooldown_timer_timeout")):
		print("Connecting bomb spawn cooldown timer timeout signal")
		bomb_spawn_cooldown_timer.connect("timeout", Callable(self, "_on_bomb_spawn_cooldown_timer_timeout"))

func _physics_process(delta):
	if is_moving == false:
		animated_sprite_2d.play("idle%s" %[player_id])
		return
	
	if global_position.distance_to(target_position) < 1:
		is_moving = false
		global_position = target_position  # Ensure final position is exact
		return
		
	global_position = global_position.move_toward(target_position, speed * delta)
	animated_sprite_2d.global_position = global_position  # Sync sprite position
	collision_shape_2d.global_position = global_position  # Sync collision box position

func _process(_delta):
	if Input.get_action_strength("use%s" %[player_id]) and bomb_spawn_cooldown_timer.is_stopped():
		spawn_bomb()
		bomb_spawn_cooldown_timer.start()  # Start the cooldown timer
		
	if is_moving:
		return
	
	if Input.get_action_strength("up%s" %[player_id]):
		move(Vector2.UP)
		animated_sprite_2d.play("up%s" %[player_id])
		print("moving up and playing animations")
	elif Input.get_action_strength("down%s" %[player_id]):
		move(Vector2.DOWN)
		animated_sprite_2d.play("down%s" %[player_id])
		print("moving down and playing animations")
	elif Input.get_action_strength("left%s" %[player_id]):
		move(Vector2.LEFT)
		animated_sprite_2d.play("left%s" %[player_id])
		print("moving left and playing animations")
	elif Input.get_action_strength("right%s" %[player_id]):
		move(Vector2.RIGHT)
		animated_sprite_2d.play("right%s" %[player_id])
		print("moving right and playing animations")
	elif Input.get_action_strength("restartGame"):
		get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
		print("Restarting Game")

func move(direction: Vector2):
	var current_tile: Vector2i = tile_map.local_to_map(global_position)
	var direction_i: Vector2i = Vector2i(int(direction.x), int(direction.y))
	var target_tile: Vector2i = current_tile + direction_i
	
	# Check the dynamic layer (breakable)
	var tile_dataDynamic: TileData = tile_map.get_cell_tile_data(1, target_tile)
	if tile_dataDynamic and tile_dataDynamic.get_custom_data("breakable") == true:
		return  # Prevent movement if the tile is breakable
	
	# Check the static layer (walkable/wall)
	var tile_dataStatic: TileData = tile_map.get_cell_tile_data(0, target_tile)
	if tile_dataStatic and tile_dataStatic.get_custom_data("walkable") == false:
		return  # Prevent movement if the tile is not walkable
	
	# Check if target tile is occupied by a bomb
	for bomb in get_tree().get_nodes_in_group("bombs"):
		if bomb.global_position == tile_map.map_to_local(target_tile):
			# Push the bomb if the target tile is occupied
			bomb.push_away_from(global_position)
			return
		
	is_moving = true
	target_position = tile_map.map_to_local(target_tile)  # Set target position
	animated_sprite_2d.global_position = global_position  # Sync sprite position
	collision_shape_2d.global_position = global_position  # Sync collision box position

func spawn_bomb():
	print("Spawning bomb at position: ", global_position)  # Position Print
	
	var tile_size = 16
	var tile_center_offset = tile_size / 2
	var bomb_position = Vector2(
		int(global_position.x / tile_size) * tile_size + tile_center_offset,
		int(global_position.y / tile_size) * tile_size + tile_center_offset
	)
	
	var bomb_instance = bomb_scene.instantiate()
	bomb_instance.global_position = bomb_position  # Set bomb pos to player pos
	get_parent().add_child(bomb_instance)
	bomb_instance.add_to_group("bombs")  # Add bomb to group
	bomb = bomb_instance  # Ref for placed bomb

func _on_bomb_spawn_cooldown_timer_timeout():
	bomb_spawn_cooldown_timer.stop()

func take_damage(amount: int):
	if not damaged_by_explosion:
		health -= amount
		match health:
			2:
				print("Playing health_3 animation")
				animation_player.play("ban3_%s" %[player_id])
			1:
				animation_player.play("ban2_%s" %[player_id])
				print("Health:", health)
			0:
				animation_player.play("ban1_%s" %[player_id])
				die()
		damaged_by_explosion = true
	
func die():
	print("Player has died")
	queue_free()
