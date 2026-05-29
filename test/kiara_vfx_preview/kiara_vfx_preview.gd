extends Node2D
# ════════════════════════════════════════════════════════════════
# Universal VFX preview harness  (run this scene with F6)
#
# Shows N shader variants side-by-side over a tower + AoE-tile stage.
# Each variant auto-loops: scale_p elastic pop → progress 0→1 → hold →
# repeat. Click anywhere to replay all immediately.
#
# To preview a different tower/skill, edit the CONFIG block below.
# Every variant is its own canvas_item shader using the shared
# progress / scale_p convention (see amelia_skill_effect.gdshader).
# ════════════════════════════════════════════════════════════════

# ── CONFIG ──────────────────────────────────────────────────────
const VIEW := Vector2(1920.0, 1080.0)
const TOWER_SPRITE := "res://resources/tower/hololive/en_branch/myth_gen/kiara/sprite/kiara_attack001.png"
const ENEMY_SPRITE := "res://resources/enemy/enemy_test.png"
const AREA_TILES := Vector2i(3, 1)      # skill AoE footprint (width × height)
const CELL := 150.0                     # preview tile size (px)
const EFFECT_ASPECT := 2.4              # author-frame width/height of the shaders
const DURATION := 0.85                  # progress 0→1 duration (s)
const POP_FRAC := 0.26                  # scale_p pop length as a fraction of DURATION
const HOLD := 0.45                      # pause between loops (s)

const HEADER := "Kiara · Flame Slash — Concept Preview  (click to replay)"

const VARIANTS := [
	{
		"title": "A · Crescent (shape ref)",
		"subtitle": "single clean blade",
		"shader": "res://test/kiara_vfx_preview/a_crescent_slash.gdshader",
	},
	{
		"title": "★ AB · Flame Slash",
		"subtitle": "A shape + B flow — candidate",
		"shader": "res://test/kiara_vfx_preview/ab_flame_slash.gdshader",
	},
	{
		"title": "B · Wing (feel ref)",
		"subtitle": "flow/erode — but 3-feather = claw",
		"shader": "res://test/kiara_vfx_preview/b_phoenix_wing.gdshader",
	},
]

var _mats: Array[ShaderMaterial] = []
var _stage_centers: Array[Vector2] = []
var _tweens: Array[Tween] = []

func _ready() -> void:
	_label(HEADER, Vector2(VIEW.x * 0.5 - 600.0, 30.0), 26, Color(0.85, 0.88, 0.95), 1200.0)
	var n := VARIANTS.size()
	var panel_w := VIEW.x / float(n)
	for i in n:
		var v: Dictionary = VARIANTS[i]
		var cx := panel_w * (float(i) + 0.5)
		var stage_center := Vector2(cx, VIEW.y * 0.48)
		_stage_centers.append(stage_center)
		_build_panel(v, cx, stage_center)
	_start_loops()

func _build_panel(v: Dictionary, cx: float, stage_center: Vector2) -> void:
	# title + subtitle
	_label(String(v["title"]), Vector2(cx - 300.0, 96.0), 34, Color(1.0, 0.85, 0.40))
	_label(String(v["subtitle"]), Vector2(cx - 300.0, 142.0), 20, Color(0.72, 0.72, 0.82))

	# tower sprite (caster) — below the AoE stage, centred in the panel
	var tex := _load_tower_tex()
	if tex != null:
		var spr := Sprite2D.new()
		spr.texture = tex
		var sc := (CELL * 1.4) / float(tex.get_height())
		spr.scale = Vector2(sc, sc)
		spr.position = stage_center + Vector2(0.0, CELL * 1.9)
		add_child(spr)

	# enemy markers inside the AoE tiles (context)
	var enemy_tex := load(ENEMY_SPRITE) as Texture2D
	if enemy_tex != null:
		var origin := stage_center - Vector2(float(AREA_TILES.x), float(AREA_TILES.y)) * CELL * 0.5
		for tx in AREA_TILES.x:
			for ty in AREA_TILES.y:
				var e := Sprite2D.new()
				e.texture = enemy_tex
				var es := (CELL * 0.5) / float(enemy_tex.get_height())
				e.scale = Vector2(es, es)
				e.position = origin + Vector2((float(tx) + 0.5) * CELL, (float(ty) + 0.5) * CELL)
				add_child(e)

	# VFX rect (over the AoE tiles)
	var eff_w := float(AREA_TILES.x) * CELL * 1.18 * 1.2   # x1.2 enlarge
	var eff_h := eff_w / EFFECT_ASPECT
	var rect := ColorRect.new()
	rect.size = Vector2(eff_w, eff_h)
	rect.position = stage_center - rect.size * 0.5
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load(String(v["shader"]))
	mat.set_shader_parameter("progress", 0.0)
	mat.set_shader_parameter("scale_p", 0.0)
	mat.set_shader_parameter("aspect", EFFECT_ASPECT)
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
	# kiara_attack001 is a sprite sheet; grab the top-left 512×512 frame.
	var src := load(TOWER_SPRITE) as Texture2D
	if src == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = src
	atlas.region = Rect2(0.0, 0.0, 512.0, 512.0)
	return atlas

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.06, 0.06, 0.09))
	# header
	var n := VARIANTS.size()
	var panel_w := VIEW.x / float(n)
	for i in n:
		# panel divider
		if i > 0:
			draw_line(Vector2(panel_w * float(i), 70.0), Vector2(panel_w * float(i), VIEW.y - 50.0), Color(1, 1, 1, 0.07), 2.0)
		# AoE tile outlines
		var center: Vector2 = _stage_centers[i]
		var origin := center - Vector2(float(AREA_TILES.x), float(AREA_TILES.y)) * CELL * 0.5
		for tx in AREA_TILES.x:
			for ty in AREA_TILES.y:
				var r := Rect2(origin + Vector2(float(tx) * CELL, float(ty) * CELL), Vector2(CELL, CELL))
				draw_rect(r, Color(1.0, 0.5, 0.2, 0.05))
				draw_rect(r, Color(1.0, 0.6, 0.3, 0.22), false, 2.0)

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
