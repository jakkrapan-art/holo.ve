extends Node2D
# ════════════════════════════════════════════════════════════════
# Kiara · Hinotori (evo) VFX preview harness  (run this scene with F6)
#
# Stacked rows compare phoenix SIZE (smaller body_scale reads as flying
# farther down the lane). Shape 1 (Spread-wings), magma-violet, living
# flame, normal-copied slash → fades → fast rush (no retract) + velocity
# streak → impact burst → burn-away dissolve vanish.
# Kiara at LEFT (caster); phoenix flies L→R. Visual frame is WIDER than
# the 3×5 damage corridor (pad) so nothing clips — AoE is code-side.
# Auto-loops; click to replay.
# ════════════════════════════════════════════════════════════════

const VIEW := Vector2(1920.0, 1080.0)
const TOWER_SPRITE := "res://resources/tower/hololive/en_branch/myth_gen/kiara/sprite/kiara_attack001.png"
const ENEMY_SPRITE := "res://resources/enemy/enemy_test.png"
const SHADER := "res://test/kiara_vfx_preview/evo3_magma.gdshader"

const AREA_TILES := Vector2i(5, 3)   # DAMAGE corridor (length × width)
const PAD_L := 1.0                   # visual pad (tiles) — slash/launch room
const PAD_R := 2.2                   # visual pad — impact burst + rush room
const PAD_TB := 1.0                  # visual pad — wing/ember spill room

const DURATION := 1.35
const POP_FRAC := 0.14
const HOLD := 0.55

const HEADER := "Kiara · Hinotori (evo) — variant 2 base + 2 evolutions (Plumage / Wingsweep)   (click to replay)"

const ENEMY_TILES := [Vector2i(0,1), Vector2i(1,0), Vector2i(2,1), Vector2i(2,2), Vector2i(3,0), Vector2i(4,1), Vector2i(4,2)]

# all: shape 1 · body_scale 0.60 · no orb · no inner cone · Method-1 vanish · no burst — differ by `evo`
const VARIANTS := [
	{ "title": "1 · Variant 2 base", "subtitle": "wings + body + sparkles", "shape": 1, "body_scale": 0.60, "orb": false, "streak": false, "burst": 1, "evo": 0 },
	{ "title": "2 · Evo A · Plumage", "subtitle": "feather striations + anime ink outline", "shape": 1, "body_scale": 0.60, "orb": false, "streak": false, "burst": 1, "evo": 1 },
	{ "title": "3 · Evo B · Wingsweep", "subtitle": "layered swept wing-arcs + bright leading crest", "shape": 1, "body_scale": 0.60, "orb": false, "streak": false, "burst": 1, "evo": 2 },
]

const TOP_MARGIN := 150.0
const BOT_MARGIN := 30.0

var _total := Vector2.ZERO
var _eff := Vector2.ZERO
var _cell := 0.0
var _aspect := 1.0
var _corridor_uv := Vector3.ZERO   # (hx, hy, cx) in author space
var _corridor_cx_px := 0.0
var _stage_centers: Array[Vector2] = []
var _mats: Array[ShaderMaterial] = []
var _tweens: Array[Tween] = []

func _ready() -> void:
	var n := VARIANTS.size()
	_total = Vector2(float(AREA_TILES.x) + PAD_L + PAD_R, float(AREA_TILES.y) + 2.0 * PAD_TB)
	var usable := VIEW.y - TOP_MARGIN - BOT_MARGIN
	var row_h := usable / float(n)
	_cell = floor(min(VIEW.x * 0.92 / _total.x, row_h * 0.84 / _total.y))
	_eff = _total * _cell
	_aspect = _eff.x / _eff.y

	var corridor_cx_tiles := (PAD_L + float(AREA_TILES.x) * 0.5) - _total.x * 0.5
	_corridor_cx_px = corridor_cx_tiles * _cell
	_corridor_uv = Vector3(
		(float(AREA_TILES.x) * _cell * 0.5) / _eff.y,
		(float(AREA_TILES.y) * _cell * 0.5) / _eff.y,
		_corridor_cx_px / _eff.y)

	_label(HEADER, Vector2(VIEW.x * 0.5 - 760.0, 24.0), 24, Color(0.85, 0.88, 0.95), 1520.0)

	for i in n:
		var stage_center := Vector2(VIEW.x * 0.5, TOP_MARGIN + (float(i) + 0.5) * row_h)
		_stage_centers.append(stage_center)
		_build_panel(VARIANTS[i], stage_center)
	_start_loops()

func _build_panel(v: Dictionary, stage_center: Vector2) -> void:
	var corridor_center := stage_center + Vector2(_corridor_cx_px, 0.0)
	var top := stage_center.y - _eff.y * 0.5
	_label(String(v["title"]), Vector2(stage_center.x - _eff.x * 0.5, top - 34.0), 22, Color(1.0, 0.6, 0.85), _eff.x)
	_label(String(v["subtitle"]), Vector2(stage_center.x + _eff.x * 0.5 - 320.0, top - 30.0), 16, Color(0.7, 0.7, 0.8), 320.0)

	var origin := corridor_center - Vector2(float(AREA_TILES.x), float(AREA_TILES.y)) * _cell * 0.5

	var tex := _load_tower_tex()
	if tex != null:
		var spr := Sprite2D.new()
		spr.texture = tex
		var sc := (_cell * 1.7) / float(tex.get_height())
		spr.scale = Vector2(sc, sc)
		spr.position = corridor_center + Vector2(-(float(AREA_TILES.x) * 0.5 + 0.6) * _cell, 0.0)
		add_child(spr)

	var enemy_tex := load(ENEMY_SPRITE) as Texture2D
	if enemy_tex != null:
		for c in ENEMY_TILES:
			var e := Sprite2D.new()
			e.texture = enemy_tex
			var es := (_cell * 0.55) / float(enemy_tex.get_height())
			e.scale = Vector2(es, es)
			e.position = origin + Vector2((float(c.x) + 0.5) * _cell, (float(c.y) + 0.5) * _cell)
			add_child(e)

	var rect := ColorRect.new()
	rect.size = _eff
	rect.position = stage_center - _eff * 0.5
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load(SHADER)
	mat.set_shader_parameter("progress", 0.0)
	mat.set_shader_parameter("scale_p", 0.0)
	mat.set_shader_parameter("aspect", _aspect)
	mat.set_shader_parameter("corridor_hx", _corridor_uv.x)
	mat.set_shader_parameter("corridor_hy", _corridor_uv.y)
	mat.set_shader_parameter("corridor_cx", _corridor_uv.z)
	mat.set_shader_parameter("shape", int(v["shape"]))
	mat.set_shader_parameter("body_scale", float(v["body_scale"]))
	mat.set_shader_parameter("show_orb", bool(v["orb"]))
	mat.set_shader_parameter("show_streak", bool(v["streak"]))
	mat.set_shader_parameter("burst_mode", int(v["burst"]))
	mat.set_shader_parameter("evo", int(v["evo"]))
	rect.material = mat
	add_child(rect)
	_mats.append(mat)

func _label(text: String, pos: Vector2, size_px: int, color: Color, box_w: float = 600.0) -> void:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = Vector2(box_w, float(size_px) + 12.0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", color)
	add_child(l)

func _load_tower_tex() -> Texture2D:
	var src := load(TOWER_SPRITE) as Texture2D
	if src == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = src
	atlas.region = Rect2(0.0, 0.0, 512.0, 512.0)
	return atlas

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.06, 0.06, 0.09))
	for i in _stage_centers.size():
		var sc: Vector2 = _stage_centers[i]
		draw_rect(Rect2(sc - _eff * 0.5, _eff), Color(0.5, 0.5, 0.7, 0.10), false, 2.0)
		var cc := sc + Vector2(_corridor_cx_px, 0.0)
		var origin := cc - Vector2(float(AREA_TILES.x), float(AREA_TILES.y)) * _cell * 0.5
		for tx in AREA_TILES.x:
			for ty in AREA_TILES.y:
				var r := Rect2(origin + Vector2(float(tx) * _cell, float(ty) * _cell), Vector2(_cell, _cell))
				draw_rect(r, Color(1.0, 0.4, 0.5, 0.05))
				draw_rect(r, Color(1.0, 0.5, 0.6, 0.20), false, 2.0)

func _start_loops() -> void:
	_tweens.resize(_mats.size())
	for i in _mats.size():
		_loop(i)

func _loop(i: int) -> void:
	var mat := _mats[i]
	mat.set_shader_parameter("scale_p", 0.0)
	mat.set_shader_parameter("progress", 0.0)
	var t := create_tween()
	_tweens[i] = t
	t.tween_method(_set_scale.bind(mat), 0.0, 1.0, DURATION * POP_FRAC).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	t.parallel().tween_method(_set_prog.bind(mat), 0.0, 1.0, DURATION)
	t.tween_interval(HOLD)
	t.tween_callback(_loop.bind(i))

func _set_scale(x: float, mat: ShaderMaterial) -> void:
	mat.set_shader_parameter("scale_p", x)

func _set_prog(x: float, mat: ShaderMaterial) -> void:
	mat.set_shader_parameter("progress", x)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		for i in _mats.size():
			if _tweens[i] != null and _tweens[i].is_valid():
				_tweens[i].kill()
			_loop(i)
