@tool
extends EditorPlugin

var plugin = preload("res://addons/map_setting/map_setting_inspector.gd");

func _enter_tree():
	plugin = plugin.new();
	add_inspector_plugin(plugin)


func _exit_tree():
	remove_inspector_plugin(plugin);
