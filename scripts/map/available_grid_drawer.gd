extends Node2D
class_name AvailableGridDrawer

const CELL_INSET_FRAC := 0.03
const CORNER_RADIUS_CELL_FRAC := 0.08
const NORMAL_STROKE_CELL_FRAC := 0.03
const HOVER_STROKE_CELL_FRAC := 0.04
const NORMAL_STROKE := Color(1.0, 0.94, 0.80, 0.45)
const HOVER_STROKE := Color(1.0, 0.78, 0.30, 0.95)
const HOVER_FILL := Color(1.0, 0.78, 0.30, 0.08)

var _hovered_cell: Variant = null
var _normal_style: StyleBoxFlat = null
var _hover_style: StyleBoxFlat = null
var _style_cell_scale: float = -1.0

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
	_ensure_styles(cell_scale)

	for x in range(Map.startX, Map.startX + int(Map.mapSize.x)):
		for y in range(Map.startY, Map.startY + int(Map.mapSize.y)):
			var cell := Vector2i(x, y)
			if not Map.isCellAvailable(cell):
				continue

			var center_pos := map.map_to_local(cell)
			var rect := Rect2(center_pos - tile_size / 2.0 + Vector2.ONE * inset, rect_size)
			var is_hovered: bool = cell == _hovered_cell
			draw_style_box(_hover_style if is_hovered else _normal_style, rect)

func _ensure_styles(p_cell_scale: float) -> void:
	if is_equal_approx(_style_cell_scale, p_cell_scale):
		return

	_style_cell_scale = p_cell_scale
	var corner_radius := roundi(p_cell_scale * CORNER_RADIUS_CELL_FRAC)

	_normal_style = StyleBoxFlat.new()
	_normal_style.bg_color = Color.TRANSPARENT
	_normal_style.border_color = NORMAL_STROKE
	_normal_style.set_border_width_all(roundi(p_cell_scale * NORMAL_STROKE_CELL_FRAC))
	_normal_style.set_corner_radius_all(corner_radius)

	_hover_style = StyleBoxFlat.new()
	_hover_style.bg_color = HOVER_FILL
	_hover_style.border_color = HOVER_STROKE
	_hover_style.set_border_width_all(roundi(p_cell_scale * HOVER_STROKE_CELL_FRAC))
	_hover_style.set_corner_radius_all(corner_radius)
