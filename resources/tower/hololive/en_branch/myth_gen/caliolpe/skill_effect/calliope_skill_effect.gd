extends Node2D
# ════════════════════════════════════════════════════════════════
# Calliope · "Ricky" (normal) VFX controller — self-centered 3x3 scythe sweep.
# Self-centered / aura family (docs/shader.md): no lane helpers, one stationary
# square ColorRect centred on the caster; the shader plays the whole sweep via
# `progress`. Spawned by SkillActionPlayEffect (bare Node2D at tower.global_position);
# no setup() needed — the effect is centred, nothing to orient (Amelia precedent).
#
# SHADER_PATH is read by ResourceManager.warmSkillEffectShaders to pre-compile the
# pipeline at deck load, so the first in-run cast doesn't hitch.
# ════════════════════════════════════════════════════════════════

const SHADER_PATH = "res://resources/tower/hololive/en_branch/myth_gen/caliolpe/skill_effect/calliope_skill_effect.gdshader"
const EFFECT_SIZE = GridHelper.CELL_SIZE * 3.0   # 3x3 skill footprint
const PAD         = 2.0                           # visual pad beyond the footprint
const DURATION    = 0.85                           # progress 0->1 seconds
const POP_FRAC    = 0.22                           # scale_p elastic pop length (fraction of DURATION)

func _ready() -> void:
	var draw_size := EFFECT_SIZE * PAD
	var rect := ColorRect.new()
	rect.size     = Vector2(draw_size, draw_size)
	rect.position = Vector2(-draw_size / 2.0, -draw_size / 2.0)
	# VFX must never eat mouse input: a Control's default filter blocked every
	# world click under the effect for its whole lifetime (SkillVfx rule).
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var mat := ShaderMaterial.new()
	mat.shader = load(SHADER_PATH)
	mat.set_shader_parameter("progress", 0.0)
	mat.set_shader_parameter("scale_p", 0.0)
	mat.set_shader_parameter("aspect", 1.0)
	rect.material = mat
	add_child(rect)

	var pop := create_tween()
	pop.set_ease(Tween.EASE_OUT)
	pop.set_trans(Tween.TRANS_ELASTIC)
	pop.tween_method(
		func(v: float): mat.set_shader_parameter("scale_p", v),
		0.0, 1.0, DURATION * POP_FRAC
	)

	var run := create_tween()
	run.tween_method(
		func(v: float): mat.set_shader_parameter("progress", v),
		0.0, 1.0, DURATION
	)
	run.tween_callback(queue_free)
