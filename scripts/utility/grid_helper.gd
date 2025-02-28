extends Node

class_name GridHelper

const CELL_SIZE: int = 64

static func WorldToCell(world_position: Vector2) -> Vector2i:
	return Vector2i(floor(world_position.x / CELL_SIZE), floor(world_position.y / CELL_SIZE))

static func CellToWorld(cell_position: Vector2i) -> Vector2:
	return Vector2(cell_position * CELL_SIZE)
