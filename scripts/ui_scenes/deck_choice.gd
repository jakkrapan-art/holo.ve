extends Control

signal deck_selected(deck_name: String)

var deck_key: String

func set_deck_info(deck_name: String, deck_info: Dictionary):
	deck_key = deck_name

	if deck_info.has("sprite"):
		var sprite_path = "res://resources/" + deck_info["sprite"]
		if ResourceLoader.exists(sprite_path):
			$Panel/DeckImage.texture = load(sprite_path)
		else:
			print("Warning: Sprite not found at", sprite_path)
			
	# 💡 This ensures the button actually works
	$Panel/DeckImage/Button.pressed.connect(_on_SelectButton_pressed)

func _on_SelectButton_pressed():
	deck_selected.emit(deck_key)
