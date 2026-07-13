extends Node2D
# ════════════════════════════════════════════════════════════════
# Calliope evolve · BEAT 1 "reap" VFX controller — self-centered 3x3.
# The elevated reaper crescent + smoke + magenta ink rim (phase 0 of the shared
# calliope_evo_skill_effect.gdshader). Spawned by the evolve skill's play_effect
# action, synced to the beat-1 attack; the second beat (slash) is a SEPARATE
# effect fired by the aftershock explosion (calliope_evo_aftershock_effect.gd).
#
# DURATION MUST stay < the skill's aftershockDelay (mori_calliope.yaml, 0.5s) so
# the reap fully clears before the aftershock slash — keep the two in step.
#
# SHADER_PATH is read by ResourceManager.warmSkillEffectShaders to pre-compile
# the shared pipeline at deck load; because the slash controller points at the
# SAME shader, warming here warms beat 2 too.
# ════════════════════════════════════════════════════════════════

const SHADER_PATH = "res://resources/tower/hololive/en_branch/myth_gen/caliolpe/skill_effect/calliope_evo_skill_effect.gdshader"
const EFFECT_SIZE = GridHelper.CELL_SIZE * 3.0   # 3x3 skill footprint
const PAD         = 2.0                           # visual pad beyond the footprint
const DURATION    = 0.45                           # progress 0->1 seconds (< aftershockDelay 0.5)
const POP_FRAC    = 0.30                           # scale_p elastic pop length (fraction of DURATION)
const PHASE       = 0                              # 0 = reap beat

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
