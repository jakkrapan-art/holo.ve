extends Node2D
# ================================================================
# Altare - Gun Volley (skill beat 2) - normal skill VFX controller
#
# Spawned by SkillActionPlayEffect. Lane family (template shape):
# one rect oriented down the 1-wide x 3-deep gun lane in front of
# the caster; the shot, trail, and impact all live in the shader.
# Evolve tier (1x6 lane) is NOT wired yet - LANE_LEN_CELLS is the
# only knob that changes when it is.
#
# Artist-drawn-base: hands the hand-drawn frames to the shader as
# body_tex / head_tex / star_tex. Textures are preload()ed so the
# deck-load shader warm (which loads this script) pulls them off
# disk early - no first-cast hitch.
# ================================================================

const SHADER_PATH := "res://resources/tower/holostars/en_branch/tempus_gen/altare/skill_effect/altare_volley_effect.gdshader"
const BODY_TEX := preload("res://resources/tower/holostars/en_branch/tempus_gen/altare/skill_effect/skill2/05.png")
const HEAD_TEX := preload("res://resources/tower/holostars/en_branch/tempus_gen/altare/skill_effect/skill2/11.png")
const STAR_TEX := preload("res://resources/tower/holostars/en_branch/tempus_gen/altare/skill_effect/skill2/09.png")

const LANE_LEN_CELLS := 3.0   # beat-2 lane depth (tiles); evolve = 6.0
const VISUAL_W_CELLS := 1.6   # visual rect height (tiles) - may exceed the 1-tile damage width
const LANE_PAD       := 0.25  # frame padding in lane units - MUST match the shader's lane_pad
const ROT_OFFSET     := 0.0   # shader motion runs along +X

const DURATION := 0.6         # progress 0->1 seconds - keep in step with the beat's cast_time; visual stays close to the hitbox
const POP_FRAC := 0.18        # scale_p elastic pop length (fraction of DURATION)

# Called by SkillActionPlayEffect after the node is in the tree.
func setup(tower, context = null) -> void:
	var forward := Vector2.RIGHT
	var aim := SkillVfx.resolve_aim(tower, context)
	if aim.length() > 0.001:
		forward = aim.normalized()
		rotation = forward.angle() + ROT_OFFSET
	var lane_px := LANE_LEN_CELLS * GridHelper.CELL_SIZE
	global_position += forward * (lane_px * 0.5)
	_spawn_effect(lane_px)

func _spawn_effect(lane_px: float) -> void:
	var size := Vector2(lane_px * (1.0 + 2.0 * LANE_PAD), VISUAL_W_CELLS * GridHelper.CELL_SIZE)
	var rect := SkillVfx.make_lane_rect(self, size, SHADER_PATH)
	var mat := rect.material as ShaderMaterial
	mat.set_shader_parameter("progress", 0.0)
	mat.set_shader_parameter("scale_p", 0.0)
	mat.set_shader_parameter("aspect", size.x / size.y)
	mat.set_shader_parameter("lane_pad", LANE_PAD)
	mat.set_shader_parameter("lane_aniso", LANE_LEN_CELLS / VISUAL_W_CELLS)
	# shot leaves the real muzzle - same knob as the homing basic attack
	mat.set_shader_parameter("muzzle_x", Utility.MUZZLE_OFFSET_TILES / LANE_LEN_CELLS)
	mat.set_shader_parameter("body_tex", BODY_TEX)
	mat.set_shader_parameter("head_tex", HEAD_TEX)
	mat.set_shader_parameter("star_tex", STAR_TEX)

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
