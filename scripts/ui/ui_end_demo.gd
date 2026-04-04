class_name UIEndDemo
extends Node

static func create():
	var ui = load("res://resources/ui_component/ui_end_demo.tscn")
	var instantiated = ui.instantiate()
	return instantiated

func _onMainMenuPressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
