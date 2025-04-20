extends Node
class_name PathBakeAuto

@export var tilemap: TileMap
@export var path2d: Path2D
@export var target_source_id: int = 4
@export var layer: int = 0  # TileMap layer index

func bake():
	var marked_points: Array[Vector2i] = get_marked_points(layer)
	if marked_points.is_empty():
		print("No marked tiles found!")
		return

	var path: Array[Vector2] = find_path_from_marked_points(marked_points)
	if path.is_empty():
		print("No valid path found.")
		return

	# Clear existing path
	path2d.curve.clear_points()

	# Add points to the Path2D curve
	for point in path:
		path2d.curve.add_point(point)
	
	draw_path_line(path);
	print("Path set with %d points." % path.size())
	return path

func get_marked_points(layer: int) -> Array[Vector2i]:
	var marked: Array[Vector2i] = []
	var allowed_atlas_coords: Array[Vector2i] = [
		Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2),
		Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2),
		Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2)
	]

	# Step 1: Collect from the base layer (layer 0)
	for pos in tilemap.get_used_cells(layer):
		var source_id: int = tilemap.get_cell_source_id(layer, pos)
		if source_id != target_source_id:
			continue

		var atlas_coord: Vector2i = tilemap.get_cell_atlas_coords(layer, pos)
		if allowed_atlas_coords.has(atlas_coord):
			marked.append(pos)

	# Step 2: Check other layers and remove positions if they exist there
	var final_marked := marked.duplicate()
	for check_layer in range(2):
		if check_layer == layer:
			continue
		for pos in marked:
			if tilemap.get_used_cells(check_layer).has(pos):
				final_marked.erase(pos)

	return final_marked

func find_path_from_marked_points(points: Array[Vector2i]) -> Array[Vector2]:
	if points.is_empty():
		return []

	var visited: Dictionary = {}
	var path: Array[Vector2] = []
	var start: Vector2i = points[0]
	var stack: Array[Vector2i] = [start]

	while not stack.is_empty():
		var current: Vector2i = stack.pop_back()
		if visited.has(current):
			continue

		visited[current] = true
		path.append(Vector2(tilemap.map_to_local(current)))  # Explicit cast

		for offset in get_adjacent_offsets():
			var neighbor: Vector2i = current + offset
			if points.has(neighbor) and not visited.has(neighbor):
				stack.append(neighbor)
		
	if(path.size() >= 2):
		var last_dir = get_direction(path[path.size() - 2], path[path.size() - 1])/2
		var last_cell = path[path.size()-1];
		path.append(Vector2(last_cell.x + last_dir.x, last_cell.y + last_dir.y));
	return path

func get_direction(from: Vector2i, to: Vector2i):
	var cell_size = GridHelper.CELL_SIZE;
	return (to - from)

func get_adjacent_offsets() -> Array[Vector2i]:
	return [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1)
	]

func draw_path_line(points: Array[Vector2]) -> void:
	# Remove old Line2D if any
	for child in path2d.get_children():
		if child is Line2D:
			child.queue_free()

	if points.size() < 2:
		return  # Need at least two points to draw a line

	var line := Line2D.new()
	line.width = 15
	line.default_color = Color.DARK_RED
	line.position = Vector2.ZERO

	for point in points:
		line.add_point(point)

	path2d.add_child(line)

func get_available_tiles(path_tiles: Array[Vector2], excluded_layers: Array[int] = []) -> Array[Vector2i]:
	var available_tiles: Array[Vector2i] = []

	var target_layer := 1
	var target_source := 3
	var used_cells := tilemap.get_used_cells(target_layer)

	for pos in used_cells:
		if path_tiles.has(pos):
			continue

		#var source_id := tilemap.get_cell_source_id(target_layer, pos)
		#if source_id != target_source:
			#continue
#
		#var is_used_elsewhere := false
		#for check_layer in range(tilemap.get_layers_count()):
			#if check_layer == target_layer or excluded_layers.has(check_layer):
				#continue
			#if tilemap.get_used_cells(check_layer).has(pos):
				#is_used_elsewhere = true
				#break

		available_tiles.append(pos)
		#if not is_used_elsewhere:

	return available_tiles
