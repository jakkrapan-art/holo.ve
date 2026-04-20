extends Node2D

const SHADER_PATH = "res://resources/tower/hololive/en_branch/myth_gen/amelia/skill_effect/amelia_skill_effect.gdshader"
const EFFECT_SIZE = GridHelper.CELL_SIZE * 2.0
const BURST_PAD   = 1.4  # matches UV_SCALE in shader — gives burst headroom beyond R
const DURATION    = 0.6

func _ready() -> void:
	var rect := ColorRect.new()
	var draw_size := EFFECT_SIZE * BURST_PAD
	rect.size     = Vector2(draw_size, draw_size)
	rect.position = Vector2(-draw_size / 2.0, -draw_size / 2.0)

	var mat := ShaderMaterial.new()
	mat.shader = load(SHADER_PATH)
	mat.set_shader_parameter("progress", 0.0)
	mat.set_shader_parameter("scale_p", 0.0)
	rect.material = mat
	add_child(rect)

	var scale_tween := create_tween()
	scale_tween.set_ease(Tween.EASE_OUT)
	scale_tween.set_trans(Tween.TRANS_ELASTIC)
	scale_tween.tween_method(
		func(v: float): mat.set_shader_parameter("scale_p", v),
		0.0, 1.0, DURATION * 0.28
	)

	var tween := create_tween()
	tween.tween_method(
		func(v: float): mat.set_shader_parameter("progress", v),
		0.0, 1.0, DURATION
	)
	tween.tween_callback(queue_free)
