extends Node2D
class_name Player

var maxHp: int;
var currentHp: int;

var ui: PlayerUI;
@export var uiTemplate: PackedScene;

func _ready():
	setup(1000);

func setup(hp: int):
	currentHp = hp;
	maxHp = hp;
	
	createUI();

func createUI():
	if(!uiTemplate.can_instantiate()):
		return;

	var uiCanvas = CanvasLayer.new();
	add_child(uiCanvas);

	ui = uiTemplate.instantiate() as PlayerUI
	uiCanvas.add_child(ui);
	ui.setup(maxHp);

func updateHp(updateAmount: int):
	currentHp += updateAmount;
	ui.updateBar(currentHp);
