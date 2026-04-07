extends Node

var previous_scene_path = ""
var current_ruby_id = ""
var defeated_rubies = []
var previous_player_position: Vector2 = Vector2.ZERO
var level_1_completed = false
var level_2_completed = false
var level_3_completed = false
var current_level = 1
var defaultSpotlight = false
# Garnet health persists across scenes
var garnet_health: int = 10

# NEW: Max health
var garnet_max_health: int = 10
