extends TileMap
class_name Map

@export var mapSize: Vector2;
@export var path: Path2D;
@onready var path_bake: PathBakeAuto = $Path2D
static var availableCells: Array[Vector2i];

static func isCellAvailable(cellPos: Vector2i) -> bool:
	return availableCells.has(cellPos);
	
func removeAvailableCell(cell: Vector2i):
	var index = availableCells.find(cell);
	if(index > -1):
		availableCells.remove_at(index);
		
func addAvailableCell(cell: Vector2i):
	if(availableCells.has(cell)):
		return;
		
	availableCells.append(cell);

func setup():
	var path = path_bake.bake();
	availableCells = path_bake.get_available_tiles(path, [6]);
	print("grid size:", availableCells.size());
