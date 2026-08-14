extends Node2D
class_name AvailableGridDrawer

const CELL_INSET_FRAC := 0.08
const NORMAL_STROKE_CELL_FRAC := 0.012
const HOVER_STROKE_CELL_FRAC := 0.02
const NORMAL_STROKE := Color(1.0, 0.94, 0.80, 0.45)
const HOVER_STROKE := Color(1.0, 0.78, 0.30, 0.95)
const HOVER_FILL := Color(1.0, 0.78, 0.30, 0.08)

var _hovered_cell: Variant = null

func _ready() -> void:
	visible = false
	set_process(false)

func set_active(p_is_active: bool) -> void:
	if not p_is_active:
		set_process(false)
		_hovered_cell = null
		visible = false
		return

	visible = true
	set_process(true)
	_update_hovered_cell()
	queue_redraw()

func _process(_delta: float) -> void:
	_update_hovered_cell()

func _update_hovered_cell() -> void:
	var map := get_parent() as Map
	if map == null:
		return

	var hovered_cell := map.local_to_map(map.to_local(get_global_mouse_position()))
	if hovered_cell == _hovered_cell:
		return

	_hovered_cell = hovered_cell
	queue_redraw()

func _draw() -> void:
	var map := get_parent() as Map
	if map == null or map.tile_set == null:
		return

	var tile_size := Vector2(map.tile_set.tile_size)
	var cell_scale := minf(tile_size.x, tile_size.y)
	var inset := cell_scale * CELL_INSET_FRAC
	var rect_size := tile_size - Vector2.ONE * inset * 2.0

	for cell in Map.availableCells:
		var center_pos := map.map_to_local(cell)
		var rect := Rect2(center_pos - tile_size / 2.0 + Vector2.ONE * inset, rect_size)
		var is_hovered: bool = cell == _hovered_cell

		if is_hovered:
			draw_rect(rect, HOVER_FILL, true)
			draw_rect(rect, HOVER_STROKE, false,
					cell_scale * HOVER_STROKE_CELL_FRAC, true)
		else:
			draw_rect(rect, NORMAL_STROKE, false,
					cell_scale * NORMAL_STROKE_CELL_FRAC, true)
