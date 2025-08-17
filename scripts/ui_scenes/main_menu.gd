extends Control

func _ready():
	ResourceManager.loadResources();
	var btn_normal_pic = load("res://resources/ui_component/ui_asset/button_off.png")
	var btn_press_pic = load("res://resources/ui_component/ui_asset/button_on.png")

	# Connect button signals
	var start = get_node("VBoxContainer/StartButton")
	start.pressed.connect(_on_start_pressed)
	var option = get_node("VBoxContainer/OptionsButton")
	option.pressed.connect(_on_options_pressed)
	var exit = get_node("VBoxContainer/ExitButton")
	exit.pressed.connect(_on_exit_pressed)
	
	_set_btn_image(start, btn_normal_pic, btn_press_pic)
	_set_btn_image(option, btn_normal_pic, btn_press_pic)
	_set_btn_image(exit, btn_normal_pic, btn_press_pic)
	
func _set_btn_image(btn, normal, press):
	btn.texture_normal = normal
	btn.texture_pressed = press

func _on_start_pressed():
	#get_tree().change_scene_to_file("res://scenes/tower_select_tmp_scene.tscn")  # Change to your actual game scene
	get_tree().change_scene_to_file("res://resources/ui_component/deck_selection.tscn")  # Change to your actual game scene
func _on_options_pressed():
	print("Options menu (To be implemented)")

func _on_exit_pressed():
	get_tree().quit()
