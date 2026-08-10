extends TileMap
class_name Map

static var mapSize: Vector2 = Vector2(10, 10);
static var startX: int = 9;
static var startY: int = 3;

@export var path: Array[Path2D];
@onready var path_bake: PathBakeAuto = $Path2D
@onready var drawer: Node2D = $GridDrawer

static var availableCells: Array[Vector2i];

func toggle_grid(p_is_visible: bool):
	if drawer:
		drawer.visible = p_is_visible
		if p_is_visible:
			drawer.queue_redraw()

# Internal helper to refresh when data changes
func refresh_visuals():
	if drawer and drawer.visible:
		drawer.queue_redraw()

# --- YOUR ORIGINAL FUNCTIONS (UNTOUCHED LOGIC) ---

static func isCellAvailable(cellPos: Vector2i) -> bool:
	if(cellPos.x < startX || cellPos.y < startY || cellPos.x > startX + mapSize.x - 1 || cellPos.y > startY + mapSize.y - 1):
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
	path_bake.bake()
	availableCells = path_bake.get_available_tiles()
	path = path_bake.baked_paths

	print("path: ", path.size())
	toggle_grid(false)
