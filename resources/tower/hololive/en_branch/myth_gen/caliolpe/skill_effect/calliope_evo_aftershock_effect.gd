extends Node2D
# ════════════════════════════════════════════════════════════════
# Calliope evolve · BEAT 2 "slash" VFX controller — self-centered 3x3.
# The elevated cross-slash flurry + closing reap-ring (phase 1 of the shared
# calliope_evo_skill_effect.gdshader). Spawned by the aftershock EXPLOSION
# (SkillActionAftershock -> AftershockTimer._fire), so it lands exactly on the
# second damage tick and rides the same pause/x2 game clock. The reap (beat 1)
# is the separate calliope_evo_skill_effect.gd.
#
# Shares SHADER_PATH with the reap controller, so the beat-1 play_effect warm
# already covers this beat — no separate warm entry needed.
# ════════════════════════════════════════════════════════════════

const SHADER_PATH = "res://resources/tower/hololive/en_branch/myth_gen/caliolpe/skill_effect/calliope_evo_skill_effect.gdshader"
const EFFECT_SIZE = GridHelper.CELL_SIZE * 3.0   # 3x3 skill footprint
const PAD         = 2.0                           # visual pad beyond the footprint
const DURATION    = 0.65                           # progress 0->1 seconds (the flurry + closing ring)
const POP_FRAC    = 0.16                           # scale_p elastic pop length (fraction of DURATION)
const PHASE       = 1                              # 1 = slash beat

func _ready() -> void:
	var draw_size := EFFECT_SIZE * PAD
	var rect := ColorRect.new()
	rect.size     = Vector2(draw_size, draw_size)
	rect.position = Vector2(-draw_size / 2.0, -draw_size / 2.0)

	var mat := ShaderMaterial.new()
	mat.shader = load(SHADER_PATH)
	mat.set_shader_parameter("progress", 0.0)
	mat.set_shader_parameter("scale_p", 0.0)
	mat.set_shader_parameter("aspect", 1.0)
	mat.set_shader_parameter("phase", PHASE)
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
