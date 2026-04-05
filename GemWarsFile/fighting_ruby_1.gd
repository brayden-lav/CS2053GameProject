extends Node2D

enum Turn {
	PLAYER,
	ENEMY
}

var current_turn = Turn.PLAYER
var cards = []
var ruby_health = 10


func _ready():
	randomize()
	cards = $Cards.get_children()
	start_player_turn()

# ------------------------
# TURN MANAGEMENT
# ------------------------

func start_player_turn():
	current_turn = Turn.PLAYER
	show_cards(true)

func start_enemy_turn():
	current_turn = Turn.ENEMY
	show_cards(false)
	
	await get_tree().process_frame  # ensures we're still in tree
	
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
	
	print("Player picked:", card.name)
	resolve_card(card, true)
	start_enemy_turn()

# ------------------------
# ENEMY ACTION
# ------------------------

func enemy_pick_card():
	var random_card = cards[randi() % cards.size()]
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
			heal(is_player)
		"Card3":
			shield(is_player)
		"Card4":
			lightning(is_player, 2)

# ------------------------
# DAMAGE CALCULATIONS
# ------------------------
func damage_ruby(amount):
	ruby_health -= amount
	print("Ruby HP:", ruby_health)
	
	if ruby_health <= 0:
		ruby_died()

func ruby_died():
	print("Ruby died!")
	
	GameManager.defeated_rubies.append(GameManager.current_ruby_id)
	
	return_to_previous_scene()

func return_to_previous_scene():
	get_tree().change_scene_to_file(GameManager.previous_scene_path)

# ------------------------
# ABILITIES
# ------------------------

func fireball(is_player, damage):
	if is_player:
		print("Ruby used FireBall on Garnet for", damage)
	else:
		print("Garnet used FireBall on Ruby for", damage)
		damage_ruby(damage)

func lightning(is_player, damage):
	if is_player:
		print("Ruby used Lightning on Garnet for", damage)
	else:
		print("Garnet used Lightning on Ruby for", damage)
		damage_ruby(damage)

func shield(is_player):
	print("Ruby uses Shield" if is_player else "Garnet uses Shield")

func heal(is_player):
	print("Ruby healed 1 HP" if is_player else "Garnet healed 1 HP")
