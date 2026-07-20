extends Node2D
# ================================================================
# LANE SKILL-VFX CONTROLLER TEMPLATE (copy me) - godot-2dfx skill
#
# COPY, do not edit in place:
#   1. Copy this .gd + lane_effect_template.gdshader into
#      test/<effect>_preview/ (iteration) or the tower's skill_effect/
#      folder (production), rename both to the effect's name.
#   2. Point SHADER_PATH at the copied shader, tune the consts, replace
#      the shader's placeholder layers with the real effect.
#   3. Production spawn path: SkillActionPlayEffect creates a bare
#      Node2D at the caster, attaches this script, then calls
#      setup(tower, context). YAML: action type "play_effect" ->
#      data.effect_script = this file's res:// path.
#
# Anchor files (SKILL.md intake - read before designing):
#   benchmark  resources/tower/hololive/en_branch/myth_gen/kiara/
#              skill_effect/kiara_evo_skill_effect.gd + .gdshader
#              (Hinotori - the project quality bar)
#   this shape kiara_skill_effect.gd + .gdshader (Flame Slash)
#
# OTHER FAMILIES:
#   centered/aura  - drop setup()'s aim/rotation and the lane include;
#                    keep the rect + tweens. See amelia_skill_effect.gd.
#   lingering tail - a second, longer clock ("life_t") owns queue_free.
#                    See shinri_evo_skill_effect.gd.
#   bullet         - visual rides the projectile via the tower YAML
#                    `attack:` block, not a controller like this one.
#                    See amelia/normal_effect/amelia_bullet.gdshader.
# ================================================================

const SHADER_PATH := "res://test/vfx_template/lane_effect_template.gdshader"

const LANE_LEN_CELLS := 3.0   # gameplay lane length (tiles) - match the skill's range/AOE
const VISUAL_W_CELLS := 1.6   # visual rect height (tiles) - may exceed the damage width
const LANE_PAD       := 0.25  # frame padding in lane units - MUST match the shader's lane_pad
const ROT_OFFSET     := 0.0   # shader motion runs along +X; flip (+-PI/2, PI) if it faces wrong
const DURATION       := 0.9   # progress 0->1 seconds
const POP_FRAC       := 0.22  # scale_p elastic pop length (fraction of DURATION)

# Preview-only: the harness injects per-variant uniforms here before setup().
# Production leaves it empty - bake the final look into the shader defaults.
var uniform_overrides: Dictionary = {}

# Called by SkillActionPlayEffect after the node is in the tree (or by the
# preview harness with tower = null, which keeps the default RIGHT facing).
func setup(tower, context = null) -> void:
	var forward := Vector2.RIGHT
	var aim := SkillVfx.resolve_aim(tower, context)  # live target -> aim snapshot -> ZERO
	if aim.length() > 0.001:
		forward = aim.normalized()
		rotation = forward.angle() + ROT_OFFSET
	# Centre the padded rect so lane-x 0 (the caster) sits on this node.
	# Production may also add Utility.MUZZLE_OFFSET_TILES * cell so the bolt
	# leaves the sprite edge, not its belly (see kiara_evo_skill_effect.gd).
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
	for key in uniform_overrides:
		mat.set_shader_parameter(key, uniform_overrides[key])

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
