extends PanelContainer
class_name UISynergyContent

@onready var bg = $"."
@onready var synergyName = $HBoxContainer/VBoxContainer/SynergyName
@onready var synergyValue = $HBoxContainer/VBoxContainer/SynergyValue

func setup(name: String, current: int, max: int, active: bool):
	if bg != null:
		var style = bg.get_theme_stylebox("panel");
		if(style != null):
			style.bg_color = Color("#F3B578") if active else Color("#4D4D4D");

	if synergyName != null:
		synergyName.text = name

	if synergyValue != null:
		synergyValue.text = str(current) + "/" + str(max)
