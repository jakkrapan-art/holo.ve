extends Node2D
# ════════════════════════════════════════════════════════════════
# Josuiji Shinri · "Bull Eyes" crit pierce-arrow VFX controller — NORMAL tier.
#
# Spawned by PassiveCritPierce._fire_arrow on a crit: a bare Node2D is created,
# this script attached, then setup(tower, aim_dir, travel_dur). We orient one
# lane-static ColorRect (running shinri_skill_effect.gdshader) so the arrow's
# 1×4 lane lies along the crit direction; the head travels the lane via
# `progress` (0→1). The wide-pierce DAMAGE is the separate shinri_skill_projectile.
#
# Convention (kiara_skill_effect): progress 0→1 = the shot, scale_p does the
# elastic pop-in; the effect frees itself when done.
# ════════════════════════════════════════════════════════════════

const SHADER_PATH := "res://resources/tower/holostars/en_branch/tempus_gen/josuiji_shinri/skill_effect/shinri_skill_effect.gdshader"

const LANE_PAD       := 0.25    # must match the shader lane_pad uniform
const RANGE_TILES    := 4.0     # arrow_range — lane length in tiles
const VISUAL_H_CELLS := 1.6     # lane visual height (1 tile + glow headroom)
const POP_FRAC       := 0.30    # scale_p elastic pop length (fraction of travel)

# Called by PassiveCritPierce after the node is in the tree.
func setup(tower, aim_dir: Vector2, travel_dur: float) -> void:
	if aim_dir.length() <= 0.001:
		aim_dir = Vector2.RIGHT
	aim_dir = aim_dir.normalized()
	var lane_len := RANGE_TILES * float(GridHelper.CELL_SIZE)
	# Lane origin (lane-x 0) starts at the muzzle point (pushed off the tower centre
	# along the aim), matching the damage projectile so the visible arrow leaves the
	# character edge, not its belly. Then push forward half a lane so lane-x 1 lands
	# on the range end (the ColorRect is centred on this node; the padded quad spans
	# the lane midpoint).
	var muzzle := Utility.muzzle_origin(tower.global_position, aim_dir)
	global_position = muzzle + aim_dir * (lane_len * 0.5)
	rotation = aim_dir.angle()
	_spawn_effect(lane_len, maxf(travel_dur, 0.05))

func _spawn_effect(lane_len: float, dur: float) -> void:
	var visual_len := lane_len * (1.0 + 2.0 * LANE_PAD)
	var visual_h := VISUAL_H_CELLS * float(GridHelper.CELL_SIZE)

	var rect := ColorRect.new()
	rect.size = Vector2(visual_len, visual_h)
	rect.position = -rect.size * 0.5           # centre on the node origin
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var mat := ShaderMaterial.new()
	mat.shader = load(SHADER_PATH)
	mat.set_shader_parameter("progress", 0.0)
	mat.set_shader_parameter("scale_p", 0.0)
	mat.set_shader_parameter("lane_pad", LANE_PAD)
	rect.material = mat
	add_child(rect)

	var pop := create_tween()
	pop.set_ease(Tween.EASE_OUT)
	pop.set_trans(Tween.TRANS_ELASTIC)
	pop.tween_method(func(v: float): mat.set_shader_parameter("scale_p", v), 0.0, 1.0, dur * POP_FRAC)

	var run := create_tween()
	run.tween_method(func(v: float): mat.set_shader_parameter("progress", v), 0.0, 1.0, dur)
	run.tween_callback(queue_free)
