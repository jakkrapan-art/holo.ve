extends Node2D

const SHADER_PATH = "res://resources/tower/hololive/en_branch/myth_gen/amelia/skill_effect/amelia_evo_skill_effect.gdshader"
# 5 tiles wide — ใหญ่พอให้เห็นชัดบนหน้าจอหลังกล้อง zoom out
const EFFECT_SIZE = GridHelper.CELL_SIZE * 5.0
const BURST_PAD   = 1.4
const DURATION    = 1.2

func _ready() -> void:
	var rect := ColorRect.new()
	var draw_size := EFFECT_SIZE * BURST_PAD
	rect.size     = Vector2(draw_size, draw_size)
	rect.position = Vector2(-draw_size / 2.0, -draw_size / 2.0)
	# VFX must never eat mouse input: a Control's default filter blocked every
	# world click under the effect for its whole lifetime (SkillVfx rule).
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var mat := ShaderMaterial.new()
	mat.shader = load(SHADER_PATH)
	mat.set_shader_parameter("progress", 0.0)
	mat.set_shader_parameter("scale_p", 0.0)
	rect.material = mat
	add_child(rect)

	# Elastic scale-in (0 → 1.05 → 1.0)
	var scale_tween := create_tween()
	scale_tween.set_ease(Tween.EASE_OUT)
	scale_tween.set_trans(Tween.TRANS_ELASTIC)
	scale_tween.tween_method(
		func(v: float): mat.set_shader_parameter("scale_p", v),
		0.0, 1.0, DURATION * 0.28
	)

	# Progress drives the full animation
	var tween := create_tween()
	tween.tween_method(
		func(v: float): mat.set_shader_parameter("progress", v),
		0.0, 1.0, DURATION
	)
	tween.tween_callback(queue_free)
