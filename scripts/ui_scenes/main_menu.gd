extends Control

func _ready():
	ResourceManager.loadResources();

	# Connect button signals
	get_node("VBoxContainer/StartButton").pressed.connect(_on_start_pressed)
	get_node("VBoxContainer/OptionsButton").pressed.connect(_on_options_pressed)
	get_node("VBoxContainer/ExitButton").pressed.connect(_on_exit_pressed)

func _on_start_pressed():
	#get_tree().change_scene_to_file("res://scenes/tower_select_tmp_scene.tscn")  # Change to your actual game scene
	get_tree().change_scene_to_file("res://resources/ui_component/deck_selection.tscn")  # Change to your actual game scene
func _on_options_pressed():
	print("Options menu (To be implemented)")

func _on_exit_pressed():
	get_tree().quit()
