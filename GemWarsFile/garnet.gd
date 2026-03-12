extends Area2D
@export var speed = 60
var target_velocity = Vector2.ZERO
var screen_size
func _process(delta):
	screen_size = get_viewport_rect().size
	var dir := Vector2.ZERO
	if Input.is_action_pressed("moveRight"):
		dir = Vector2.RIGHT
		$AnimatedSprite2D.animation = "RightWalk"
	if Input.is_action_pressed("moveLeft"):
		dir = Vector2.LEFT
		$AnimatedSprite2D.animation = "LeftWalk"
	if Input.is_action_pressed("moveUp"):
		dir = Vector2.UP
		$AnimatedSprite2D.animation = "BackWalk"
	if Input.is_action_pressed("moveDown"):
		dir = Vector2.DOWN
		$AnimatedSprite2D.animation = "FrontWalk"
	if dir != Vector2.ZERO:
		position += dir * speed * delta
	else:
		$AnimatedSprite2D.animation = "Idle"
	$AnimatedSprite2D.play()
	target_velocity.x = dir.x * speed
	target_velocity.y = dir.y * speed
