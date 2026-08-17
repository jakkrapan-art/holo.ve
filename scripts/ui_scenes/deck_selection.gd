extends Control

@export var decks: Array[Dictionary]  # List of all decks
@export var characters: Array[Dictionary]  # List of characters

var _data
var _selected_deck: Dictionary
var current_character_index: int = 0

@export var exitBtn: Button;
@export var startBtn: Button;

@export var deckContainer: Node;
@export var genGroupContainer: Node;
var selectingDeckToggle: UIToggle;

@export var branchFilterContainer: Node;
@export var emptyDeckLabel: Label;

var currentGroupFilter: String = "";
var currentBranchFilter: String = "";

const DEFAULT_GROUP_FILTER: String = "Hololive"
const DEFAULT_BRANCH_FILTER: String = "en"
const VISIBLE_BRANCHES_BY_GROUP: Dictionary = {
	"Hololive": ["en", "jp", "id"],
	"Holostars": ["en", "jp"],
}

# Manager Card display refs — populated dynamically from the selected StaffData.
# (Phase 1 has 1 staff; the script is shaped so adding more entries in staffs.yaml
# + bullets in the scene "just works" without further plumbing.)
@onready var _manager_portrait: TextureRect = $ContentContainer/ManagerField/ManagerCard/CardContainer/ManagerImage/TextureRect
@onready var _manager_name: Label = $ContentContainer/ManagerField/ManagerCard/CardContainer/Name
@onready var _manager_hp_value: Label = $ContentContainer/ManagerField/ManagerCard/CardContainer/HpInfo/HpValue
@onready var _manager_skill_icon: TextureRect = $ContentContainer/ManagerField/ManagerCard/CardContainer/Skill/Icon
@onready var _manager_skill_name: Label = $ContentContainer/ManagerField/ManagerCard/CardContainer/Skill/Name
@onready var _manager_skill_desc: RichTextLabel = $ContentContainer/ManagerField/ManagerCard/CardContainer/Skill/Description

func _ready():
	_load_deck();
	_setup_gen_filter()
	_setup_branch_filter()
	_setup_buttons()
	_setup_staff_card()

	currentGroupFilter = DEFAULT_GROUP_FILTER
	currentBranchFilter = DEFAULT_BRANCH_FILTER
	_refresh_deck_filters()

func _load_deck():
	_data = YamlParser.load_data("res://resources/database/towers/decks/decks.yaml")

	if !is_instance_valid(deckContainer):
		push_error("DeckContainer node is not valid. Please check the scene hierarchy.");
		return

	for deck_name in _data.keys():
		var deck_info = _data[deck_name]

		var deck_choice = preload("res://resources/ui_component/deck_choice.tscn").instantiate()

		deck_choice.set_deck_info(deck_name, deck_info)
		deck_choice.deck_selected.connect(_on_deck_selected)

		deckContainer.add_child(deck_choice)

func _setup_gen_filter():
	var genGroupBtn = genGroupContainer.get_children();

	for filter_button in genGroupBtn:
		filter_button.pressed.connect(Callable(self, "_on_gen_filter_pressed").bind(filter_button.name))

func _setup_branch_filter():
	var branchGroupBtn = branchFilterContainer.get_children();

	for filter_button in branchGroupBtn:
		filter_button.pressed.connect(Callable(self, "_on_branch_filter_pressed").bind(filter_button.name.to_lower()))

func _display_character():
	var character = characters[current_character_index]
	%CharacterImage.texture = load(character["image"])
	%CharacterName.text = character["name"]
	%CharacterDescription.text = character["description"]

func _setup_buttons():
	if is_instance_valid(startBtn):
		startBtn.pressed.connect(_on_confirm)
		setActiveStartBtn(false)
	if is_instance_valid(exitBtn):
		exitBtn.pressed.connect(_on_exit)
	#%NextButton.pressed.connect(_on_next_character)
	#%PrevButton.pressed.connect(_on_prev_character)

func _on_gen_filter_pressed(target_gen: String):
	if not VISIBLE_BRANCHES_BY_GROUP.has(target_gen):
		return
	var nextBranchFilter: String = currentBranchFilter
	var visibleBranches: Array = _visible_branches_for_group(target_gen)
	if not visibleBranches.has(nextBranchFilter):
		nextBranchFilter = DEFAULT_BRANCH_FILTER
	if target_gen == currentGroupFilter and nextBranchFilter == currentBranchFilter:
		return

	_clear_deck_selection()
	currentGroupFilter = target_gen
	currentBranchFilter = nextBranchFilter
	_refresh_deck_filters()

func _on_branch_filter_pressed(target_branch: String):
	if not _visible_branches_for_group(currentGroupFilter).has(target_branch):
		return
	if target_branch == currentBranchFilter:
		return

	_clear_deck_selection()
	currentBranchFilter = target_branch
	_refresh_deck_filters()

func _visible_branches_for_group(target_group: String) -> Array:
	return VISIBLE_BRANCHES_BY_GROUP.get(target_group, [DEFAULT_BRANCH_FILTER])

func _refresh_deck_filters():
	for filter_button in genGroupContainer.get_children():
		_set_filter_toggle(filter_button, filter_button.name == currentGroupFilter)

	var visibleBranches: Array = _visible_branches_for_group(currentGroupFilter)
	for filter_button in branchFilterContainer.get_children():
		var branchName: String = filter_button.name.to_lower()
		filter_button.visible = visibleBranches.has(branchName)
		_set_filter_toggle(filter_button, filter_button.visible and branchName == currentBranchFilter)

	var visibleDeckCount: int = 0
	for deck_button in deckContainer.get_children():
		deck_button.visible = deck_button.group == currentGroupFilter and deck_button.branch == currentBranchFilter
		if deck_button.visible:
			visibleDeckCount += 1

	_clear_hidden_deck_selection()
	if is_instance_valid(emptyDeckLabel):
		emptyDeckLabel.visible = visibleDeckCount == 0

func _set_filter_toggle(filter_button: Node, is_active: bool):
	var toggleChild = filter_button.find_child("Toggle")
	if toggleChild and toggleChild is UIToggle:
		(toggleChild as UIToggle).toggleActive(is_active)

func _clear_hidden_deck_selection():
	if _selected_deck.is_empty():
		return
	if _selected_deck.get("group", "") == currentGroupFilter and _selected_deck.get("branch", "") == currentBranchFilter:
		return
	_clear_deck_selection()

func _clear_deck_selection():
	if is_instance_valid(selectingDeckToggle):
		selectingDeckToggle.toggleActive(false)
	selectingDeckToggle = null
	_selected_deck = {}
	setActiveStartBtn(false)

func _on_next_character():
	current_character_index = (current_character_index + 1) % characters.size()
	_display_character()

func _on_prev_character():
	current_character_index = (current_character_index - 1 + characters.size()) % characters.size()
	_display_character()

func _on_deck_selected(deck_name: String, toggle: UIToggle):
	if (selectingDeckToggle):
		selectingDeckToggle.toggleActive(false)

	if (toggle):
		toggle.toggleActive(true)
		selectingDeckToggle = toggle

	_selected_deck = _data[deck_name].duplicate()
	setActiveStartBtn(true)

func setActiveStartBtn(isActive: bool):
	if (startBtn):
		startBtn.disabled = !isActive
		var toggleChild = startBtn.find_child("Toggle");
		if toggleChild and toggleChild is UIToggle:
			var startToggle = toggleChild as UIToggle
			startToggle.toggleActive(isActive);

func _on_confirm():
	if _selected_deck.is_empty() or not _selected_deck.has("name") or not _selected_deck.has("data_file"):
		setActiveStartBtn(false)
		return
	TowerCenter.selected_deck = _selected_deck["name"]
	TowerCenter.selected_data_file = _selected_deck["data_file"]
	# Staff selection: persisted via StaffCenter.selected_staff (already set by _refresh_staff_card on bullet/arrow).
	get_tree().change_scene_to_file("res://scenes/dev_scene.tscn")

func _setup_staff_card():
	# Mirror of _load_deck for staffs — populate StaffCenter, then push the
	# currently-selected staff into the Manager Card display nodes.
	StaffCenter.loadAllStaffs()
	_refresh_staff_card()

func _refresh_staff_card():
	var data: StaffData = StaffCenter.getSelectedStaff()
	if data == null:
		push_warning("DeckSelection._refresh_staff_card: no selected staff in StaffCenter")
		return

	if data.selection_portrait != "":
		var portrait_path = "res://resources/" + data.selection_portrait
		if ResourceLoader.exists(portrait_path):
			_manager_portrait.texture = load(portrait_path)
	if data.name != "":
		_manager_name.text = data.name
	_manager_hp_value.text = str(data.max_hp)

	if data.hud_skill_icon != "":
		var icon_path = "res://resources/" + data.hud_skill_icon
		if ResourceLoader.exists(icon_path):
			_manager_skill_icon.texture = load(icon_path)
	# Skill text goes through the display metadata path (tokens resolve; a plain
	# desc renders as-is). Fall back to scene placeholder text when staff has no
	# skill defined or fields are empty.
	if data.skill != null:
		if data.skill.get_display_name(1) != "":
			_manager_skill_name.text = data.skill.get_display_name(1)
		var skill_desc: String = data.skill.get_display_desc(1)
		if skill_desc != "":
			_manager_skill_desc.text = skill_desc

func _on_exit():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
