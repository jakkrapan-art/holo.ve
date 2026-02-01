extends TileMap
class_name Map

static var mapSize: Vector2 = Vector2(10, 10);
static var startX: int = 9;
static var startY: int = 3;

@export var path: Path2D;
@onready var path_bake: PathBakeAuto = $Path2D
@onready var drawer: Node2D = $GridDrawer

static var availableCells: Array[Vector2i];

func toggle_grid(is_visible: bool):
	if drawer:
		drawer.visible = is_visible
		if is_visible:
			drawer.queue_redraw()

# Internal helper to refresh when data changes
func refresh_visuals():
	if drawer and drawer.visible:
		drawer.queue_redraw()

# --- YOUR ORIGINAL FUNCTIONS (UNTOUCHED LOGIC) ---

static func isCellAvailable(cellPos: Vector2i) -> bool:
	if(cellPos.x < startX || cellPos.y < startY || cellPos.x > startX + mapSize.x || cellPos.y > startY + mapSize.y):
		return false;
	return availableCells.has(cellPos);

func removeAvailableCell(cell: Vector2i):
	var index = availableCells.find(cell);
	if(index > -1):
		availableCells.remove_at(index);
		refresh_visuals()

func addAvailableCell(cell: Vector2i):
	if(availableCells.has(cell)):
		return;

	availableCells.append(cell);
	refresh_visuals()

func setup():
	var path_data = path_bake.bake();
	availableCells = path_bake.get_available_tiles(path_data, [6]);
	print("grid size:", availableCells.size());
	# Default to visible on setup, or call toggle_grid(false) if you want it off by default
	toggle_grid(false)