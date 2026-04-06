extends Area2D

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		get_parent().get_parent().player_selected_card(self)
