extends Camera2D

@export var margin: float = 0.9
@export var tilemap: TileMap

func _ready():
	var cell_size = GridHelper.GetCellSize();
	# Get cell size from TileMap (if you want to use TileMap's cell size instead of the export var)
	var tile_cell_size = cell_size  # Assuming square cells
	
	# Get the used rect of the TileMap (area that contains tiles)
	var used_rect = tilemap.get_used_rect()
	
	# Calculate total map dimensions in pixels
	var map_width_pixels = used_rect.size.x * tile_cell_size
	var map_height_pixels = used_rect.size.y * tile_cell_size
	
	# Get the viewport size
	var viewport_size = get_viewport_rect().size
	
	# Calculate zoom factors for both dimensions
	var zoom_x = viewport_size.x / map_width_pixels / margin
	var zoom_y = viewport_size.y / map_height_pixels / margin
	
	# Use the larger value to ensure the entire map fits
	var zoom_factor = max(zoom_x, zoom_y)
	
	# Set the zoom
	print("zoom:", zoom_factor);
	zoom = Vector2(zoom_factor, zoom_factor)
	
	var center = get_tilemap_center(tilemap);
	
	position = Vector2(center.x * cell_size, center.y * cell_size)

func get_tilemap_center(tilemap: TileMap) -> Vector2:
	var used_rect = tilemap.get_used_rect()
	var center_cell = used_rect.position + (used_rect.size / 2)
	return center_cell
