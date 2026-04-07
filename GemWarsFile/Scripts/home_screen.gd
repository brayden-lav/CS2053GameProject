extends Control

func _on_play_pressed():
	get_tree().change_scene_to_file("res://Scene/main.tscn")

func _on_author_pressed():
	get_tree().change_scene_to_file("res://Scene/Authors.tscn") 
	
func _on_quit_pressed():
	get_tree().quit()
