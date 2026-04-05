extends Node2D
@export var start_position: Node2D  # a Position2D node in the scene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	remove_defeated_rubies()
	restore_player_position()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func remove_defeated_rubies():
	for ruby in get_tree().get_nodes_in_group("rubies"):
		if ruby.ruby_id in GameManager.defeated_rubies:
			print("Removing Ruby:", ruby.ruby_id)
			ruby.queue_free()

func restore_player_position():
	var player = get_tree().get_nodes_in_group("player")[0]
	if not player:
		return
	
	# If we have a saved position from GameManager, use it
	if GameManager.previous_player_position != Vector2.ZERO:
		player.global_position = GameManager.previous_player_position
	else:
		# Otherwise, use the default start position
		if start_position:
			player.global_position = start_position.global_position
