extends Node2D
# ================================================================
# BULLET + IMPACT PREVIEW HARNESS TEMPLATE (copy me) - godot-2dfx skill
#
# Purpose (Director 2026-07-22): watch a normal-attack bullet in flight
# AND its on-hit impact beat at near-gameplay scale, compare up to 3
# variants. Nothing else - keep it this light.
# Lane / skill-effect family lives in vfx_preview_harness.gd instead.
#
# Copy to test/<effect>_preview/, point SHADER_PATH at your shader copy,
# fill _variants (max 3, each differing on >= 2 macro axes - see
# skills/godot-2dfx/references/vfx-craft.md). F6 runs it: a volley
# auto-replays; keys 1/2/3 switch variants. Scratch only - DELETE the
# copied folder at handoff (this template folder itself stays).
#
# Every gameplay number below mirrors production - when copying, re-read
# the copied tower's YAML `attack:` block and overwrite them with ITS
# values, never guess. The target is STATIC on purpose: homing flatters
# aim, a moving target hides problems.
#
# This dark background hides blend_add washout: verify additive or
# dark-band effects over the real lit map before calling a look final
# (Kiara Hinotori lesson).
# ================================================================

const SHADER_PATH := "res://test/vfx_template/bullet_template.gdshader"

# --- production mirrors (source value in the comment) ---
const SPEED_TILES := 9.0         # TowerAttackConfig.speed default (tiles/sec)
const BULLET_SIZE := 84.0        # TowerAttackConfig.size default (px; sprite height AND collision diameter)
const BURST := 3                 # TowerAttackConfig.burst default (visual; damage lands once)
const BURST_STAGGER := 0.07      # AttackController._spawnBurstRemainder stagger (sec)
const IMPACT_SIZE_FACTOR := 1.8  # TowerAttackConfig.IMPACT_SIZE_FACTOR (unauthored impact = size * this)
const IMPACT_TIME := 0.35        # TowerAttackConfig.impact_time default (sec)
const IMPACT_QUAD_PX := 64.0     # AttackController.IMPACT_QUAD_PX (impact carrier quad px)

const TARGET_CELLS := 4     # static mock target distance (cells) - match the tower's range
const FACE_TRAVEL := true   # rotate bullet to travel direction; false for upright art (Ina)
const REPLAY_GAP := 0.9     # sec between volleys - set to the copied tower's REAL attack interval so cadence is judgeable

# Static caster sprite for scale/overview context (Director 2026-07-02) -
# first frame only, no animation. ALWAYS the Kiara mock, whatever tower
# the effect belongs to.
const CASTER_SPRITE := "res://resources/tower/hololive/en_branch/myth_gen/kiara/sprite/kiara_stand001.png"
const CASTER_SHEET_GRID := 3  # kiara_stand001.png is a 3x3 sheet of 512px frames

# Max 3 variants. name = short label, intent = one-line artistic intent
# (never a parameter diff), params = shader uniform overrides.
var _variants := {
	1: {
		"name": "Warm bolt",
		"intent": "Graceful register: warm core, soft glow, reads calm.",
		"params": {},
	},
	2: {
		"name": "Hard round",
		"intent": "Powerful register: hot core, tight edge, reads heavy.",
		"params": {"glow_softness": 0.3, "edge_color": Color(1.0, 0.25, 0.05)},
	},
	3: {
		"name": "Cold shard",
		"intent": "Element swap: icy palette - identity check.",
		"params": {
			"core_color": Color(0.9, 0.98, 1.0),
			"mid_color": Color(0.55, 0.8, 1.0),
			"edge_color": Color(0.25, 0.45, 1.0),
		},
	},
}

var _current := 1
var _label: Label
var _timer: Timer
var _target_pos: Vector2
var _bullets: Array[Dictionary] = []  # {spr, mat, elapsed, delay, lead}

func _ready() -> void:
	_label = $HUD/Label
	_target_pos = Vector2(TARGET_CELLS * GridHelper.CELL_SIZE, 0.0)
	var caster := Sprite2D.new()
	caster.texture = load(CASTER_SPRITE)
	caster.hframes = CASTER_SHEET_GRID
	caster.vframes = CASTER_SHEET_GRID
	caster.frame = 0
	add_child(caster)  # added before the bullets -> bullets draw on top
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_fire)
	add_child(_timer)
	_fire()

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var idx := int(key.keycode) - int(KEY_1) + 1
	if _variants.has(idx):
		_current = idx
		_fire()

func _fire() -> void:
	_timer.stop()
	_clear_bullets()
	var v: Dictionary = _variants[_current]
	_label.text = "[%d/%d] %s - %s   (1/2/3 = switch variant)" % [
		_current, _variants.size(), v["name"], v["intent"]
	]
	# Volley mirrors attackProjectile: bullet 0 is the damage carrier (fires the
	# impact), the remainder is cosmetic and staggered. Stagger runs as a per-bullet
	# delay inside _process - no async, so a variant switch mid-volley stays clean.
	for i in BURST:
		_spawn_bullet(i == 0, i * BURST_STAGGER, v["params"])

func _spawn_bullet(lead: bool, delay: float, params: Dictionary) -> void:
	var spr := Sprite2D.new()
	spr.texture = _white_quad()
	var mat := ShaderMaterial.new()
	mat.shader = load(SHADER_PATH)
	mat.set_shader_parameter("phase", 0.0)
	mat.set_shader_parameter("life", 0.0)
	# Mirrors _applyBulletVisual: only overrides are pushed, shader defaults stand.
	for key in params:
		mat.set_shader_parameter(key, params[key])
	spr.material = mat
	spr.scale = Vector2.ONE * (BULLET_SIZE / IMPACT_QUAD_PX)
	var aim := (_target_pos).normalized()
	spr.position = Utility.muzzle_origin(Vector2.ZERO, aim)
	if FACE_TRAVEL:
		spr.rotation = aim.angle()
	spr.visible = delay <= 0.0
	add_child(spr)
	_bullets.append({"spr": spr, "mat": mat, "elapsed": 0.0, "delay": delay, "lead": lead})

func _process(delta: float) -> void:
	if _bullets.is_empty():
		return
	var cell := float(GridHelper.CELL_SIZE)
	for b in _bullets.duplicate():
		if b["delay"] > 0.0:
			b["delay"] -= delta
			b["spr"].visible = b["delay"] <= 0.0
			continue
		var spr: Sprite2D = b["spr"]
		var dir: Vector2 = (_target_pos - spr.position).normalized()
		spr.position += dir * SPEED_TILES * cell * delta
		if FACE_TRAVEL:
			spr.rotation = dir.angle()
		# Mirrors _onBulletMove: seconds-in-flight pushed every frame, and pushed
		# BEFORE the elapsed bump so frame one reads 0.0 (production order).
		b["mat"].set_shader_parameter("life", b["elapsed"])
		b["elapsed"] += delta
		# Arrival threshold mirrors the production collision radius (size * 0.5).
		if spr.position.distance_to(_target_pos) < BULLET_SIZE * 0.5:
			if b["lead"]:
				_spawn_impact()
			_bullets.erase(b)
			spr.queue_free()
	if _bullets.is_empty():
		_timer.start(REPLAY_GAP)

func _clear_bullets() -> void:
	for b in _bullets:
		if is_instance_valid(b["spr"]):
			b["spr"].queue_free()
	_bullets.clear()

# Mirrors AttackController._spawnImpact: phase-1 branch of the SAME shader on a
# square UNROTATED quad (the impact fragment is radial), centred on the target.
func _spawn_impact() -> void:
	var spr := Sprite2D.new()
	spr.texture = _white_quad()
	var mat := ShaderMaterial.new()
	mat.shader = load(SHADER_PATH)
	mat.set_shader_parameter("phase", 1.0)
	mat.set_shader_parameter("progress", 0.0)
	var params: Dictionary = _variants[_current]["params"]
	for key in params:
		mat.set_shader_parameter(key, params[key])
	spr.material = mat
	spr.scale = Vector2.ONE * (BULLET_SIZE * IMPACT_SIZE_FACTOR / IMPACT_QUAD_PX)
	spr.position = _target_pos
	add_child(spr)
	var t := spr.create_tween()
	t.tween_method(
		func(p: float): mat.set_shader_parameter("progress", p),
		0.0, 1.0, IMPACT_TIME
	)
	t.tween_callback(spr.queue_free)

# Plain white carrier quad (mirror of AttackController._whiteQuad) - the shader
# draws everything from UV, sampling nothing.
func _white_quad() -> GradientTexture2D:
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	grad.colors = PackedColorArray([Color.WHITE, Color.WHITE])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.width = int(IMPACT_QUAD_PX)
	tex.height = int(IMPACT_QUAD_PX)
	return tex

func _draw() -> void:
	# caster cell + target cell at true grid scale - the footprint check
	var cell := float(GridHelper.CELL_SIZE)
	_draw_cell(Vector2.ZERO, cell, Color(0.35, 0.9, 0.5))
	_draw_cell(_target_pos, cell, Color(0.95, 0.45, 0.35))

func _draw_cell(centre: Vector2, cell: float, tint: Color) -> void:
	var r := Rect2(centre - Vector2(cell, cell) * 0.5, Vector2(cell, cell))
	draw_rect(r, Color(tint, 0.12), true)
	draw_rect(r, tint, false, 6.0)
