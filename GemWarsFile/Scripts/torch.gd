extends Node2D
@export var speed = 60
func _process(delta):
	$PointLight2D.energy = randf_range(0.8, 1.0)
	$Torch.animation = "Torch1"
	$Torch.play()
