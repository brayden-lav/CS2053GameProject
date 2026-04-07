extends Node
var music_player: AudioStreamPlayer

var previous_scene_path = ""
var current_ruby_id = ""
var defeated_rubies = []
var dialogue_active = false
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


func _ready():
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.finished.connect(_on_music_finished)
	play_music("res://Music/Love Like You (feat. Rebecca Sugar) - Reprise.mp3")

func _on_music_finished():
	music_player.play()
	
func play_music(path: String):
	if music_player.stream != load(path):
		music_player.stream = load(path)
		music_player.play()
