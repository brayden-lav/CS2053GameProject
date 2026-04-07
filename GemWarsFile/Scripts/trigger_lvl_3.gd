extends Area2D

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		if GameManager.level_2_completed:
			GameManager.current_level = 3
			GameManager.defaultSpotlight = false
			get_tree().change_scene_to_file("res://Scene/level_3.tscn")
