extends CharacterBody2D
@export var ruby_id: String = ""
@export var speed := 30
@export var next_scene: String = "res://fighting_ruby_2.tscn"
 
var direction := -1
var target: CharacterBody2D = null
var state := "patrol"
 
@onready var anim: AnimatedSprite2D = $frames
@onready var idle_timer: Timer = $IdleTimer
 
func _ready():
	idle_timer.wait_time = 5.0
	idle_timer.one_shot = true
	idle_timer.start()
 
func _physics_process(delta):
	match state:
		"patrol":
			patrol()
		"idle":
			idle()
 
 
func patrol():
	velocity.x = direction * speed
	move_and_slide()
 
	if is_on_wall():
		direction *= -1
 
	update_animation()
 
func idle():
	velocity = Vector2.ZERO
	move_and_slide()
	anim.play("Idle")
 
 
func update_animation():
	if velocity.x != 0:
		anim.flip_h = velocity.x > 0
		anim.play("LeftWalk")
	else:
		anim.play("Idle")
 
func _on_idle_timer_timeout() -> void:
	state = "idle"
	anim.play("Idle")
 
# Wait 2 seconds
	await get_tree().create_timer(2.0).timeout
 
	state = "patrol"
	idle_timer.start()

func _on_transfer_area_body_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Save previous scene path
		GameManager.previous_scene_path = get_tree().current_scene.scene_file_path
		
		# Save Ruby ID
		GameManager.current_ruby_id = ruby_id
		
		# Save player position
		GameManager.previous_player_position = body.global_position
		
		# Go to battle
		get_tree().change_scene_to_file(next_scene)
