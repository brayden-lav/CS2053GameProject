extends Area2D

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		GameManager.level_2_completed = true
		GameManager.defaultSpotlight = true
		get_tree().change_scene_to_file("res://Scene/main.tscn") 
