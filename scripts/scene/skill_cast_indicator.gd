class_name SkillCastIndicator
extends Node2D

# Visual indicator that follows the mouse during a staff skill cast, showing the AOE
# footprint (default 4×4 cells) snapped to grid. Phase 2 placeholder visual — minimal
# semi-transparent fill + outline. Polish (particles / aura / animation) deferred to
# the VFX pass per Game Director Phase 2 spec.
#
# IMPORTANT: thicknesses are in WORLD pixels. GridHelper.CELL_SIZE=512 and the gameplay
# camera zooms out heavily (~0.15) so 1 screen px ≈ 6-7 world px. Defaults boosted so
# strokes remain visible on screen. We also draw a dark drop-shadow under every stroke
# for contrast against any backdrop (grass / path / props / enemies).

@export var aoe_width: int = 4
@export var aoe_height: int = 4
@export var fill_color: Color = Color(0.4, 0.85, 1.0, 0.22)

# Outline = 2-layer stroke. Dark wider stroke under bright narrower stroke.
# Cyan tone matches the publisher's CI (kept blue family on purpose); the dark
# shadow underneath is what carries contrast vs the fill + backdrop, so the
# outline itself can stay on-brand.
@export var outline_color: Color = Color(0.55, 0.95, 1.0, 1.0)
@export var outline_shadow_color: Color = Color(0.0, 0.0, 0.0, 0.85)
@export var outline_thickness: float = 32.0
@export var outline_shadow_thickness: float = 56.0

# Per-cell grid lines — same 2-layer stroke pattern. Bright white on dark halo so
# player can count cells at a glance regardless of tile background.
@export var grid_line_color: Color = Color(1.0, 1.0, 1.0, 0.95)
@export var grid_line_shadow_color: Color = Color(0.0, 0.0, 0.0, 0.7)
@export var grid_line_thickness: float = 20.0
@export var grid_line_shadow_thickness: float = 36.0

func _ready() -> void:
	visible = false  # GameScene shows on cast-request, hides on commit / cancel

func set_aoe_size(width: int, height: int) -> void:
	aoe_width = width
	aoe_height = height
	queue_redraw()

# Snap the indicator to the grid cell under the given world position.
# Caller passes raw mouse world position; indicator centers on the snapped cell.
func update_position_from_world(world_position: Vector2) -> void:
	var cell: Vector2i = GridHelper.WorldToCell(world_position)
	global_position = GridHelper.CellToWorld(cell)
	queue_redraw()

func _draw() -> void:
	var cellSize: float = float(GridHelper.CELL_SIZE)
	var w: float = aoe_width * cellSize
	var h: float = aoe_height * cellSize
	var rect := Rect2(Vector2(-w * 0.5, -h * 0.5), Vector2(w, h))

	# 1. Fill (semi-transparent backdrop tint)
	draw_rect(rect, fill_color, true)

	# 2. Per-cell grid lines — draw BEFORE outline so the outer outline sits on top
	# at the rectangle edges. Each line = dark shadow (wider) + bright line (narrower).
	for i in range(1, aoe_width):
		var x: float = rect.position.x + i * cellSize
		var p1 := Vector2(x, rect.position.y)
		var p2 := Vector2(x, rect.position.y + h)
		draw_line(p1, p2, grid_line_shadow_color, grid_line_shadow_thickness)
		draw_line(p1, p2, grid_line_color, grid_line_thickness)
	for j in range(1, aoe_height):
		var y: float = rect.position.y + j * cellSize
		var p1 := Vector2(rect.position.x, y)
		var p2 := Vector2(rect.position.x + w, y)
		draw_line(p1, p2, grid_line_shadow_color, grid_line_shadow_thickness)
		draw_line(p1, p2, grid_line_color, grid_line_thickness)

	# 3. Outline — dark shadow (wider) first, then warm-yellow bright stroke on top.
	# Yellow tone contrasts vs the blue fill + green/brown map → unambiguous AOE edge.
	draw_rect(rect, outline_shadow_color, false, outline_shadow_thickness)
	draw_rect(rect, outline_color, false, outline_thickness)
