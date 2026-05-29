extends Node2D
# ════════════════════════════════════════════════════════════════
# Kiara · Flame Slash — normal skill VFX controller
#
# Spawned by SkillActionPlayEffect: a bare Node2D is created at the
# caster's global_position, this script is attached, then setup(tower)
# is called. We orient a single ColorRect (running kiara_skill_effect
# .gdshader) so the crescent swing lands on the 3×1 tile area in front
# of Kiara — same aim math as find_multi_enemy (toward tower.enemy).
#
# Convention (amelia_skill_effect): progress 0→1 drives the swing,
# scale_p does the elastic pop-in; the effect frees itself when done.
# ════════════════════════════════════════════════════════════════

const SHADER_PATH := "res://resources/tower/hololive/en_branch/myth_gen/kiara/skill_effect/kiara_skill_effect.gdshader"

const EFFECT_ASPECT := 2.4     # must match the shader author-frame ratio
const AREA_W_CELLS  := 3.0     # Flame Slash AOE width (tiles)
const WIDTH_PAD     := 1.4     # headroom so flame never clips the rect edge
const FORWARD_CELLS := 0.9     # push the rect ahead of the caster onto the AOE
const ROT_OFFSET    := PI / 2  # author "up" → forward; flip (±PI/2, PI) if it faces wrong in-engine

const DURATION := 0.85         # progress 0→1 seconds
const POP_FRAC := 0.26         # scale_p elastic pop length (fraction of DURATION)

# Called by SkillActionPlayEffect after the node is in the tree.
# tower is the caster (Tower); tower.enemy is the locked target, if any.
func setup(tower) -> void:
	if tower != null and tower.enemy != null and is_instance_valid(tower.enemy):
		var to_enemy: Vector2 = tower.enemy.global_position - tower.global_position
		if to_enemy.length() > 0.001:
			var forward := to_enemy.normalized()
			global_position += forward * (GridHelper.CELL_SIZE * FORWARD_CELLS)
			rotation = to_enemy.angle() + ROT_OFFSET
	_spawn_effect()

func _spawn_effect() -> void:
	var width := AREA_W_CELLS * GridHelper.CELL_SIZE * WIDTH_PAD
	var height := width / EFFECT_ASPECT

	var rect := ColorRect.new()
	rect.size = Vector2(width, height)
	rect.position = -rect.size * 0.5          # centre on the node origin
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var mat := ShaderMaterial.new()
	mat.shader = load(SHADER_PATH)
	mat.set_shader_parameter("progress", 0.0)
	mat.set_shader_parameter("scale_p", 0.0)
	mat.set_shader_parameter("aspect", EFFECT_ASPECT)
	rect.material = mat
	add_child(rect)

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
