extends StaticBody2D

func _ready():
	if GameManager.level_2_completed:
		$Door.play("Opening")
		await $Door.animation_finished
		queue_free()
