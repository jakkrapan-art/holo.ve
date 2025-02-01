extends Node2D
var GRID_SIZE = 64;

@onready var spr: Sprite2D = $Sprite2D
@export var enableMove: bool = false;
@onready var attackController: AttackController = $AttackController;

var enemy: Enemy = null;

func _ready():
	if(attackController != null):
		attackController.setup(10, 0.2);

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		print("Space was pressed!")
		enableMove = !enableMove

func _process(delta):
	if enableMove:
		var mousePos = get_global_mouse_position()
		var gridPos = snapToGrid(mousePos)
		position = gridPos;
		
		var avail = isAvailable();
		updateSpriteColor(avail);
	
	attackEnemy();

func setEnableMove(enable: bool):
	enableMove = enable;

func snapToGrid(position):
	var screenSize = get_viewport().size;
	position = Vector2(clamp(position.x, 0, screenSize.x - GRID_SIZE), clamp(position.y, 0, screenSize.y - GRID_SIZE));
	var gridX = floor(position.x / GRID_SIZE) * GRID_SIZE + GRID_SIZE / 2
	var gridY = floor(position.y / GRID_SIZE) * GRID_SIZE + GRID_SIZE / 2
	
	return Vector2(gridX, gridY)

func attackEnemy():
	if(enemy != null && attackController != null):
		attackController.attack(enemy);
	pass;

func isAvailable():
	return true

func updateSpriteColor(available: bool):
	if (available):
		spr.self_modulate = Color("#ffffff", 1);
	else:
		spr.self_modulate = Color("#ff0000", 1);

func _onEnemyDetected(enemy: Enemy):
	if(self.enemy == null):
		self.enemy = enemy;
