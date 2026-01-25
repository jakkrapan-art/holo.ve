extends TileMap
class_name Map

static var mapSize: Vector2 = Vector2(11, 10);
static var startX: int = 8;
static var startY: int = 3;

@export var path: Path2D;
@onready var path_bake: PathBakeAuto = $Path2D
static var availableCells: Array[Vector2i];

static func isCellAvailable(cellPos: Vector2i) -> bool:
	if(cellPos.x < startX || cellPos.y < startY || cellPos.x > startX + mapSize.x || cellPos.y > startY + mapSize.y):
		return false;
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
