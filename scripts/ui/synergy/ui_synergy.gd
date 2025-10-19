extends Control
class_name UISynergy

var synergyDatas: Dictionary = {};
var contentList: Dictionary = {};

@onready var camera: Camera2D = $"../../Camera2D"
@export var contentTemplate: PackedScene;

var currentYPos = 0;

func _ready() -> void:
	addNewSynergy("test1", 10, 20);

func hasContent(name: String):
	return synergyDatas.has(name);

func addNewSynergy(name: String, min: int, max: int):
	if(synergyDatas.has(name)):
		printerr("adding exist synergy: ", name);
		return;

	synergyDatas[name] = {"current": 0, "max": max, "min": min};

func addSynergy(synergyName: String):
	if !synergyDatas.has(synergyName):
		print("adding not exist synergy: ", synergyName);
		return;

	var data = synergyDatas.get(synergyName);
	var newVal = data.get("current", 0) + 1;
	var minActive = data.get("min", 0);
	var active = false if minActive <= 0 else newVal >= minActive;
	synergyDatas[synergyName]["current"] = newVal;
	if(contentList.has(synergyName)):
		var existContent: UISynergyContent = contentList.get(synergyName);
		existContent.setup(synergyName, newVal, data.get("max", 0), active);
	else:
		createContent(synergyName, newVal, data.get("max", 0), active);

func createContent(synergyName: String, current: int, maxCount: int, active: bool):
	var newContent = contentTemplate.instantiate() as UISynergyContent;
	contentList[synergyName] = newContent;
	add_child(newContent);
	newContent.position.y = currentYPos;
	currentYPos += 100;
	newContent.setup(synergyName, current, maxCount, active);
