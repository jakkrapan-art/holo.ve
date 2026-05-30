extends Node2D
# ════════════════════════════════════════════════════════════════
# Kiara · Hinotori (evo) VFX controller — magma-violet Wingsweep phoenix
# rushing across the 3×5 corridor. Spawned by SkillActionPlayEffect: a bare
# Node2D is created at the caster, this script attached, then setup(tower).
#
# The shader (kiara_evo_skill_effect.gdshader) plays the WHOLE rush
# (slash → launch → rush → lingering-sparkle vanish) internally via the
# `progress` uniform over one stationary ColorRect; the wide-pierce DAMAGE is
# the separate kiara_skill_projectile. So this effect is a single oriented
# rect, NOT bound to the moving projectile.
#
# Orientation note: unlike the normal Flame Slash (which rotates +PI/2), this
# shader's motion runs along its local +X (head_x: LEFT→RIGHT), so we rotate
# by exactly to_enemy.angle() — the shader's +X then points at the target lane.
#
# Geometry mirrors the tuned harness (kiara_evo_preview.gd): a 5×3 damage
# corridor inside a padded frame; corridor_hx/hy/cx map it into shader UV.
# ════════════════════════════════════════════════════════════════

const SHADER_PATH := "res://resources/tower/hololive/en_branch/myth_gen/kiara/skill_effect/kiara_evo_skill_effect.gdshader"

const AREA_LEN_CELLS := 5.0   # corridor length (matches find_multi_enemy height)
const AREA_W_CELLS   := 3.0   # corridor width  (matches find_multi_enemy width)
const PAD_L  := 1.0           # visual pad (tiles) — slash/launch room
const PAD_R  := 2.2           # visual pad — rush/impact headroom
const PAD_TB := 1.0           # visual pad — wing/ember spill

const ROT_OFFSET   := 0.0     # shader rushes along +X → face the lane directly
const MOUTH_AHEAD  := 0.6      # corridor mouth (slash) this many cells ahead of caster (tune in-engine)

const DURATION := 1.15        # progress 0→1 seconds
const POP_FRAC := 0.16        # scale_p elastic pop length (fraction of DURATION)

func setup(tower) -> void:
	var cell := float(GridHelper.CELL_SIZE)
	var total_x := AREA_LEN_CELLS + PAD_L + PAD_R
	var total_y := AREA_W_CELLS + 2.0 * PAD_TB
	var eff := Vector2(total_x * cell, total_y * cell)
	var aspect := eff.x / eff.y
	# corridor centre offset inside the padded frame (more pad on the right)
	var corridor_cx_tiles := (PAD_L + AREA_LEN_CELLS * 0.5) - total_x * 0.5
	var hx := (AREA_LEN_CELLS * cell * 0.5) / eff.y
	var hy := (AREA_W_CELLS * cell * 0.5) / eff.y
	var cx := (corridor_cx_tiles * cell) / eff.y

	# Orient toward the locked target — same lane as find_multi_enemy.
	var forward := Vector2.RIGHT
	if tower != null and tower.enemy != null and is_instance_valid(tower.enemy):
		var to_enemy: Vector2 = tower.enemy.global_position - tower.global_position
		if to_enemy.length() > 0.001:
			forward = to_enemy.normalized()
			rotation = forward.angle() + ROT_OFFSET

	# Push the rect forward so the corridor mouth (slash) sits ~MOUTH_AHEAD cells
	# ahead of the caster. The rect centre is (hx - cx) author-units ahead of the
	# corridor's left edge; 1 author-unit == eff.y px.
	var center_ahead_px := (hx - cx) * eff.y
	global_position += forward * (center_ahead_px + MOUTH_AHEAD * cell)

	_spawn_effect(eff, aspect, hx, hy, cx)

func _spawn_effect(eff: Vector2, aspect: float, hx: float, hy: float, cx: float) -> void:
	var rect := ColorRect.new()
	rect.size = eff
	rect.position = -eff * 0.5            # centre on the node origin
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var mat := ShaderMaterial.new()
	mat.shader = load(SHADER_PATH)
	# dynamic uniforms only — the look (shape/evo/show_*/body_scale/burst) is
	# baked as defaults in the shader.
	mat.set_shader_parameter("progress", 0.0)
	mat.set_shader_parameter("scale_p", 0.0)
	mat.set_shader_parameter("aspect", aspect)
	mat.set_shader_parameter("corridor_hx", hx)
	mat.set_shader_parameter("corridor_hy", hy)
	mat.set_shader_parameter("corridor_cx", cx)
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
