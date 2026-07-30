extends Node2D
# ================================================================
# Altare - Gun Blade Slash (skill beat 1) - normal skill VFX controller
#
# Spawned by SkillActionPlayEffect: a bare Node2D is created at the
# caster's global_position, this script is attached, then setup(tower,
# context) is called. One rect (running altare_slash_effect.gdshader)
# is rotated onto the 3x1 tile area in front of Altare - same aim math
# as find_multi_enemy (kiara_skill_effect precedent).
#
# Artist-drawn-base: hands the hand-drawn frames to the shader as
# blade_tex / shard_tex. Textures are preload()ed so the deck-load
# shader warm (which loads this script) pulls them off disk early -
# no first-cast hitch.
# ================================================================

const SHADER_PATH := "res://resources/tower/holostars/en_branch/tempus_gen/altare/skill_effect/altare_slash_effect.gdshader"
const BLADE_TEX := preload("res://resources/tower/holostars/en_branch/tempus_gen/altare/skill_effect/skill1/02.png")
const SHARD_TEX := preload("res://resources/tower/holostars/en_branch/tempus_gen/altare/skill_effect/skill1/06.png")

const EFFECT_ASPECT := 2.4     # must match the shader author-frame ratio
const AREA_W_CELLS  := 3.0     # beat-1 AOE width (tiles)
const WIDTH_PAD     := 1.4     # headroom so the effect never clips the rect edge
const FORWARD_CELLS := 0.9     # push the rect ahead of the caster onto the AOE
const ROT_OFFSET    := PI / 2  # author "up" -> forward

const DURATION := 0.4          # progress 0->1 seconds - tuned to the 0.5s beat (impact_frame 9)
const POP_FRAC := 0.24         # scale_p elastic pop length (fraction of DURATION)

# Called by SkillActionPlayEffect after the node is in the tree.
func setup(tower, context = null) -> void:
	var forward := SkillVfx.resolve_aim(tower, context)
	var sweep_flip := 1.0
	if forward.length() > 0.001:
		forward = forward.normalized()
		global_position += forward * (GridHelper.CELL_SIZE * FORWARD_CELLS)
		rotation = forward.angle() + ROT_OFFSET
		if forward.x < -0.001:
			sweep_flip = -1.0  # aiming left flips the author frame - re-flip so the slash still swings UP
	_spawn_effect(sweep_flip)

func _spawn_effect(sweep_flip: float) -> void:
	var width := AREA_W_CELLS * GridHelper.CELL_SIZE * WIDTH_PAD
	var height := width / EFFECT_ASPECT

	var rect := SkillVfx.make_lane_rect(self, Vector2(width, height), SHADER_PATH)
	var mat := rect.material as ShaderMaterial
	mat.set_shader_parameter("progress", 0.0)
	mat.set_shader_parameter("scale_p", 0.0)
	mat.set_shader_parameter("aspect", EFFECT_ASPECT)
	mat.set_shader_parameter("sweep_flip", sweep_flip)
	mat.set_shader_parameter("blade_tex", BLADE_TEX)
	mat.set_shader_parameter("shard_tex", SHARD_TEX)

	var pop := create_tween()
	pop.set_ease(Tween.EASE_OUT)
	pop.set_trans(Tween.TRANS_ELASTIC)
	pop.tween_method(
		func(v: float): mat.set_shader_parameter("scale_p", v),
		0.0, 1.0, DURATION * POP_FRAC
	)

	var swing := create_tween()
	swing.tween_method(
		func(v: float): mat.set_shader_parameter("progress", v),
		0.0, 1.0, DURATION
	)
	swing.tween_callback(queue_free)
