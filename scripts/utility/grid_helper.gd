extends Node

const CELL_SIZE: int = 512

static func WorldToCell(world_position: Vector2) -> Vector2i:
	return Vector2i(floor(world_position.x / CELL_SIZE), floor(world_position.y / CELL_SIZE))

static func CellToWorld(cell_position: Vector2i) -> Vector2:
	return Vector2(cell_position * CELL_SIZE)
	
static func snapToGrid(screenSize, position):
	var gridX = floor(position.x / CELL_SIZE) * CELL_SIZE + CELL_SIZE / 2
	var gridY = floor(position.y / CELL_SIZE) * CELL_SIZE + CELL_SIZE / 2
	return Vector2(gridX, gridY)
