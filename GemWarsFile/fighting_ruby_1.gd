extends Node2D

enum Turn {
	PLAYER,
	ENEMY
}
var garnet_shield_active = false
var ruby_shield_active = false
var current_turn = Turn.PLAYER
var cards = []
var ruby_health = 10
var ruby_skip_turn = false
var garnet_max_health = 10

# NEW: Garnet health pulled from GameManager
var garnet_health = 0

# NEW: Lightning cooldown (player only)
var lightning_cooldown = 0


func _ready():
	randomize()
	cards = $Cards.get_children()
	
	garnet_health = GameManager.garnet_health
	garnet_max_health = GameManager.garnet_max_health

	if garnet_health <= 0:
		garnet_health = garnet_max_health
	
	start_player_turn()

# ------------------------
# TURN MANAGEMENT
# ------------------------

func start_player_turn():
	current_turn = Turn.PLAYER
	
	# REMOVE Garnet shield at start of her turn (expired)
	garnet_shield_active = false
	
	# Reduce cooldown each player turn
	if lightning_cooldown > 0:
		lightning_cooldown -= 1
	
	show_cards(true)

func start_enemy_turn():
	current_turn = Turn.ENEMY
	
	# Remove Ruby shield at start of its turn
	ruby_shield_active = false
	
	# Check if Ruby should skip this turn
	if ruby_skip_turn:
		print("Ruby skips its turn!")
		ruby_skip_turn = false
		
		await get_tree().create_timer(0.5).timeout
		start_player_turn()
		return
	
	show_cards(false)
	
	await get_tree().process_frame
	
	if !is_inside_tree():
		return
	
	await get_tree().create_timer(1.0).timeout
	
	if !is_inside_tree():
		return
	
	enemy_pick_card()

# ------------------------
# CARD VISIBILITY
# ------------------------

func show_cards(state: bool):
	for card in cards:
		card.visible = state
		card.set_process_input(state)

# ------------------------
# PLAYER ACTION
# ------------------------

func player_selected_card(card):
	if current_turn != Turn.PLAYER:
		return
	
	# Prevent lightning if on cooldown
	if card.name == "Card4" and lightning_cooldown > 0:
		print("Lightning is on cooldown!")
		return
	
	print("Player picked:", card.name)
	resolve_card(card, true)
	start_enemy_turn()

# ------------------------
# ENEMY ACTION
# ------------------------

func enemy_pick_card():
	# Ruby can ONLY use Fireball (Card1) or Shield (Card3)
	var allowed_cards = []
	
	for card in cards:
		if card.name == "Card1" or card.name == "Card3":
			allowed_cards.append(card)
	
	if allowed_cards.size() == 0:
		return
	
	var random_card = allowed_cards[randi() % allowed_cards.size()]
	print("Enemy picked:", random_card.name)
	
	resolve_card(random_card, false)
	start_player_turn()

# ------------------------
# CARD EFFECT RESOLUTION
# ------------------------

func resolve_card(card, is_player: bool):
	match card.name:
		"Card1":
			fireball(is_player, 1)
		"Card2":
			heal()
		"Card3":
			shield(is_player)
		"Card4":
			lightning(is_player, 2)

# ------------------------
# DAMAGE CALCULATIONS
# ------------------------

func damage_ruby(amount):
	if ruby_shield_active:
		print("Ruby blocked the attack!")
		return
	
	ruby_health -= amount
	print("Ruby HP:", ruby_health)
	
	if ruby_health <= 0:
		ruby_died()

func damage_garnet(amount):
	if garnet_shield_active:
		print("Garnet blocked the attack!")
		return
	
	garnet_health -= amount
	print("Garnet HP:", garnet_health)
	
	if garnet_health <= 0:
		print("Garnet defeated!")

func ruby_died():
	print("Ruby died!")
	
	GameManager.defeated_rubies.append(GameManager.current_ruby_id)
	
	# Save health before leaving
	GameManager.garnet_health = garnet_health
	
	# Delay one frame to avoid tree issues
	await get_tree().process_frame
	
	return_to_previous_scene()

func return_to_previous_scene():
	if GameManager.previous_scene_path == "":
		print("ERROR: No previous scene set! Returning to Level 1 fallback.")
		get_tree().change_scene_to_file("res://Level1.tscn")
	else:
		get_tree().change_scene_to_file(GameManager.previous_scene_path)

# ------------------------
# ABILITIES
# ------------------------

func fireball(is_player, damage):
	if is_player:
		print("Garnet used FireBall on Ruby for", damage)
		damage_ruby(damage)
	else:
		print("Ruby used FireBall on Garnet for", damage)
		damage_garnet(damage)

func lightning(is_player, damage):
	if is_player:
		print("Garnet used Lightning on Ruby for", damage)
		damage_ruby(damage)
		
		lightning_cooldown = 2
	else:
		print("Ruby used Lightning on Garnet for", damage)
		damage_garnet(damage)

func shield(is_player):
	if is_player:
		print("Garnet uses Shield")
		garnet_shield_active = true
	else:
		print("Ruby uses Shield")
		ruby_shield_active = true
		
		# Ruby will skip next turn
		ruby_skip_turn = true

func heal():
		print("Garnet healed 1 HP")
		garnet_health += 1
		
		# Clamp to max health
		if garnet_health > garnet_max_health:
			garnet_health = garnet_max_health
		
		print("Garnet HP:", garnet_health)
