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

	path2d.curve.clear_points()
	for point in path:
		path2d.curve.add_point(point)

	print("Path set with %d points." % path.size())


func get_marked_points(layer: int) -> Array[Vector2i]:
	var marked: Array[Vector2i] = []
	var allowed_atlas_coords: Array[Vector2i] = [
		Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2),
		Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2),
		Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2)
	]

	for pos in tilemap.get_used_cells(layer):
		var source_id: int = tilemap.get_cell_source_id(layer, pos)
		if source_id != target_source_id:
			continue

		var atlas_coord: Vector2i = tilemap.get_cell_atlas_coords(layer, pos)
		if allowed_atlas_coords.has(atlas_coord):
			marked.append(pos)

	return marked


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

	return path


func get_adjacent_offsets() -> Array[Vector2i]:
	return [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1)
	]
