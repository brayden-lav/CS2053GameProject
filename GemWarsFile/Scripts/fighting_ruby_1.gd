extends Node2D
# maing it turn by turn
enum Turn { PLAYER, ENEMY }

# State all variables required
var current_turn = Turn.PLAYER

	#health variables
var garnet_health = 0
var garnet_max_health = 10
var ruby_health = 10

	#for ruby when she uses a shield
var ruby_skip_turn = false
	#initialize shield active as false
var garnet_shield_active = false
var ruby_shield_active = false
	#lightning cooldown
var lightning_cooldown = 0
	#card array
var cards = []

# VISUAL REFERENCES
	#hearts
@onready var hearts = $Hearts.get_children()
	#characters
@onready var garnet_node = $GarnetFighting
@onready var ruby_node = $RubyFighting
	#effects
@onready var garnet_lightning = $GarnetEffects/Lightning
@onready var garnet_shield = $GarnetEffects/Shield
@onready var garnet_fireball = $GarnetEffects/FireBall
@onready var ruby_fireball = $RubyEffects/FireBall
@onready var ruby_shield_node = $RubyEffects/Shield
#effect starting positions defining
var lightning_start_pos
var garnet_shield_pos
var ruby_shield_pos
var garnet_fireball_start_pos
var ruby_fireball_start_pos


# READY

func _ready():
	randomize() # for ruby to randomly pick a card
	cards = $Cards.get_children() #putting cards into card array

	# Ensure heart order is correct
	hearts.sort_custom(func(a, b): return a.name < b.name) #descending order using name
	#setting garnet health to whatever it was from the previous scene
	garnet_health = GameManager.garnet_health
	garnet_max_health = GameManager.garnet_max_health
	
	if garnet_health <= 0:
		garnet_health = garnet_max_health
	
	update_hearts()

	# Positions
	lightning_start_pos = garnet_lightning.global_position
	garnet_shield_pos = garnet_node.global_position + Vector2(50, 0)
	ruby_shield_pos = ruby_node.global_position + Vector2(-50, 0)
	garnet_fireball_start_pos = garnet_fireball.global_position
	ruby_fireball_start_pos = ruby_fireball.global_position

	# Hide effects
	garnet_lightning.visible = false
	garnet_shield.visible = false
	ruby_shield_node.visible = false
	garnet_fireball.visible = false
	ruby_fireball.visible = false

	start_player_turn()

# TURN SYSTEM

func start_player_turn():
	current_turn = Turn.PLAYER
	
	#shield disappears at start of Ruby's next turn if it was a defensive shield
	if ruby_shield_active and not ruby_skip_turn:
		ruby_shield_node.visible = false
		ruby_shield_active = false
	
	#break Garnet shield
	if garnet_shield_active:
		await play_garnet_shield_break()
	garnet_shield_active = false
	
	if lightning_cooldown > 0:
		lightning_cooldown -= 1
	
	show_cards(true)

func start_enemy_turn():
	current_turn = Turn.ENEMY
	
	show_cards(false)

	if ruby_skip_turn:
		print("Ruby skips turn!")
		ruby_skip_turn = false # so Ruby can act next turn
		await get_tree().create_timer(0.5).timeout
		start_player_turn()
		return
	
	await get_tree().create_timer(0.8).timeout
	enemy_pick_card()

# CARD VISIBILITY

func show_cards(state: bool):
	for card in cards: #adjust for lightning visibility
		if card.name == "Card4" and lightning_cooldown > 0:
			card.visible = false
			continue
		
		card.visible = state
		card.set_process_input(state)

func show_only_selected_card(selected): #makes it so that you can see the effect of the card you just picked happen
	for card in cards:
		card.visible = (card == selected)


# PLAYER INPUT

func player_selected_card(card):
	if current_turn != Turn.PLAYER:
		return
	
	if card.name == "Card4" and lightning_cooldown > 0:
		print("Lightning on cooldown!")
		return
	
	show_only_selected_card(card)
	await resolve_card(card, true)
	start_enemy_turn()


# ENEMY AI

func enemy_pick_card():
	var allowed = []
	for card in cards:
		if card.name == "Card1" or card.name == "Card3": #makes the fight go a bit smoother to use only the 2 cards
			allowed.append(card)
	if allowed.is_empty():
		return
	
	var pick = allowed[randi() % allowed.size()]
	print("Enemy picked:", pick.name)
	await resolve_card(pick, false)
	start_player_turn()


# CARD RESOLUTION

func resolve_card(card, is_player: bool):
	match card.name:
		"Card1":
			await fireball(is_player, 1) #wait for the animations to be played
		"Card2":
			heal()
		"Card3":
			await shield(is_player) # await added to ensure Ruby shows animation
		"Card4":
			await lightning(is_player, 2) #wait for the animations to be played

# HEARTS

func update_hearts():
	var total = hearts.size()
	for i in range(total):
		var sprite = hearts[i].get_node("AnimatedSprite2D")
		if i > total - garnet_health:
			sprite.play("life")
		else:
			sprite.play("dead")


# DAMAGE

func damage_ruby(amount):
	if ruby_shield_active:
		print("Ruby blocked attack!")
		await play_ruby_shield_break() # shield disappears after blocking
		return
	
	ruby_health -= amount
	print("Ruby takes", amount, "damage. HP =", ruby_health)
	if ruby_health <= 0:
		ruby_died()

func damage_garnet(amount):
	if garnet_shield_active:
		print("Garnet blocked attack!")
		return
	
	garnet_health = garnet_health - amount
	print("Garnet takes", amount, "damage. HP =", garnet_health)
	update_hearts()


# ANIMATIONS

func play_attack_animation(node):
	var sprite = node.get_node("AnimatedSprite2D")
	sprite.play("default")
	var frames = sprite.sprite_frames.get_frame_count("default")
	var speed = sprite.speed_scale
	var fps = sprite.sprite_frames.get_animation_speed("default")
	var duration = frames / (fps * speed)
	await get_tree().create_timer(duration).timeout
	sprite.stop()
	sprite.frame = 0


# ABILITIES

func fireball(is_player, damage):
	if is_player:
		await play_attack_animation(garnet_node) #garnet lifts arm
		await play_fireball(garnet_fireball, garnet_node.global_position, ruby_node.global_position, true) #launch fireball at ruby
		damage_ruby(damage) #check if ruby takes damage
	else:
		await play_attack_animation(ruby_node) #ruby lifts arm
		await play_fireball(ruby_fireball, ruby_node.global_position, garnet_node.global_position, false)
		damage_garnet(damage)

func play_fireball(node, from_pos, to_pos, is_player):
	node.global_position = from_pos #starting position
	node.visible = true #make visible
	var sprite = node.get_node("AnimatedSprite2D") #select the fireball node
	sprite.stop() #make sure that you are launching from the first frame
	sprite.frame = 0
	sprite.play("default") #play whole animation
	
	var target = to_pos #assigning who you are pulling the fireball to
	
	#making the pull stop at shield if it is in fact there
	if is_player and ruby_shield_active:
		target = ruby_shield_pos
	elif !is_player and garnet_shield_active:
		target = garnet_shield_pos
	
	var tween = create_tween() #creating the pull
	tween.tween_property(node, "global_position", target, 0.5)  #this basically pulls the node from the position to the target in a given amount of time.
	await tween.finished #wait until they have collided
	
	await get_tree().create_timer(0.15).timeout # pause on impact
	
	if is_player and ruby_shield_active: #break shield after turn
		await play_ruby_shield_break()
	
	sprite.stop()
	sprite.frame = 0
	node.visible = false

func lightning(is_player, damage): #functions the same as fireball but with a cooldown
	if is_player:
		await play_attack_animation(garnet_node)
		await play_lightning(garnet_node.global_position, ruby_node.global_position, true)
		print("Lightning hits Ruby for", damage)
		damage_ruby(damage)
		lightning_cooldown = 2
	else:
		await play_attack_animation(ruby_node)
		await play_lightning(ruby_node.global_position, garnet_node.global_position, false)
		print("Lightning hits Garnet for", damage)
		damage_garnet(damage)

func play_lightning(from_pos, to_pos, is_player):
	garnet_lightning.global_position = from_pos
	garnet_lightning.visible = true
	var sprite = garnet_lightning.get_node("AnimatedSprite2D")
	sprite.stop()
	sprite.frame = 0
	sprite.play("default")
	
	var target = to_pos
	if is_player and ruby_shield_active:
		target = ruby_shield_pos
	elif !is_player and garnet_shield_active:
		target = garnet_shield_pos
	
	var tween = create_tween()
	tween.tween_property(garnet_lightning, "global_position", target, 0.5)
	await tween.finished
	
	await get_tree().create_timer(0.15).timeout
	
	if is_player and ruby_shield_active:
		await play_ruby_shield_break()
	
	sprite.stop()
	sprite.frame = 0
	garnet_lightning.visible = false
	garnet_lightning.global_position = lightning_start_pos

func shield(is_player):
	if is_player:
		garnet_shield_active = true
		garnet_shield.visible = true
		garnet_shield.global_position = garnet_shield_pos
		garnet_shield.scale.x = -1 #had to flip due to how it was drawn
		garnet_shield.get_node("AnimatedSprite2D").play("ShieldUp")
	else:
		ruby_shield_active = true
		ruby_shield_node.visible = true
		ruby_shield_node.global_position = ruby_shield_pos
		await play_attack_animation(ruby_node) # Ruby shows fighting animation before shield
		ruby_shield_node.get_node("AnimatedSprite2D").play("ShieldUp")
		ruby_skip_turn = true # skip next turn after shielding


# SHIELD BREAK

#this just selects, then plays the animation and makes the shield visibility false.
func play_ruby_shield_break():
	var sprite = ruby_shield_node.get_node("AnimatedSprite2D")
	sprite.play("ShieldBreak")
	await get_tree().create_timer(0.4).timeout
	ruby_shield_node.visible = false
	ruby_shield_active = false

func play_garnet_shield_break():
	var sprite = garnet_shield.get_node("AnimatedSprite2D")
	sprite.play("ShieldBreak")
	await get_tree().create_timer(0.4).timeout
	garnet_shield.visible = false
	garnet_shield_active = false


# HEALING

func heal():
	garnet_health = min(garnet_health + 1, garnet_max_health)
	print("Garnet healed 1 HP. HP =", garnet_health)
	update_hearts()


# WINNING

func ruby_died():
	print("Ruby died!")
	GameManager.defeated_rubies.append(GameManager.current_ruby_id)
	GameManager.garnet_health = garnet_health
	
	await get_tree().process_frame
	return_to_previous_scene()

func return_to_previous_scene():
	if GameManager.previous_scene_path == "":
		get_tree().change_scene_to_file("res://Scene/level_1.tscn")
	else:
		get_tree().change_scene_to_file(GameManager.previous_scene_path)
