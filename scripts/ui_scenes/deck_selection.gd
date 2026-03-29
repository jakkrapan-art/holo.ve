extends Control

@export var decks: Array[Dictionary]  # List of all decks
@export var characters: Array[Dictionary]  # List of characters

var _data
var _selected_deck: Dictionary
var current_character_index: int = 0

func _ready():
	_load_deck();
	_setup_gen_filter()
	_setup_branch_filter()
	_setup_buttons()

func _load_deck():
	_data = YamlParser.load_data("res://resources/database/towers/decks/decks.yaml")
	print("Loaded JSON Data: ", _data.keys())

	for deck_name in _data.keys():
		var deck_info = _data[deck_name]

		var deck_choice = preload("res://resources/ui_component/deck_choice.tscn").instantiate()

		deck_choice.set_deck_info(deck_name, deck_info)
		deck_choice.deck_selected.connect(_on_deck_selected)

		$MainPanel/DeckContainer.add_child(deck_choice)

func _setup_gen_filter():
	var genGroupBtn = $MainPanel/GenGroupContainer.get_children();

	for filter_button in genGroupBtn:
		filter_button.pressed.connect(Callable(self, "_on_gen_filter_pressed").bind(filter_button.name))

	if(genGroupBtn.size() > 0): # Set default filter to first button's group
		_on_gen_filter_pressed(genGroupBtn[0].name);

func _setup_branch_filter():
	var branchGroupBtn = $MainPanel/BranchFilterContainer.get_children();

	for filter_button in branchGroupBtn:
		filter_button.pressed.connect(Callable(self, "_on_branch_filter_pressed").bind(filter_button.name.to_lower()))

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

func _on_gen_filter_pressed(target_gen: String):
	# Filter decks by type (Fast, Strong, Trick)
	print("Filter pressed:", target_gen)
	for deck_button in $MainPanel/DeckContainer.get_children():
		print("Checking deck:", deck_button.group, "against filter:", target_gen)
		deck_button.visible = deck_button.group == target_gen
		print("Deck visible:", deck_button.visible)

func _on_branch_filter_pressed(target_branch: String):
	# Filter decks by branch (EN, JP, KR)
	print("Branch filter pressed:", target_branch)
	for deck_button in $MainPanel/DeckContainer.get_children():
		print("Checking deck:", deck_button.branch, "against filter:", target_branch)
		deck_button.visible = deck_button.branch == target_branch
		print("Deck visible:", deck_button.visible)

func _on_next_character():
	current_character_index = (current_character_index + 1) % characters.size()
	_display_character()

func _on_prev_character():
	current_character_index = (current_character_index - 1 + characters.size()) % characters.size()
	_display_character()

func _on_deck_selected(deck_name: String):
	_selected_deck = _data[deck_name]
	print("Selected Deck:", _selected_deck)
	$Start.disabled = false

func _on_confirm():
	print("Deck selected:", _selected_deck)
	TowerCenter.selected_deck = _selected_deck["name"]
	TowerCenter.selected_data_file = _selected_deck["data_file"]
	get_tree().change_scene_to_file("res://scenes/dev_scene.tscn")

func _on_exit():
	get_tree().change_scene_to_file("res://MainMenu.tscn")
