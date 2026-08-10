extends Node
class_name PathBakeAuto

@export var tilemap: TileMap
@export var path_container: Node
@export var target_source_id: int = 4
@export var layer: int = 0

var baked_paths: Array[Path2D] = []
var baked_path_points: Array = []


# ============================================================
# BAKE
# ============================================================

func bake() -> Array[Path2D]:
	clear_baked_paths()

	var marked_points: Array[Vector2i] = get_marked_points(layer)

	if marked_points.is_empty():
		push_warning("No marked tiles found!")
		return []

	baked_path_points = find_paths_from_marked_points(marked_points)

	if baked_path_points.is_empty():
		push_warning("No valid path found.")
		return []

	for path_points in baked_path_points:
		create_path(path_points)

	debug_paths()

	return baked_paths


func create_path(points: Array[Vector2i]) -> Path2D:
	if points.size() < 2:
		return null

	var path := Path2D.new()
	var curve := Curve2D.new()

	for point in points:
		curve.add_point(tilemap.map_to_local(point))

	path.curve = curve

	if path_container != null:
		path_container.add_child(path)
	else:
		add_child(path)

	baked_paths.append(path)

	return path


func clear_baked_paths() -> void:
	for path in baked_paths:
		if is_instance_valid(path):
			path.queue_free()

	baked_paths.clear()
	baked_path_points.clear()


# ============================================================
# PATH ACCESS
# ============================================================

func get_path_by_index(index: int) -> Path2D:
	if baked_paths.is_empty():
		push_warning("No baked paths available.")
		return null

	if index < 0 or index >= baked_paths.size():
		push_warning("Path index out of range: %d" % index)
		return null

	return baked_paths[index]


func get_random_path() -> Path2D:
	if baked_paths.is_empty():
		push_warning("No baked paths available.")
		return null

	return baked_paths[randi_range(0, baked_paths.size() - 1)]


func get_baked_paths() -> Array[Path2D]:
	return baked_paths


func get_path_count() -> int:
	return baked_paths.size()


# ============================================================
# AVAILABLE TILES
# ============================================================

func get_available_tiles() -> Array[Vector2i]:
	var available_tiles: Array[Vector2i] = []
	var path_tiles: Dictionary = {}

	for path in baked_path_points:
		for point: Vector2i in path:
			path_tiles[point] = true

	var used_cells: Array[Vector2i] = tilemap.get_used_cells(1)

	for pos in used_cells:
		if path_tiles.has(pos):
			continue

		available_tiles.append(pos)

	return available_tiles


# ============================================================
# MARKED TILES
# ============================================================

func get_marked_points(p_layer: int) -> Array[Vector2i]:
	var marked: Array[Vector2i] = []

	var allowed_atlas_coords: Array[Vector2i] = [
		Vector2i(0, 0),
		Vector2i(0, 1),
		Vector2i(0, 2),
		Vector2i(1, 0),
		Vector2i(1, 1),
		Vector2i(1, 2),
		Vector2i(2, 0),
		Vector2i(2, 1),
		Vector2i(2, 2)
	]

	# Collect marked tiles from target layer.
	for pos in tilemap.get_used_cells(p_layer):
		var source_id: int = tilemap.get_cell_source_id(
			p_layer,
			pos
		)

		if source_id != target_source_id:
			continue

		var atlas_coord: Vector2i = tilemap.get_cell_atlas_coords(
			p_layer,
			pos
		)

		if allowed_atlas_coords.has(atlas_coord):
			marked.append(pos)

	# Remove tiles that exist on another layer.
	var final_marked: Array[Vector2i] = marked.duplicate()

	for check_layer in range(2):
		if check_layer == p_layer:
			continue

		var used_cells: Array[Vector2i] = tilemap.get_used_cells(
			check_layer
		)

		for pos in marked:
			if used_cells.has(pos):
				final_marked.erase(pos)

	return final_marked


# ============================================================
# PATH GENERATION
# ============================================================

func find_paths_from_marked_points(
	points: Array[Vector2i]
) -> Array:

	if points.is_empty():
		return []

	var point_set: Dictionary = {}

	for point in points:
		point_set[point] = true

	var visited_edges: Dictionary = {}
	var paths: Array = []

	# Start from endpoints and junctions.
	#
	# 1 neighbor = endpoint
	# 2 neighbors = normal path
	# 3+ neighbors = junction
	for point in points:
		var neighbors: Array[Vector2i] = get_point_neighbors(
			point,
			point_set
		)

		if neighbors.size() == 2:
			continue

		for neighbor in neighbors:
			var edge_key: String = get_edge_key(
				point,
				neighbor
			)

			if visited_edges.has(edge_key):
				continue

			var path: Array[Vector2i] = trace_path(
				point,
				neighbor,
				point_set,
				visited_edges
			)

			if path.size() >= 2:
				paths.append(path)

	# Handle closed loops.
	for point in points:
		var neighbors: Array[Vector2i] = get_point_neighbors(
			point,
			point_set
		)

		for neighbor in neighbors:
			var edge_key: String = get_edge_key(
				point,
				neighbor
			)

			if visited_edges.has(edge_key):
				continue

			var path: Array[Vector2i] = trace_path(
				point,
				neighbor,
				point_set,
				visited_edges
			)

			if path.size() >= 2:
				paths.append(path)

	return paths


func trace_path(
	start: Vector2i,
	next: Vector2i,
	point_set: Dictionary,
	visited_edges: Dictionary
) -> Array[Vector2i]:

	var path: Array[Vector2i] = [start]

	var previous: Vector2i = start
	var current: Vector2i = next

	visited_edges[get_edge_key(previous, current)] = true

	path.append(current)

	while true:
		var neighbors: Array[Vector2i] = get_point_neighbors(
			current,
			point_set
		)

		# Endpoint or junction.
		if neighbors.size() != 2:
			break

		var next_point: Vector2i = neighbors[0]

		if next_point == previous:
			next_point = neighbors[1]

		var edge_key: String = get_edge_key(
			current,
			next_point
		)

		if visited_edges.has(edge_key):
			break

		visited_edges[edge_key] = true

		previous = current
		current = next_point

		path.append(current)

	return path


func get_point_neighbors(
	point: Vector2i,
	point_set: Dictionary
) -> Array[Vector2i]:

	var neighbors: Array[Vector2i] = []

	for offset in get_adjacent_offsets():
		var neighbor: Vector2i = point + offset

		if point_set.has(neighbor):
			neighbors.append(neighbor)

	return neighbors


func get_edge_key(
	a: Vector2i,
	b: Vector2i
) -> String:

	if a.x < b.x or (a.x == b.x and a.y < b.y):
		return "%s_%s_%s_%s" % [
			a.x,
			a.y,
			b.x,
			b.y
		]

	return "%s_%s_%s_%s" % [
		b.x,
		b.y,
		a.x,
		a.y
	]


func get_adjacent_offsets() -> Array[Vector2i]:
	return [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1)
	]


# ============================================================
# DEBUG
# ============================================================

func debug_paths() -> void:
	print("========== PATH DEBUG ==========")
	print("Total Paths: ", baked_path_points.size())

	for i in range(baked_path_points.size()):
		var path: Array = baked_path_points[i]

		print("")
		print("Path %d (%d points)" % [
			i,
			path.size()
		])

		var path_text := ""

		for j in range(path.size()):
			var point: Vector2i = path[j]

			if j > 0:
				path_text += " -> "

			path_text += str(point)

		print("  ", path_text)

		if not path.is_empty():
			print("  Start: ", path[0])
			print("  End:   ", path[path.size() - 1])

	print("")
	print("================================")
