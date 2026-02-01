extends Node2D

func _draw():
	var parent = get_parent()
	if not parent is Map or not parent.tile_set:
		return

	var tile_size = parent.tile_set.tile_size

	for x in range(Map.startX, Map.startX + int(Map.mapSize.x)):
		for y in range(Map.startY, Map.startY + int(Map.mapSize.y)):
			var cell = Vector2i(x, y)

			var is_avail = Map.availableCells.has(cell)
			var color = Color(0, 1, 0, 0.4) if is_avail else Color(1, 0, 0, 0.4)

			var center_pos = parent.map_to_local(cell)
			var draw_pos = center_pos - (Vector2(tile_size) / 2)

			draw_rect(Rect2(draw_pos, tile_size), color, true)
			draw_rect(Rect2(draw_pos, tile_size), Color(color, 1.0), false, 1.0)