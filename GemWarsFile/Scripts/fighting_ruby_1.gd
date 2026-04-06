extends Node2D

enum Turn {
	PLAYER,
	ENEMY
}
#shield variable
var garnet_shield_active = false
var ruby_shield_active = false
#keeping track of turn
var current_turn = Turn.PLAYER
#card array
var cards = []
#ruby health
var ruby_health = 10
var ruby_skip_turn = false
#garnet health
var garnet_max_health = 10
var garnet_health = 0

#lightning cooldown
var lightning_cooldown = 0


func _ready():
	randomize() #randomizes ruby's pick
	cards = $Cards.get_children() #filling card array with cards
	#set garnet health
	garnet_health = GameManager.garnet_health
	garnet_max_health = GameManager.garnet_max_health
	#check garnet health
	if garnet_health <= 0:
		garnet_health = garnet_max_health
	#start game!
	start_player_turn()

# TURN MANAGEMENT

#player's turn
func start_player_turn():
	current_turn = Turn.PLAYER
	
	# REMOVE Garnet shield at start of her turn 
	garnet_shield_active = false
	
	# Reduce lightning cooldown each turn
	if lightning_cooldown > 0:
		lightning_cooldown -= 1
	#make cards visible
	show_cards(true)
#ruby's turn
func start_enemy_turn():
	current_turn = Turn.ENEMY
	
	# Remove Ruby shield at start of its turn
	ruby_shield_active = false
	
	# Check if Ruby should skip this turn (this keeps the game more interactive I find)
	if ruby_skip_turn:
		print("Ruby skips its turn!")
		ruby_skip_turn = false #don't skip next turn unless picking shield again.
		
		await get_tree().create_timer(0.5).timeout
		start_player_turn()
		return
	
	show_cards(false) #Hide for animation/action sequence
	
	await get_tree().process_frame #wait for next tree frame
	
	if !is_inside_tree():
		return
	
	await get_tree().create_timer(1.0).timeout #wait 1 second
	
	if !is_inside_tree():
		return
	
	enemy_pick_card() #make enemy choice

# CARD VISIBILITY
func show_cards(state: bool):
	for card in cards:
		card.visible = state
		card.set_process_input(state)

# PLAYER ACTION
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

#Ruby's turn
func enemy_pick_card():
	# Ruby can ONLY use Fireball (Card1) or Shield (Card3) healing makes game go on too long and lightning HURTS with 10 hp
	var allowed_cards = []
	
	for card in cards: #cycle through cards and find "allowed" cards
		if card.name == "Card1" or card.name == "Card3":
			allowed_cards.append(card)
	
	if allowed_cards.size() == 0:
		return
	
	var random_card = allowed_cards[randi() % allowed_cards.size()] #50/50 between cards
	print("Enemy picked:", random_card.name)
	
	resolve_card(random_card, false)
	start_player_turn()
	
# CARD EFFECT RESOLUTION
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


# DAMAGE CALCULATIONS

#Damaging Ruby
func damage_ruby(amount):
	if ruby_shield_active:
		print("Ruby blocked the attack!")
		return
	
	ruby_health -= amount
	print("Ruby HP:", ruby_health)
	
	if ruby_health <= 0:
		ruby_died()

#Taking damage as garnet
func damage_garnet(amount):
	if garnet_shield_active:
		print("Garnet blocked the attack!")
		return
	
	garnet_health -= amount
	print("Garnet HP:", garnet_health)
	
	if garnet_health <= 0:
		print("Garnet defeated!") #handle end screen here

#handling ruby's death
func ruby_died():
	print("Ruby died!")
	#find what ruby was defeated
	GameManager.defeated_rubies.append(GameManager.current_ruby_id)
	
	# Save health before leaving
	GameManager.garnet_health = garnet_health
	
	# Delay one frame to avoid tree issues
	await get_tree().process_frame
	
	return_to_previous_scene()

func return_to_previous_scene():
	if GameManager.previous_scene_path == "":
		print("ERROR: No previous scene set! Returning to Level 1 fallback.") #added check beacause I was getting crashing errors
		get_tree().change_scene_to_file("res://Scene/level_1.tscn")
	else:
		get_tree().change_scene_to_file(GameManager.previous_scene_path) #also moves to level 1 for now, but will work with any level.

# ABILITIES AND ANIMATIONS (still need to add the animations in the battling sequence)
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
