extends CharacterBody2D
@export var speed = 60
var target_velocity = Vector2.ZERO
var screen_size

func _ready() -> void:
	if GameManager.current_level == 2:
		$PointLight2D.color = Color("#6b69ff")
	if GameManager.current_level == 3:
		$PointLight2D.color = Color("#a2ff7b")
	if GameManager.defaultSpotlight == true:
		$PointLight2D.color = Color("#ffad32")
		
func _process(delta):
	screen_size = get_viewport_rect().size
	var dir := Vector2.ZERO
	if GameManager.dialogue_active:
		dir = Vector2.ZERO
	elif  Input.is_action_pressed("moveRight"):
		dir = Vector2.RIGHT
		$AnimatedSprite2D.animation = "RightWalk"
	elif Input.is_action_pressed("moveLeft"):
		dir = Vector2.LEFT
		$AnimatedSprite2D.animation = "LeftWalk"
	elif Input.is_action_pressed("moveUp"):
		dir = Vector2.UP
		$AnimatedSprite2D.animation = "BackWalk"
	elif Input.is_action_pressed("moveDown"):
		dir = Vector2.DOWN
		$AnimatedSprite2D.animation = "FrontWalk"
	if dir != Vector2.ZERO:
		position += dir * speed * delta
	else:
		$AnimatedSprite2D.animation = "Idle"
	$AnimatedSprite2D.play()
	target_velocity.x = dir.x * speed
	target_velocity.y = dir.y * speed
	move_and_slide()
	$PointLight2D.energy = randf_range(0.8, 1.0)
