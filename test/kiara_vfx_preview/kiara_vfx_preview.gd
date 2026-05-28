extends Node2D

# Reusable VFX preview stage.
# Change PREVIEW_SPEC to test another tower footprint without rebuilding the scene.

@export var loop_duration: float = 0.8

const PANEL_SIZE := Vector2(1820.0, 300.0)
const PANEL_LEFT := 50.0
const PANEL_TOP := 64.0
const PANEL_GAP := 22.0
const TILE_SIZE := 76.0
const ACTIVE_VARIANT_KEYS := ["C"]

const KIARA_ATTACK := "res://resources/tower/hololive/en_branch/myth_gen/kiara/sprite/kiara_attack001.png"
const ENEMY := "res://resources/enemy/enemy_test.png"

const PREVIEW_SPEC := {
	"title": "Kiara Normal Skill VFX Preview",
	"subtitle": "Footprint: vertical 1x3 slash on Kiara's left side.",
	"tower_sprite": KIARA_ATTACK,
	"tower_cell": Vector2i(0, 0),
	"hit_cells": [Vector2i(-1, -1), Vector2i(-1, 0), Vector2i(-1, 1)],
	"effect_center_cell": Vector2i(0, 0),
	"effect_size_tiles": Vector2(4.35, 4.35),
	"arc_center_angle_degrees": 180.0,
	"effect_rotation_degrees": 0.0
}

const VARIANTS := [
	{
		"key": "A",
		"title": "A  C-Compact Rim Fan",
		"note": "Smaller C silhouette with a clear red cel border and a rounded phoenix-flame start.",
		"shader": "res://test/kiara_vfx_preview/centered_sword_arc.gdshader",
		"style_mode": 2,
		"shape_mode": 2,
		"color": Color(1.0, 0.62, 0.12, 1.0),
		"arc_radius": 1.16,
		"arc_thickness": 0.18,
		"arc_span": 1.38,
		"trail_angle": 1.72,
		"shape_curve": 0.05,
		"shape_taper": 0.48,
		"double_arc_offset": 0.22,
		"flame_width": 0.35,
		"roughness": 0.30,
		"ember_amount": 0.62,
		"feather_amount": 0.76,
		"sparkle_amount": 0.62,
		"ash_amount": 0.38,
		"sacred_gold": 0.78,
		"anime_band": 0.94,
		"lick_amount": 0.40,
		"brush_fill": 0.86,
		"red_rim": 0.98,
		"mint_accent": 0.24,
		"shard_amount": 0.50,
		"border_strength": 0.92,
		"burst_amount": 0.34,
		"round_start": 0.78,
		"brightness": 2.90
	},
	{
		"key": "B",
		"title": "B  C-Burst Flame Fan",
		"note": "Compact C with flame tongues breaking past the rim and outward burst waves.",
		"shader": "res://test/kiara_vfx_preview/centered_sword_arc.gdshader",
		"style_mode": 2,
		"shape_mode": 1,
		"color": Color(1.0, 0.20, 0.04, 1.0),
		"arc_radius": 1.10,
		"arc_thickness": 0.23,
		"arc_span": 1.46,
		"trail_angle": 1.82,
		"shape_curve": 0.18,
		"shape_taper": 0.36,
		"double_arc_offset": 0.20,
		"flame_width": 0.40,
		"roughness": 0.48,
		"ember_amount": 0.70,
		"feather_amount": 0.82,
		"sparkle_amount": 0.58,
		"ash_amount": 0.42,
		"sacred_gold": 0.72,
		"anime_band": 0.90,
		"lick_amount": 0.74,
		"brush_fill": 0.90,
		"red_rim": 1.00,
		"mint_accent": 0.18,
		"shard_amount": 0.64,
		"border_strength": 1.00,
		"burst_amount": 0.78,
		"round_start": 0.72,
		"brightness": 2.85
	},
	{
		"key": "C",
		"title": "C  Arc-Fade Tri-Tail Starburst",
		"note": "Selected C: strong swing lead with position-based trail fade along the arc.",
		"shader": "res://test/kiara_vfx_preview/centered_sword_arc.gdshader",
		"style_mode": 2,
		"shape_mode": 2,
		"color": Color(1.0, 0.70, 0.16, 1.0),
		"arc_radius": 1.22,
		"arc_thickness": 0.20,
		"arc_span": 1.50,
		"trail_angle": 1.68,
		"shape_curve": -0.02,
		"shape_taper": 0.58,
		"double_arc_offset": 0.30,
		"flame_width": 0.37,
		"roughness": 0.36,
		"ember_amount": 0.64,
		"feather_amount": 0.95,
		"sparkle_amount": 0.86,
		"ash_amount": 0.56,
		"sacred_gold": 0.82,
		"anime_band": 0.94,
		"lick_amount": 0.52,
		"brush_fill": 0.84,
		"red_rim": 0.94,
		"mint_accent": 0.30,
		"shard_amount": 0.76,
		"border_strength": 0.88,
		"burst_amount": 0.55,
		"round_start": 0.84,
		"tail_shape_mode": 0,
		"tail_taper": 1.00,
		"tail_fade": 1.00,
		"brightness": 3.00
	},
	{
		"key": "D",
		"title": "D  Kite-Tail Wing Starburst",
		"note": "C comparison: kite-shaped trail, narrow tail, wider belly, and tighter leading nose.",
		"shader": "res://test/kiara_vfx_preview/centered_sword_arc.gdshader",
		"style_mode": 2,
		"shape_mode": 2,
		"color": Color(1.0, 0.66, 0.13, 1.0),
		"arc_radius": 1.22,
		"arc_thickness": 0.22,
		"arc_span": 1.50,
		"trail_angle": 1.68,
		"shape_curve": -0.02,
		"shape_taper": 0.50,
		"double_arc_offset": 0.28,
		"flame_width": 0.40,
		"roughness": 0.34,
		"ember_amount": 0.62,
		"feather_amount": 0.88,
		"sparkle_amount": 0.78,
		"ash_amount": 0.50,
		"sacred_gold": 0.82,
		"anime_band": 0.94,
		"lick_amount": 0.46,
		"brush_fill": 0.88,
		"red_rim": 0.96,
		"mint_accent": 0.28,
		"shard_amount": 0.68,
		"border_strength": 0.92,
		"burst_amount": 0.48,
		"round_start": 0.78,
		"tail_shape_mode": 1,
		"tail_taper": 1.00,
		"tail_fade": 0.36,
		"brightness": 2.95
	}
]

var _elapsed: float = 0.0
var _materials: Array[ShaderMaterial] = []

func _ready() -> void:
	_build_header()
	var panel_index := 0
	for i in range(VARIANTS.size()):
		var data: Dictionary = VARIANTS[i]
		if not ACTIVE_VARIANT_KEYS.is_empty() and not ACTIVE_VARIANT_KEYS.has(data["key"]):
			continue
		_build_panel(panel_index, data)
		panel_index += 1

func _process(delta: float) -> void:
	_elapsed += delta
	var t := fmod(_elapsed, loop_duration) / loop_duration
	for mat in _materials:
		if mat == null:
			continue
		mat.set_shader_parameter("progress", t)
		mat.set_shader_parameter("scale_p", 1.0)

func _build_header() -> void:
	var bg := ColorRect.new()
	bg.name = "BG"
	bg.position = Vector2.ZERO
	bg.size = Vector2(1920.0, 1080.0)
	bg.color = Color(0.032, 0.040, 0.034, 1.0)
	add_child(bg)

	var title := Label.new()
	title.name = "Title"
	title.position = Vector2(PANEL_LEFT, 12.0)
	title.size = Vector2(PANEL_SIZE.x, 30.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = PREVIEW_SPEC["title"]
	title.add_theme_font_size_override("font_size", 24)
	add_child(title)

	var subtitle := Label.new()
	subtitle.name = "Subtitle"
	subtitle.position = Vector2(PANEL_LEFT, 40.0)
	subtitle.size = Vector2(PANEL_SIZE.x, 20.0)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.text = PREVIEW_SPEC["subtitle"]
	subtitle.add_theme_font_size_override("font_size", 15)
	add_child(subtitle)

func _build_panel(index: int, data: Dictionary) -> void:
	var origin := Vector2(PANEL_LEFT, PANEL_TOP + index * (PANEL_SIZE.y + PANEL_GAP))
	var stage_anchor := origin + Vector2(500.0, 176.0)

	_draw_panel_backing(origin, data)
	_draw_stage_grid(stage_anchor, data["key"])
	_draw_hit_tiles(stage_anchor, data["key"])
	_draw_tower_tile(stage_anchor, data["key"])
	_draw_enemies(stage_anchor, data["key"])
	_draw_impact_guides(stage_anchor, data)
	_draw_vfx(stage_anchor, data)
	_draw_tower(stage_anchor, data["key"])

func _draw_panel_backing(origin: Vector2, data: Dictionary) -> void:
	var panel := ColorRect.new()
	panel.name = "Panel_%s" % data["key"]
	panel.position = origin
	panel.size = PANEL_SIZE
	panel.color = Color(0.085, 0.115, 0.087, 1.0)
	add_child(panel)

	var stage := ColorRect.new()
	stage.name = "Stage_%s" % data["key"]
	stage.position = origin + Vector2(18.0, 50.0)
	stage.size = Vector2(PANEL_SIZE.x - 36.0, PANEL_SIZE.y - 58.0)
	stage.color = Color(0.122, 0.170, 0.114, 1.0)
	add_child(stage)

	var title := Label.new()
	title.name = "VariantLabel_%s" % data["key"]
	title.position = origin + Vector2(22.0, 13.0)
	title.size = Vector2(520.0, 24.0)
	title.text = data["title"]
	title.add_theme_font_size_override("font_size", 21)
	add_child(title)

	var note := Label.new()
	note.name = "VariantNote_%s" % data["key"]
	note.position = origin + Vector2(600.0, 16.0)
	note.size = Vector2(1120.0, 22.0)
	note.text = data["note"]
	note.add_theme_font_size_override("font_size", 15)
	add_child(note)

func _draw_stage_grid(anchor: Vector2, key: String) -> void:
	var bounds := _bounds_for_cells(_all_cells())
	for y in range(bounds["min_y"] - 1, bounds["max_y"] + 2):
		for x in range(bounds["min_x"] - 1, bounds["max_x"] + 2):
			var cell := Vector2i(x, y)
			_draw_tile(_cell_center(anchor, cell), Color(0.16, 0.22, 0.145, 0.58), "Grid_%s_%d_%d" % [key, x, y], Color(0.62, 0.78, 0.48, 0.16))

func _draw_hit_tiles(anchor: Vector2, key: String) -> void:
	for i in range(PREVIEW_SPEC["hit_cells"].size()):
		var cell: Vector2i = PREVIEW_SPEC["hit_cells"][i]
		_draw_tile(_cell_center(anchor, cell), Color(0.95, 0.28, 0.06, 0.25), "HitTile_%s_%d" % [key, i], Color(1.0, 0.74, 0.25, 0.58))

func _draw_tower_tile(anchor: Vector2, key: String) -> void:
	_draw_tile(_cell_center(anchor, PREVIEW_SPEC["tower_cell"]), Color(0.18, 0.33, 0.18, 0.82), "TowerTile_%s" % key, Color(0.80, 1.0, 0.50, 0.44))

func _draw_enemies(anchor: Vector2, key: String) -> void:
	for i in range(PREVIEW_SPEC["hit_cells"].size()):
		var cell: Vector2i = PREVIEW_SPEC["hit_cells"][i]
		var sprite := Sprite2D.new()
		sprite.name = "Enemy_%s_%d" % [key, i]
		sprite.texture = load(ENEMY)
		sprite.position = _cell_center(anchor, cell) + Vector2(0.0, 5.0)
		sprite.scale = Vector2(0.26, 0.26)
		add_child(sprite)

func _draw_impact_guides(anchor: Vector2, data: Dictionary) -> void:
	var tower_center := _cell_center(anchor, PREVIEW_SPEC["tower_cell"])
	var hit_bounds := _bounds_for_cells(PREVIEW_SPEC["hit_cells"])
	var hit_center := _bounds_center(anchor, hit_bounds)
	var hit_min := _cell_center(anchor, Vector2i(hit_bounds["min_x"], hit_bounds["min_y"]))
	var hit_max := _cell_center(anchor, Vector2i(hit_bounds["max_x"], hit_bounds["max_y"]))

	_draw_line("Guide_%s_cast" % data["key"], [tower_center, hit_center], Color(data["color"].r, data["color"].g, data["color"].b, 0.32), 7.0)
	_draw_line("Guide_%s_spine" % data["key"], [hit_min, hit_max], Color(data["color"].r, data["color"].g, data["color"].b, 0.24), 10.0)

func _draw_vfx(anchor: Vector2, data: Dictionary) -> void:
	var effect_center := _cell_center(anchor, PREVIEW_SPEC["effect_center_cell"])
	var rotation_degrees: float = PREVIEW_SPEC["effect_rotation_degrees"]
	var effect_size_tiles: Vector2 = PREVIEW_SPEC["effect_size_tiles"]
	var shader_size := effect_size_tiles * TILE_SIZE

	var mat := ShaderMaterial.new()
	mat.shader = load(data["shader"])
	mat.set_shader_parameter("style_mode", data["style_mode"])
	mat.set_shader_parameter("shape_mode", data["shape_mode"])
	mat.set_shader_parameter("space_tiles", effect_size_tiles)
	mat.set_shader_parameter("arc_center_angle", deg_to_rad(PREVIEW_SPEC["arc_center_angle_degrees"]))
	mat.set_shader_parameter("arc_radius", data["arc_radius"])
	mat.set_shader_parameter("arc_thickness", data["arc_thickness"])
	mat.set_shader_parameter("arc_span", data["arc_span"])
	mat.set_shader_parameter("trail_angle", data["trail_angle"])
	mat.set_shader_parameter("shape_curve", data["shape_curve"])
	mat.set_shader_parameter("shape_taper", data["shape_taper"])
	mat.set_shader_parameter("double_arc_offset", data["double_arc_offset"])
	mat.set_shader_parameter("flame_width", data["flame_width"])
	mat.set_shader_parameter("roughness", data["roughness"])
	mat.set_shader_parameter("ember_amount", data["ember_amount"])
	mat.set_shader_parameter("feather_amount", data["feather_amount"])
	mat.set_shader_parameter("sparkle_amount", data["sparkle_amount"])
	mat.set_shader_parameter("ash_amount", data["ash_amount"])
	mat.set_shader_parameter("sacred_gold", data["sacred_gold"])
	mat.set_shader_parameter("anime_band", data["anime_band"])
	mat.set_shader_parameter("lick_amount", data["lick_amount"])
	mat.set_shader_parameter("brush_fill", data["brush_fill"])
	mat.set_shader_parameter("red_rim", data["red_rim"])
	mat.set_shader_parameter("mint_accent", data["mint_accent"])
	mat.set_shader_parameter("shard_amount", data["shard_amount"])
	mat.set_shader_parameter("border_strength", data["border_strength"])
	mat.set_shader_parameter("burst_amount", data["burst_amount"])
	mat.set_shader_parameter("round_start", data["round_start"])
	mat.set_shader_parameter("tail_shape_mode", data.get("tail_shape_mode", 0))
	mat.set_shader_parameter("tail_taper", data.get("tail_taper", 0.0))
	mat.set_shader_parameter("tail_fade", data.get("tail_fade", 0.0))
	mat.set_shader_parameter("brightness", data["brightness"])
	_materials.append(mat)

	var vfx := ColorRect.new()
	vfx.name = "Vfx_%s" % data["key"]
	vfx.material = mat
	vfx.position = effect_center - shader_size * 0.5
	vfx.size = shader_size
	vfx.pivot_offset = shader_size * 0.5
	vfx.rotation = deg_to_rad(rotation_degrees)
	vfx.color = Color(0.0, 0.0, 0.0, 1.0)
	add_child(vfx)

func _draw_tower(anchor: Vector2, key: String) -> void:
	var center := _cell_center(anchor, PREVIEW_SPEC["tower_cell"])

	var glow := ColorRect.new()
	glow.name = "TowerGlow_%s" % key
	glow.position = center + Vector2(-TILE_SIZE * 0.45, -TILE_SIZE * 0.45)
	glow.size = Vector2(TILE_SIZE * 0.9, TILE_SIZE * 0.9)
	glow.color = Color(1.0, 0.54, 0.08, 0.16)
	add_child(glow)

	var sprite := Sprite2D.new()
	sprite.name = "Tower_%s" % key
	sprite.texture = _atlas(PREVIEW_SPEC["tower_sprite"])
	sprite.position = center + Vector2(-8.0, -32.0)
	sprite.scale = Vector2(0.21, 0.21)
	add_child(sprite)

func _draw_tile(center: Vector2, color: Color, node_name: String, outline_color: Color) -> void:
	var tile := ColorRect.new()
	tile.name = node_name
	tile.position = center - Vector2(TILE_SIZE, TILE_SIZE) * 0.5
	tile.size = Vector2(TILE_SIZE, TILE_SIZE)
	tile.color = color
	add_child(tile)

	var top := ColorRect.new()
	top.name = "%s_Top" % node_name
	top.position = tile.position
	top.size = Vector2(TILE_SIZE, 2.0)
	top.color = outline_color
	add_child(top)

	var bottom := ColorRect.new()
	bottom.name = "%s_Bottom" % node_name
	bottom.position = tile.position + Vector2(0.0, TILE_SIZE - 2.0)
	bottom.size = Vector2(TILE_SIZE, 2.0)
	bottom.color = outline_color
	add_child(bottom)

	var left := ColorRect.new()
	left.name = "%s_Left" % node_name
	left.position = tile.position
	left.size = Vector2(2.0, TILE_SIZE)
	left.color = outline_color
	add_child(left)

	var right := ColorRect.new()
	right.name = "%s_Right" % node_name
	right.position = tile.position + Vector2(TILE_SIZE - 2.0, 0.0)
	right.size = Vector2(2.0, TILE_SIZE)
	right.color = outline_color
	add_child(right)

func _draw_line(node_name: String, points: Array, color: Color, width: float) -> void:
	var line := Line2D.new()
	line.name = node_name
	line.points = PackedVector2Array(points)
	line.width = width
	line.default_color = color
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(line)

func _all_cells() -> Array:
	var cells := [PREVIEW_SPEC["tower_cell"]]
	for cell in PREVIEW_SPEC["hit_cells"]:
		cells.append(cell)
	return cells

func _bounds_for_cells(cells: Array) -> Dictionary:
	var min_x := 999
	var min_y := 999
	var max_x := -999
	var max_y := -999
	for cell in cells:
		min_x = mini(min_x, cell.x)
		min_y = mini(min_y, cell.y)
		max_x = maxi(max_x, cell.x)
		max_y = maxi(max_y, cell.y)
	return {
		"min_x": min_x,
		"min_y": min_y,
		"max_x": max_x,
		"max_y": max_y
	}

func _bounds_center(anchor: Vector2, bounds: Dictionary) -> Vector2:
	var min_center := _cell_center(anchor, Vector2i(bounds["min_x"], bounds["min_y"]))
	var max_center := _cell_center(anchor, Vector2i(bounds["max_x"], bounds["max_y"]))
	return (min_center + max_center) * 0.5

func _cell_center(anchor: Vector2, cell: Vector2i) -> Vector2:
	return anchor + Vector2(float(cell.x), float(cell.y)) * TILE_SIZE

func _atlas(path: String) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = load(path)
	texture.region = Rect2(0.0, 0.0, 512.0, 512.0)
	return texture
