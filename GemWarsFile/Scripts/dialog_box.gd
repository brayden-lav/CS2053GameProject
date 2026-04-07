extends CanvasLayer

@onready var dialogue_label = $Panel/RichTextLabel
@onready var name_label = $Panel/Label

var dialogues = [
	"In the Gem War of Old, all hope seemed lost...",
	"The Paradime Gems attacked with overwhelming force.",
	"A band of traitors, led by Rose, saw what was good in this world.",
	"We swore to protect the innocent, and were named... the Crystal Gems.",
	"A mighty Rose, a graceful Pearl, and the magical Amethyst and I, led the war efforts.",
	"But calamity struck.",
	"Pearl and Amethyst were lost. The Crystal Gems had fallen.",
	"Now I stand alone, with only my will and resolve.",
	"I have sworn a quest to save my friends and reunite the Crystal Gems.",
	"I must journey through the twisting temple...",
	"... and find the Paradime army general, Jasper...",
	"...and save the Earth.",
	"My quest begins now."
]

var current_index = 0
var is_typing = false

func _ready():
	GameManager.dialogue_active = true
	name_label.text = "Garnet"
	show_dialogue(dialogues[current_index])

func show_dialogue(text: String):
	is_typing = true
	dialogue_label.text = text
	dialogue_label.visible_characters = 0
	while dialogue_label.visible_characters < len(text):
		dialogue_label.visible_characters += 1
		await get_tree().create_timer(0.04).timeout
	is_typing = false

func _input(event):
	if event.is_action_pressed("ui_accept"):
		if is_typing:
			dialogue_label.visible_characters = len(dialogue_label.text)
			is_typing = false
		else:
			current_index += 1
			if current_index < dialogues.size():
				show_dialogue(dialogues[current_index])
			else:
				GameManager.dialogue_active = false
				queue_free()
