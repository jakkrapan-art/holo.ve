extends Node2D
# ================================================================
# VFX PREVIEW HARNESS TEMPLATE (copy me) - godot-2dfx skill
#
# Purpose (Director 2026-07-02): watch a VFX at true gameplay scale and
# compare up to 3 variants. Nothing else - keep it this light.
#
# Copy to test/<effect>_preview/, point EFFECT_SCRIPT at your controller
# copy, fill _variants (max 3, each differing on >= 2 macro axes - see
# skills/godot-2dfx/references/vfx-craft.md). F6 runs it: the effect
# auto-replays; keys 1/2/3 switch variants. Scratch only - DELETE the
# copied folder at handoff (this template folder itself stays).
#
# This dark background hides blend_add washout: verify additive or
# dark-band effects over the real lit map before calling a look final
# (docs/shader.md Section 3, Kiara Hinotori lesson).
# ================================================================

const EFFECT_SCRIPT := "res://test/vfx_template/lane_effect_template.gd"
const LANE_CELLS := 3    # target cells drawn in front of the caster (match the controller)
const REPLAY_GAP := 0.7  # seconds between auto-replays

# Max 3 variants. name = short label, intent = one-line artistic intent
# (never a parameter diff), params = shader uniform overrides.
var _variants := {
	1: {
		"name": "Clean bolt",
		"intent": "Graceful register: thin core, warm gold, reads calm.",
		"params": {},
	},
	2: {
		"name": "Wide sweep",
		"intent": "Powerful register: broad body and longer trail, reads heavy.",
		"params": {"bolt_hw": 0.30, "bolt_len": 0.75},
	},
	3: {
		"name": "Cold flicker",
		"intent": "Element swap: icy palette, tight body - identity check.",
		"params": {
			"core_color": Color(0.88, 0.97, 1.0),
			"rim_color": Color(0.35, 0.62, 1.0),
			"bolt_hw": 0.12,
		},
	},
}

var _current := 1
var _label: Label
var _timer: Timer

func _ready() -> void:
	_label = $HUD/Label
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
	var v: Dictionary = _variants[_current]
	_label.text = "[%d/%d] %s - %s   (1/2/3 = switch variant)" % [
		_current, _variants.size(), v["name"], v["intent"]
	]
	# Same spawn shape as SkillActionPlayEffect: bare Node2D + script + setup().
	var effect := Node2D.new()
	effect.set_script(load(EFFECT_SCRIPT))
	effect.global_position = Vector2.ZERO  # caster cell centre
	effect.set("uniform_overrides", v["params"])
	add_child(effect)
	if effect.has_method("setup"):
		effect.setup(null)  # null caster -> effect faces RIGHT
	effect.tree_exited.connect(_on_effect_done)

func _on_effect_done() -> void:
	if is_inside_tree() and is_instance_valid(_timer):
		_timer.start(REPLAY_GAP)

func _draw() -> void:
	# caster cell + target lane cells at true grid scale - the footprint check
	var cell := float(GridHelper.CELL_SIZE)
	_draw_cell(Vector2.ZERO, cell, Color(0.35, 0.9, 0.5))
	for i in LANE_CELLS:
		_draw_cell(Vector2((i + 1) * cell, 0.0), cell, Color(0.95, 0.45, 0.35))

func _draw_cell(centre: Vector2, cell: float, tint: Color) -> void:
	var r := Rect2(centre - Vector2(cell, cell) * 0.5, Vector2(cell, cell))
	draw_rect(r, Color(tint, 0.12), true)
	draw_rect(r, tint, false, 6.0)
