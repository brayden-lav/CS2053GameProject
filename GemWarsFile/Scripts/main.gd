extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.play_music("res://Music/Tension in the House.mp3")
	var dialogue = preload("res://Scene/dialog_box.tscn").instantiate()
	add_child(dialogue)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
