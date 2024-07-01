extends Control

func _ready():
	$MarginContainer/VBoxContainer/Start.grab_focus()

func _on_start_pressed():
	Global.player_count = 2
	get_tree().change_scene_to_file("res://Scenes/bombers.tscn")
	print("Loading game...")
func _on_start_3_pressed():
	Global.player_count = 3
	get_tree().change_scene_to_file("res://Scenes/bombers.tscn")
	print("Loading game...")
func _on_start_4_pressed():
	Global.player_count = 3
	get_tree().change_scene_to_file("res://Scenes/bombers.tscn")
	print("Loading game...")
	
func _on_quit_pressed():
	get_tree().quit()
