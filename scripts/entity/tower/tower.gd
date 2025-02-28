extends Node2D
class_name Tower
var GRID_SIZE = 64;

@onready var spr: Sprite2D = $Sprite2D
@export var isMoving: bool = false;
var enableAttack: bool = true;
var isOnValidCell: bool = false;
var inPlaceMode: bool = false;
@onready var attackController: AttackController = $AttackController;

var onPlace: Callable;
var onRemove: Callable;

var enemy: Enemy = null;

func _ready():
	if(attackController != null):
		attackController.setup(10, 0.2);

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		if(!inPlaceMode):
			enterPlaceMode();
		else:
			exitPlaceMode();

func _process(delta):
	if isMoving:
		var mousePos = get_global_mouse_position()
		var gridPos = snapToGrid(mousePos);
		position = gridPos;
		updateTowerState();

	if enableAttack:
		attackEnemy();

func setup(sprite: Texture, onPlace: Callable, onRemove: Callable):
	if(sprite != null):
		self.spr.texture = sprite;
	self.onPlace = onPlace;
	self.onRemove = onRemove;

func enterPlaceMode():
	isMoving = true;
	enableAttack = false;
	
	inPlaceMode = true;
	var cell = GridHelper.WorldToCell(position);
	onRemove.call(cell);
	
func  exitPlaceMode():
	if(!isOnValidCell):
		return;
	
	isMoving = false;
	enableAttack = true;
	inPlaceMode = false;
	
	var cell = GridHelper.WorldToCell(position);
	onPlace.call(cell);

func snapToGrid(position):
	var screenSize = get_viewport().size;
	position = Vector2(clamp(position.x, 0, screenSize.x - GRID_SIZE), clamp(position.y, 0, screenSize.y - GRID_SIZE));
	var gridX = floor(position.x / GRID_SIZE) * GRID_SIZE + GRID_SIZE / 2
	var gridY = floor(position.y / GRID_SIZE) * GRID_SIZE + GRID_SIZE / 2
	
	return Vector2(gridX, gridY)

func attackEnemy():
	if(enemy != null && attackController != null):
		attackController.attack(enemy);

func isAvailable():
	return true;

func updateTowerState():
	var cellPos = GridHelper.WorldToCell(position);
	var valid = Map.isCellAvailable(cellPos);
	updateSpriteColor(valid);
	isOnValidCell = valid;

func updateSpriteColor(available: bool):
	if (available):
		spr.self_modulate = Color("#ffffff", 1);
	else:
		spr.self_modulate = Color("#ff0000", 1);

func _onEnemyDetected(enemy: Enemy):
	if(self.enemy != null):
		return;

	self.enemy = enemy;	
	Utility.ConnectSignal(self.enemy, "onDead", Callable(self, "clearEnemy"));
	Utility.ConnectSignal(self.enemy, "onReachEndPoint", Callable(self, "clearEnemy"));

func clearEnemy():
	enemy = null;
