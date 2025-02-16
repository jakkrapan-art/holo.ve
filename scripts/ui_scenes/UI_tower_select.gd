class_name UITowerSelect
extends Node

# Signal to send selection back to the stage
signal tower_select(num_select)

func _ready():
	for button in get_tree().get_nodes_in_group("tower_buttons"):
		button.pressed.connect(Callable(self, "_on_select_tower_button").bind(button.name))

func _on_select_tower_button(num):
	print("signal: tower_select,"+str(num))
	emit_signal("tower_select", num)
	queue_free()
	#get_tree().quit()
