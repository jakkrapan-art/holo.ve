extends Node2D
class_name MapGenerator

@onready var tilemap: TileMap = $TileMap

func _ready():
	pass

func _process(delta):
	pass

func generate(width: int, height: int):
	pass

func setTile(cell: Vector2i, tileIndx: int):
	pass
