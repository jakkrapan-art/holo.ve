extends Node2D
# ════════════════════════════════════════════════════════════════
# Josuiji Shinri · "Heartpierce Shot" crit pierce-arrow VFX controller — EVOLVE tier.
#
# Same lane-static spawn as the normal controller, but the evolve shader has TWO clocks:
#   - progress : the bolt (head travels the lane), runs over `travel_dur`.
#   - life_t   : the charm particles/hearts, runs over the LONGER `total_dur` so they
#                linger and fade AFTER the bolt is gone. shot_frac = travel_dur/total_dur
#                tells the shader the life_t value at which the bolt ends.
# The wide-pierce DAMAGE is the separate shinri_skill_projectile.
# ════════════════════════════════════════════════════════════════

const SHADER_PATH := "res://resources/tower/holostars/en_branch/tempus_gen/josuiji_shinri/skill_effect/shinri_evo_skill_effect.gdshader"

const LANE_PAD       := 0.25    # must match the shader lane_pad uniform
const RANGE_TILES    := 4.0     # arrow_range — lane length in tiles
const VISUAL_H_CELLS := 1.6     # lane visual height
const POP_FRAC       := 0.22    # scale_p elastic pop length (fraction of bolt travel)
const SHOT_FRAC      := 0.55    # bolt = first SHOT_FRAC of the total; particles linger after

func setup(tower, aim_dir: Vector2, travel_dur: float) -> void:
	if aim_dir.length() <= 0.001:
		aim_dir = Vector2.RIGHT
	aim_dir = aim_dir.normalized()
	var lane_len := RANGE_TILES * float(GridHelper.CELL_SIZE)
	global_position = tower.global_position + aim_dir * (lane_len * 0.5)
	rotation = aim_dir.angle()
	_spawn_effect(lane_len, maxf(travel_dur, 0.05))

func _spawn_effect(lane_len: float, bolt_dur: float) -> void:
	var total_dur := bolt_dur / SHOT_FRAC      # bolt + lingering particles
	var visual_len := lane_len * (1.0 + 2.0 * LANE_PAD)
	var visual_h := VISUAL_H_CELLS * float(GridHelper.CELL_SIZE)

	var rect := ColorRect.new()
	rect.size = Vector2(visual_len, visual_h)
	rect.position = -rect.size * 0.5
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var mat := ShaderMaterial.new()
	mat.shader = load(SHADER_PATH)
	mat.set_shader_parameter("progress", 0.0)
	mat.set_shader_parameter("life_t", 0.0)
	mat.set_shader_parameter("scale_p", 0.0)
	mat.set_shader_parameter("lane_pad", LANE_PAD)
	mat.set_shader_parameter("shot_frac", SHOT_FRAC)
	rect.material = mat
	add_child(rect)

	var pop := create_tween()
	pop.set_ease(Tween.EASE_OUT)
	pop.set_trans(Tween.TRANS_ELASTIC)
	pop.tween_method(func(v: float): mat.set_shader_parameter("scale_p", v), 0.0, 1.0, bolt_dur * POP_FRAC)

	# bolt travels over bolt_dur
	var run := create_tween()
	run.tween_method(func(v: float): mat.set_shader_parameter("progress", v), 0.0, 1.0, bolt_dur)

	# particles/hearts run over the longer total_dur, then free
	var life := create_tween()
	life.tween_method(func(v: float): mat.set_shader_parameter("life_t", v), 0.0, 1.0, total_dur)
	life.tween_callback(queue_free)
