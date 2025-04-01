extends TileMap
class_name Map

@export var mapSize: Vector2;
@export var path: Path2D;
static var availableCells: Array[Vector2];

static func isCellAvailable(cellPos: Vector2) -> bool:
	return availableCells.has(cellPos);
	
func removeAvailableCell(cell: Vector2):
	var index = availableCells.find(cell);
	if(index > -1):
		availableCells.remove_at(index);
		
func addAvailableCell(cell: Vector2):
	if(availableCells.has(cell)):
		return;
		
	availableCells.append(cell);

func setup():
	availableCells = [];
	for y in range(mapSize.y):
		for x in range(mapSize.x):
			var cell_position = Vector2(x, y);
			var source_id = get_cell_source_id(0, cell_position);
			if(source_id != 4): #not path_tile
				availableCells.append(cell_position);
	print("grid size:", availableCells.size());
