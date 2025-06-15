extends Node

const CELL_SIZE: int = 512

static func WorldToCell(world_position: Vector2) -> Vector2i:
	# Subtract half cell size before flooring to center-align
	return Vector2i(floor((world_position.x - CELL_SIZE / 2) / CELL_SIZE), floor((world_position.y - CELL_SIZE / 2) / CELL_SIZE))

static func CellToWorld(cell_position: Vector2i) -> Vector2:
	# Add half cell size to center the position in the world
	return Vector2(cell_position.x * CELL_SIZE + CELL_SIZE / 2, cell_position.y * CELL_SIZE + CELL_SIZE / 2)

	
static func snapToGrid(screenSize, position):
	var gridX = floor(position.x / CELL_SIZE) * CELL_SIZE + CELL_SIZE / 2
	var gridY = floor(position.y / CELL_SIZE) * CELL_SIZE + CELL_SIZE / 2
	return Vector2(gridX, gridY)
