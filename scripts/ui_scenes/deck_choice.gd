extends Button

signal deck_selected(deck_name: String, ui_toggle: UIToggle)

var deck_key: String
var group: String;
var branch: String;

@export var image: Image;
@export var toggle: UIToggle;

func set_deck_info(deck_name: String, deck_info: Dictionary):
	deck_key = deck_name
	group = deck_info.get("group", "");
	branch = deck_info.get("branch", "");

	if deck_info.has("sprite"):
		var sprite_path = "res://resources/" + deck_info["sprite"]
		if ResourceLoader.exists(sprite_path) && image:
			image.texture = load(sprite_path)

	# 💡 This ensures the button actually works
	self.pressed.connect(_on_SelectButton_pressed)
	
	var nameLabelActive: Label = $"Toggle/Active/Name"
	if (nameLabelActive):
		nameLabelActive.text = deck_name
		
	var nameLabelInactive: Label = $"Toggle/Inactive/Name";
	if (nameLabelInactive):
		nameLabelInactive.text = deck_name;

func _on_SelectButton_pressed():
	deck_selected.emit(deck_key, toggle)
