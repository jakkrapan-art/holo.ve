extends Node
class_name UIToggle

@onready var activeObj = $Active;
@onready var inactiveObj = $Inactive;

@export var active = false;

func _ready() -> void:
	activeObj.visible = active;
	inactiveObj.visible = !active;

func toggleActive(isActive: bool):
	activeObj.visible = isActive;
	inactiveObj.visible = !isActive;
