extends Node2D
# maing it turn by turn
enum Turn { PLAYER, ENEMY }

# State all variables required
var current_turn = Turn.PLAYER

	#health variables
var garnet_health = 0
var garnet_max_health = 10
var boss_health = 10

	#for boss when she uses a shield
var boss_skip_turn = false
	#initialize shield active as false
var garnet_shield_active = false
var boss_shield_active = false
	#lightning cooldown
var lightning_cooldown = 0

var boss_poison_turns = 0
var garnet_poison_turns = 0
var poison_cooldown = 0

	#card array
var cards = []

# VISUAL REFERENCES
	#hearts
@onready var hearts = $Hearts.get_children()
@onready var garnet_heal_heart = $GarnetEffects/HealHeart
@onready var boss_heal_heart = $BossEffects/HealHeart
	#characters
@onready var garnet_node = $GarnetFighting
@onready var boss_node = $RubyFighting
	#effects
@onready var garnet_lightning = $GarnetEffects/Lightning
@onready var garnet_shield = $GarnetEffects/Shield
@onready var garnet_fireball = $GarnetEffects/FireBall
@onready var boss_fireball = $BossEffects/FireBall
@onready var boss_shield_node = $BossEffects/Shield
#effect starting positions defining
var lightning_start_pos
var garnet_shield_pos
var boss_shield_pos
var garnet_fireball_start_pos
var boss_fireball_start_pos


# READY

func _ready():
	randomize() # for boss to randomly pick a card
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
	boss_shield_pos = boss_node.global_position + Vector2(-50, 0)
	garnet_fireball_start_pos = garnet_fireball.global_position
	boss_fireball_start_pos = boss_fireball.global_position

	# Hide effects
	garnet_lightning.visible = false
	garnet_shield.visible = false
	boss_shield_node.visible = false
	garnet_fireball.visible = false
	boss_fireball.visible = false
	garnet_heal_heart.visible = false
	boss_heal_heart.visible = false

	start_player_turn()

# TURN SYSTEM

func start_player_turn():
	current_turn = Turn.PLAYER
	if garnet_poison_turns > 0:
		print("Garnet takes 1 poison damage")
		damage_garnet(1)
		garnet_poison_turns -= 1
	#shield disappears at start of Boss's next turn if it was a defensive shield
	if boss_shield_active and not boss_skip_turn:
		boss_shield_node.visible = false
		boss_shield_active = false
	
	#break Garnet shield
	if garnet_shield_active:
		await play_garnet_shield_break()
	garnet_shield_active = false
	
	if lightning_cooldown > 0:
		lightning_cooldown -= 1
	if poison_cooldown > 0:
		poison_cooldown -= 1
	show_cards(true)

func start_enemy_turn():
	current_turn = Turn.ENEMY
	if boss_poison_turns > 0:
		print("Boss takes 1 poison damage")
		damage_boss(1)
		boss_poison_turns -= 1
	show_cards(false)

	if boss_skip_turn:
		print("Boss skips turn!")
		boss_skip_turn = false # so Boss can act next turn
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
		if card.name == "Card5" and poison_cooldown > 0:
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
		if card.name == "Card1" or card.name == "Card3" or card.name == "Card4" or card.name == "Card2": #makes the fight go a bit smoother to use only the 3 cards
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
			heal(is_player)
		"Card3":
			await shield(is_player) # await added to ensure Boss shows animation
		"Card4":
			await lightning(is_player, 2) #wait for the animations to be played
		"Card5":
			await poison(is_player)

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

func damage_boss(amount):
	if boss_shield_active:
		print("Boss blocked attack!")
		await play_boss_shield_break() # shield disappears after blocking
		return
	
	boss_health -= amount
	print("Boss takes", amount, "damage. HP =", boss_health)
	if boss_health <= 0:
		boss_died()

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

func poison(is_player):
	if is_player:
		print("Boss is poisoned!")
		boss_poison_turns = 3
		poison_cooldown = 4
	else:
		print("Garnet is poisoned!")
		garnet_poison_turns = 3

func fireball(is_player, damage):
	if is_player:
		await play_attack_animation(garnet_node)
		await play_fireball(garnet_fireball, garnet_node.global_position, boss_node.global_position, true)
		damage_boss(damage)
	else:
		await play_attack_animation(boss_node)
		await play_fireball(boss_fireball, boss_node.global_position, garnet_node.global_position, false)
		damage_garnet(damage)

func play_fireball(node, from_pos, to_pos, is_player):
	node.global_position = from_pos
	node.visible = true
	var sprite = node.get_node("AnimatedSprite2D")
	sprite.stop()
	sprite.frame = 0
	sprite.play("default")
	
	var target = to_pos
	
	if is_player and boss_shield_active:
		target = boss_shield_pos
	elif !is_player and garnet_shield_active:
		target = garnet_shield_pos
	
	var tween = create_tween()
	tween.tween_property(node, "global_position", target, 0.5)
	await tween.finished
	
	await get_tree().create_timer(0.15).timeout
	
	if is_player and boss_shield_active:
		await play_boss_shield_break()
	
	sprite.stop()
	sprite.frame = 0
	node.visible = false

func lightning(is_player, damage):
	if is_player:
		await play_attack_animation(garnet_node)
		await play_lightning(garnet_node.global_position, boss_node.global_position, true)
		print("Lightning hits Boss for", damage)
		damage_boss(damage)
		lightning_cooldown = 2
	else:
		await play_attack_animation(boss_node)
		await play_lightning(boss_node.global_position, garnet_node.global_position, false)
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
	if is_player and boss_shield_active:
		target = boss_shield_pos
	elif !is_player and garnet_shield_active:
		target = garnet_shield_pos
	
	var tween = create_tween()
	tween.tween_property(garnet_lightning, "global_position", target, 0.5)
	await tween.finished
	
	await get_tree().create_timer(0.15).timeout
	
	if is_player and boss_shield_active:
		await play_boss_shield_break()
	
	sprite.stop()
	sprite.frame = 0
	garnet_lightning.visible = false
	garnet_lightning.global_position = lightning_start_pos

func shield(is_player):
	if is_player:
		garnet_shield_active = true
		garnet_shield.visible = true
		garnet_shield.global_position = garnet_shield_pos
		garnet_shield.scale.x = -1
		garnet_shield.get_node("AnimatedSprite2D").play("ShieldUp")
	else:
		boss_shield_active = true
		boss_shield_node.visible = true
		boss_shield_node.global_position = boss_shield_pos
		await play_attack_animation(boss_node)
		boss_shield_node.get_node("AnimatedSprite2D").play("ShieldUp")
		boss_skip_turn = true


# SHIELD BREAK

func play_boss_shield_break():
	var sprite = boss_shield_node.get_node("AnimatedSprite2D")
	sprite.play("ShieldBreak")
	await get_tree().create_timer(0.4).timeout
	boss_shield_node.visible = false
	boss_shield_active = false

func play_garnet_shield_break():
	var sprite = garnet_shield.get_node("AnimatedSprite2D")
	sprite.play("ShieldBreak")
	await get_tree().create_timer(0.4).timeout
	garnet_shield.visible = false
	garnet_shield_active = false


# HEALING

func heal(is_player):
	if is_player:
		garnet_health = min(garnet_health + 1, garnet_max_health)
		print("Garnet healed 1 HP. HP =", garnet_health)
		update_hearts()
		
		await play_heal_effect(garnet_heal_heart)
	else:
		boss_health += 1
		print("Boss healed 1 HP. HP = ", boss_health)
		update_hearts()
		
		await play_heal_effect(boss_heal_heart)

func play_heal_effect(node, duration := 1.0):
	node.visible = true
	
	var sprite = node.get_node("AnimatedSprite2D")
	sprite.stop()
	sprite.frame = 0
	sprite.play("life")
	
	await get_tree().create_timer(duration).timeout
	
	node.visible = false

# WINNING

func boss_died():
	print("Boss died!")
	GameManager.defeated_rubies.append(GameManager.current_ruby_id)
	GameManager.garnet_health = garnet_health
	
	await get_tree().process_frame
	return_to_previous_scene()

func return_to_previous_scene():
	if GameManager.previous_scene_path == "":
		get_tree().change_scene_to_file("res://Scene/fighting_Boss.tscn")
	else:
		get_tree().change_scene_to_file(GameManager.previous_scene_path)
