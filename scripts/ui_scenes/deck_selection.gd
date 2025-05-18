extends Control

@export var decks: Array[Dictionary]  # List of all decks
@export var characters: Array[Dictionary]  # List of characters

var _data
var selected_deck: String = ""
var current_character_index: int = 0

func _ready():
	_load_deck();
	#_setup_filters()
	#_display_character()
	_setup_buttons()

func _load_deck():
	_data = YamlParser.load_data("res://resources/database/decks.yaml")
	print("Loaded JSON Data: ", _data.keys())
	
	var outdata = YamlParser.load_data("res://resources/database/towers_data_test.yaml")

	for deck_name in data.keys():
		var deck_info = data[deck_name]
		
		var deck_choice = preload("res://resources/ui_component/deck_choice.tscn").instantiate()
		
		deck_choice.set_deck_info(deck_name, deck_info)
		deck_choice.deck_selected.connect(_on_deck_selected)
		
		$MainPanel/DeckContainer.add_child(deck_choice)

func _setup_filters():
	for filter_button in %FilterButtons.get_children():
		filter_button.pressed.connect(Callable(self, "_on_filter_pressed").bind(filter_button.name))

func _display_character():
	var char = characters[current_character_index]
	%CharacterImage.texture = load(char["image"])
	%CharacterName.text = char["name"]
	%CharacterDescription.text = char["description"]

func _setup_buttons():
	get_node("Start").pressed.connect(_on_confirm)
	get_node("Back").pressed.connect(_on_exit)
	#%NextButton.pressed.connect(_on_next_character)
	#%PrevButton.pressed.connect(_on_prev_character)

func _on_filter_pressed(filter_type: String):
	# Filter decks by type (Fast, Strong, Trick)
	for deck_button in %StarDecks.get_children() + %PlatinumDecks.get_children():
		deck_button.visible = deck_button.deck_type == filter_type

func _on_next_character():
	current_character_index = (current_character_index + 1) % characters.size()
	_display_character()

func _on_prev_character():
	current_character_index = (current_character_index - 1 + characters.size()) % characters.size()
	_display_character()

func _on_deck_selected(deck_name: String):
	selected_deck = deck_name
	print("Selected Deck:", selected_deck)
	$Start.disabled = false
	
func _on_confirm():
	print("Deck selected:", selected_deck)
	Global.selected_deck = selected_deck
	Global.selected_data_file = selected_deck
	#print("Character selected:", characters[current_character_index])
	get_tree().change_scene_to_file("res://scenes/dev_scene.tscn")

func _on_exit():
	get_tree().change_scene_to_file("res://MainMenu.tscn")
