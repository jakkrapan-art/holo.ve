extends Sprite2D
class_name EvoTokenDrop

# World-space loot-drop visual for boss kills. Three phases:
#   1. POP-IN  — scale-bounces in from 30% to full size
#   2. HOLD    — rests on the ground while sparkle particles emit
#   3. FLOAT   — rises and fades out
# Currency wallet is updated elsewhere via Player.processReward — this scene
# is visual feedback only. Self-cleans via tween.tween_callback(queue_free).

const TOKEN_TEXTURE_PATH := "res://resources/currency/evo_token.png"
const TOKEN_SCALE := Vector2(4.0, 4.0)

const POP_IN_DURATION := 0.3
const HOLD_DURATION := 0.8
const FLOAT_DURATION := 1.4
const FLOAT_HEIGHT := 120.0
const FADE_RATIO := 0.4  # last 40% of float fades alpha to 0

const PARTICLE_AMOUNT := 14
const PARTICLE_LIFETIME := 0.7
const PARTICLE_RADIUS := 30.0

# Total animation length = POP_IN + HOLD + FLOAT (used by GameScene to time
# the wave-end popup so it does not occlude this drop).
const TOTAL_DURATION := POP_IN_DURATION + HOLD_DURATION + FLOAT_DURATION

# Cached procedurally-generated sparkle texture, shared across all drops.
static var _sparkle_texture: ImageTexture

static func spawn(world_position: Vector2, parent: Node) -> EvoTokenDrop:
	var drop := EvoTokenDrop.new()
	drop.texture = load(TOKEN_TEXTURE_PATH)
	drop.z_index = 10  # above enemies/towers, below CanvasLayer UI popups
	parent.add_child(drop)
	# global_position must be set AFTER add_child so parent transform applies.
	drop.global_position = world_position
	drop._start_animation()
	# TODO: SFX — no audio asset yet. When ready, register a new
	# SoundDatabase.SFX_NAME entry (e.g. EVO_TOKEN_DROP) and call
	#   AudioManager.playSfx(SoundDatabase.SFX_NAME.EVO_TOKEN_DROP)
	# right after add_child. No null-guard needed once the asset is wired.
	return drop

func _start_animation():
	# Pop-in starts small; tween restores to TOKEN_SCALE with a slight overshoot.
	scale = TOKEN_SCALE * 0.3
	var rise_target := position + Vector2(0, -FLOAT_HEIGHT)

	var tween := create_tween()
	# Phase 1 — pop in
	tween.tween_property(self, "scale", TOKEN_SCALE, POP_IN_DURATION)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Phase 2 — emit particles, hold position
	tween.tween_callback(_spawn_sparkle_particles)
	tween.tween_interval(HOLD_DURATION)
	# Phase 3 — float up + overlapping fade
	tween.tween_property(self, "position", rise_target, FLOAT_DURATION)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 0.0, FLOAT_DURATION * FADE_RATIO)\
		.set_delay(FLOAT_DURATION * (1.0 - FADE_RATIO))
	# Phase 4 — cleanup
	tween.tween_callback(queue_free)

func _spawn_sparkle_particles():
	var particles := GPUParticles2D.new()
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = PARTICLE_RADIUS
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 180.0  # full circle scatter
	mat.gravity = Vector3.ZERO
	mat.initial_velocity_min = 25.0
	mat.initial_velocity_max = 65.0
	mat.scale_min = 0.6
	mat.scale_max = 1.4
	mat.color = Color(1.0, 0.92, 0.45)  # warm star-yellow
	# Fade-out alpha curve over particle lifetime.
	var alpha_curve := Curve.new()
	alpha_curve.add_point(Vector2(0.0, 1.0))
	alpha_curve.add_point(Vector2(1.0, 0.0))
	var alpha_curve_tex := CurveTexture.new()
	alpha_curve_tex.curve = alpha_curve
	mat.alpha_curve = alpha_curve_tex

	particles.process_material = mat
	particles.texture = _get_sparkle_texture()
	particles.amount = PARTICLE_AMOUNT
	particles.lifetime = PARTICLE_LIFETIME
	particles.one_shot = true
	particles.explosiveness = 0.4
	add_child(particles)

static func _get_sparkle_texture() -> ImageTexture:
	if _sparkle_texture == null:
		# Procedural 8x8 plus-shape sparkle — no external asset needed.
		var size := 8
		var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		var c := size / 2
		for i in range(size):
			img.set_pixel(i, c, Color.WHITE)
			img.set_pixel(c, i, Color.WHITE)
		_sparkle_texture = ImageTexture.create_from_image(img)
	return _sparkle_texture
