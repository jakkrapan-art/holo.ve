extends Node2D
var GRID_SIZE = 64;

@onready var spr: Sprite2D = $Sprite2D

func _process(delta):
	var mousePos = get_global_mouse_position()
	var gridPos = snapToGrid(mousePos)
	position = gridPos
	
	var avail = isAvailable();
	updateSpriteColor(avail);

func snapToGrid(position):
	var screenSize = get_viewport().size;
	position = Vector2(clamp(position.x, 0, screenSize.x - GRID_SIZE), clamp(position.y, 0, screenSize.y - GRID_SIZE));
	var gridX = floor(position.x / GRID_SIZE) * GRID_SIZE + GRID_SIZE / 2
	var gridY = floor(position.y / GRID_SIZE) * GRID_SIZE + GRID_SIZE / 2
	
	return Vector2(gridX, gridY)

func isAvailable():
	if ((roundi(position.x / GRID_SIZE) % 2 == 1 && roundi(position.y / GRID_SIZE) % 2 == 0) ||
		(roundi(position.x / GRID_SIZE) % 2 == 0 && roundi(position.y / GRID_SIZE) % 2 == 1)):
		return false
	return true

func updateSpriteColor(available: bool):
	if (available):
		spr.self_modulate = Color("#ffffff", 1);
	else:
		spr.self_modulate = Color("#ff0000", 1);
