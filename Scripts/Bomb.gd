extends Node2D

var target_pos: Vector2
const speed: float = 100.0 # push speed
const push_distance: int = 4  # push distance 
const explosion_range: int = 3  # Adjust this value to control the explosion range
const explosion_power: int = 1   # Adjust this value to control how many breakables can be removed
@onready var areaPlayer = $Area2D 
@onready var Player = $"../Player"
@onready var bomb_sprite = $BombSprite
@onready var collision_shape_2d = $Area2D/CollisionShape2D
@onready var explosion_scene = preload("res://Scenes/Explosion.tscn")
@onready var explode_delay = $explode_delay
@onready var explosion_timer = $explosion_timer  # New explosion timer
@onready var boom_Sound = $"../boomSound"


func _ready():
	bomb_sprite.play("default")
	print("Bomb _ready called")
	target_pos = global_position  # target_pos = bomb pos
	if not $Area2D.is_connected("body_entered", Callable(self, "_on_body_entered")):
		print("Connecting body_entered signal")
		$Area2D.connect("body_entered", Callable(self, "_on_body_entered"))
	else:
		print("body_entered signal already connected")
	collision_shape_2d.global_position = global_position
	
	# Connect the explosion timer's timeout signal to the explode function
	if not explosion_timer.is_connected("timeout", Callable(self, "explode")):
		explosion_timer.connect("timeout", Callable(self, "explode"))
	
	# Start the explosion timer
	explosion_timer.start()
	

func _process(delta):
	if not is_zero_approx(global_position.distance_to(target_pos)):
		global_position = global_position.move_toward(target_pos, speed * delta)
		collision_shape_2d.global_position = global_position  # Sync collision shape position

func _on_body_entered(body):
	print("Body entered detected")
	if body.name == "Player":
		call_deferred("_disable_collision_shape")
	else:
		call_deferred("_enable_collision_shape")
		push_away_from(body.global_position)
		
func _disable_collision_shape():
	collision_shape_2d.disabled = true
	
func _enable_collision_shape():
	collision_shape_2d.disabled = false

func push_away_from(position: Vector2):
	var direction = (global_position - position).normalized()
	var tile_map = get_parent().get_node("TileMap")
	var current_tile = tile_map.local_to_map(global_position)
	var target_tile = current_tile
	var steps = push_distance
	
	while steps > 0:
		var next_tile = target_tile + Vector2i(direction.x, direction.y)
		
		# Map boundary 
		if next_tile.x < 0 or next_tile.y < 0 or next_tile.x >= tile_map.get_used_rect().size.x or next_tile.y >= tile_map.get_used_rect().size.y:
			print("Next tile is out of map bounds")
			break
		
		# Check next tile exist and data
		var tile_dataStatic = tile_map.get_cell_tile_data(0, next_tile)
		var tile_dataDynamic = tile_map.get_cell_tile_data(1, next_tile)
		
		# Check if the next tile is a wall or breakable wall
		if (tile_dataStatic and tile_dataStatic.get_custom_data("wall") == true) or (tile_dataDynamic and tile_dataDynamic.get_custom_data("breakable") == true):
			print("Next tile is not walkable (wall or breakable)")
			break
		
		# Check if next tile is occupied
		var bomb_in_tile = false
		for bomb in get_tree().get_nodes_in_group("bombs"):
			if bomb.global_position == tile_map.map_to_local(next_tile):
				bomb_in_tile = true
				break
		if bomb_in_tile:
			print("Next tile is occupied by another bomb")
			break
		
		target_tile = next_tile
		steps -= 1
	
	if target_tile != current_tile:
		print("Moving bomb to new position")
		target_pos = tile_map.map_to_local(target_tile)  # Align target tile to center
	else:
		print("No valid movement found")
		

func explode():
	# Create explosion instance on bomb location
	var explosion_instance = explosion_scene.instantiate()
	explosion_instance.global_position = global_position
	get_parent().add_child(explosion_instance)
	explosion_instance.add_to_group("explosions")
	
	# Initialize the queue with the starting positions for each direction
	var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	var queue = []
	for direction in directions:
		queue.append({"position": global_position, "direction": direction, "step": 1, "power": explosion_power})
	
	# Process the queue
	while queue.size() > 0:
		var current = queue.pop_front()
		var explosion_pos = current.position + current.direction * current.step * 16  # Assuming each tile is 16x16
		
		# Check if the explosion hits a wall or breakable before creating the explosion instance
		var tile_map = get_parent().get_node("TileMap")
		var tile_pos = tile_map.local_to_map(explosion_pos)
		var tile_dataStatic = tile_map.get_cell_tile_data(0, tile_pos)
		var tile_dataDynamic = tile_map.get_cell_tile_data(1, tile_pos)
		
		if tile_dataStatic and tile_dataStatic.get_custom_data("wall") == true:
			continue # Skip if explosion in direction hits wall
		
		if tile_dataDynamic and tile_dataDynamic.get_custom_data("breakable") == true:
			# Remove the breakable wall and set the tile to walkable
			tile_map.erase_cell(1, tile_pos)  # Remove the breakable wall tile
		
			
			# Decrease power of explosion per destroyable hit
			current.power -= 1
			# Create explosion instance even if it hits a breakable tile
			explosion_instance = explosion_scene.instantiate()
			explosion_instance.global_position = explosion_pos
			get_parent().add_child(explosion_instance)
			explosion_instance.add_to_group("explosions")
			
			# Stop explosion line if power -> 0
			if current.power <= 0:
				continue  
			
		
		# Create explosion instance if no wall or breakable is hit
		if not (tile_dataDynamic and tile_dataDynamic.get_custom_data("breakable") == true):
			explosion_instance = explosion_scene.instantiate()
			explosion_instance.global_position = explosion_pos
			get_parent().add_child(explosion_instance)
			explosion_instance.add_to_group("explosions")
		
		# Add the next step in the same direction to the queue
		if current.step < explosion_range:
			queue.append({"position": current.position, "direction": current.direction, "step": current.step + 1, "power": current.power})
		
		# Delay before processing the next step
		explode_delay.start(0.02)  # Adjust the delay as needed
		await explode_delay.timeout
		
	# Remove the bomb after the explosion
	queue_free()


func _on_explosion_timer_timeout():
	boom_Sound.play()
