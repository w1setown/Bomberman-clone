extends Node2D

@onready var player_scenes = [
	preload("res://Scenes/player1.tscn"),
	preload("res://Scenes/player_2.tscn"),
	preload("res://Scenes/player_3.tscn"),
	preload("res://Scenes/player_4.tscn")
]

func _ready():
	var player_count = Global.player_count
	var player_positions = get_player_positions()  # Retrieve current positions of player branches
	
	for i in range(player_count):
		var player_scene = player_scenes[i]
		var player_instance = player_scene.instantiate()
		player_instance.player_id = i + 1  # Assign a unique player ID
		player_instance.global_position = player_positions[i]  # Position players at their current positions
		add_child(player_instance)

# Function to retrieve current positions of player branches
func get_player_positions():
	var positions = []
	for i in range(player_scenes.size()):
		var player_scene = player_scenes[i]
		var player_instance = player_scene.instantiate()
		positions.append(player_instance.global_position)
	return positions
