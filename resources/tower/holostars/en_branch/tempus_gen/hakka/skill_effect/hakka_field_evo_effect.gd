extends Node2D
# ================================================================
# Banzoin Hakka · "Obey my omen, in hymns allure" (EVOLVE) VFX
# controller — the FIELD-family effect for the 5x5 evolved zone.
# Structurally identical to the normal hakka_field_effect.gd (read
# its header for the full field lifecycle + layer model); only the
# deltas below differ.
#
# Deltas vs the normal controller:
#   - SHADER_PATH -> the evolve shader (black-fire cyclone "Burning
#     Sutra": E3c, Director-approved 2026-07-18).
#   - FADE_NATURAL 0.6 -> 0.9: the natural-expiry fade doubles as the
#     +20% Energy REFUND beat (white feather rises, script sung
#     skyward, bead overload). The refund is granted on the SAME
#     `finished` signal (SkillActionField._on_field_finished), so the
#     Energy jump and the VFX beat share one event.
#   - refund_beat uniform: the shader gates its entire refund
#     choreography on `expire`, but `expire` sweeps on BOTH exit paths
#     (natural AND wave-end cancel). Without a gate a cancel would flash
#     the feather with no refund granted. So refund_beat starts 1.0 and
#     is forced to 0.0 on the cancel path — the feather/overload/skyward
#     play ONLY on natural expiry, matching the refund.
#
# LAYER model (same as normal): drawn TWICE — fx_layer 0 = ground zone
# (flame sea + beads) under enemies via the map subtree, 1 = front
# (script columns + the rising feather) above towers/enemies.
#
# SHADER_PATH is read by ResourceManager.warmSkillEffectShaders (it
# scans evolutionSkill field actions too) to pre-compile at deck load.
# ================================================================

const SHADER_PATH := "res://resources/tower/holostars/en_branch/tempus_gen/hakka/skill_effect/hakka_field_evo_effect.gdshader"
const PAD := 1.35            # visual pad beyond the footprint (free: damage is code-side)
const PLANT_TIME := 0.5
const FADE_NATURAL := 0.9    # longer than normal's 0.6: the refund beat lives in this fade
const FADE_CANCEL := 0.25

var _mats: Array[ShaderMaterial] = []
var _back_holder: Node2D = null   # ground-layer host inside the map subtree
var _t := 0.0
var _fade_time := FADE_NATURAL
var _exp_t := -1.0           # >= 0 once expiring

# Called by SkillActionField right after spawn. Footprint (cells) comes from
# the action so the same controller serves any field size (evolve = 5x5).
func setup_field(_tower: Tower, action: SkillActionField, ticker: SkillActionChannel.ChannelTicker) -> void:
	_build(float(action.width))
	Utility.ConnectSignal(ticker, "finished",
			Callable(self, "_on_field_finished").bind(ticker))

func _ready() -> void:
	call_deferred("_ensure_built")

func _ensure_built() -> void:
	# Spawned without setup_field() means no ticker `finished` will ever arrive,
	# so a built zone would live forever - fail loud and free instead (this
	# controller is field-only; wire it via the field action's effect_script).
	if _mats.is_empty():
		push_warning("hakka_field_evo_effect: spawned without setup_field() - freeing (use the field action's effect_script, not play_effect).")
		queue_free()

func _build(cells: float) -> void:
	var draw_size := GridHelper.CELL_SIZE * cells * PAD
	var shader: Shader = load(SHADER_PATH)
	var ground_map := _resolve_ground_map()
	for side in 2:
		var rect := ColorRect.new()
		rect.size = Vector2(draw_size, draw_size)
		rect.position = Vector2(-draw_size / 2.0, -draw_size / 2.0)
		# VFX must never eat mouse input (SkillVfx rule) — and a field sits
		# under the cursor for its whole 10s life, so this matters even more
		# here than on burst effects.
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("fx_layer", side)
		mat.set_shader_parameter("plant", 0.0)
		mat.set_shader_parameter("scale_p", 0.01)
		mat.set_shader_parameter("loop_time", 0.0)
		mat.set_shader_parameter("expire", 0.0)
		mat.set_shader_parameter("refund_beat", 1.0)  # 1 = play the refund beat; 0 on cancel
		rect.material = mat
		if side == 0 and ground_map != null:
			# Ground layer: hosted inside the map subtree, ordered before the
			# Path2D so enemies (its children) draw over the zone.
			_back_holder = Node2D.new()
			ground_map.add_child(_back_holder)
			ground_map.move_child(_back_holder, ground_map.path.get_index())
			_back_holder.global_position = global_position
			_back_holder.add_child(rect)
		elif side == 0:
			rect.z_index = -1   # fallback: under towers only
			add_child(rect)
		else:
			add_child(rect)     # front script + feather, above towers/enemies
		_mats.append(mat)

# The Map (a TileMap, z -1) is a sibling of this effect under the game-scene
# root; its `path` export holds the Path2D the enemies spawn under.
func _resolve_ground_map() -> Map:
	var parent := get_parent()
	if parent == null:
		return null
	for child in parent.get_children():
		if child is Map and child.path != null:
			return child
	return null

func _exit_tree() -> void:
	# The ground holder lives in the map subtree, not under this node — free
	# it explicitly on every exit path.
	if is_instance_valid(_back_holder):
		_back_holder.queue_free()

func _process(delta: float) -> void:
	if _mats.is_empty():
		return
	_t += delta
	var plant_t: float = clampf(_t / PLANT_TIME, 0.0, 1.0)
	var pop: float = maxf(0.01, _ease_out_back(plant_t))
	var exp_v := 0.0
	if _exp_t >= 0.0:
		_exp_t += delta
		exp_v = clampf(_exp_t / _fade_time, 0.0, 1.0)
	for mat in _mats:
		mat.set_shader_parameter("loop_time", _t)
		mat.set_shader_parameter("plant", plant_t)
		mat.set_shader_parameter("scale_p", pop)
		mat.set_shader_parameter("expire", exp_v)
	if _exp_t >= 0.0 and _exp_t >= _fade_time:
		queue_free()

# Fired exactly once per field on every exit path. Natural expiry (all ticks
# fired) fades gracefully AND plays the refund beat; a wave-end cancel /
# external free fades fast and gates the refund beat OFF (no Energy refunded on
# that path, so the celebratory feather must not play).
func _on_field_finished(ticker: SkillActionChannel.ChannelTicker) -> void:
	if _exp_t >= 0.0:
		return
	var natural: bool = is_instance_valid(ticker) \
			and ticker.ticks_fired >= ticker.total_ticks
	_fade_time = FADE_NATURAL if natural else FADE_CANCEL
	if not natural:
		for mat in _mats:
			mat.set_shader_parameter("refund_beat", 0.0)
	_exp_t = 0.0

func _ease_out_back(t: float) -> float:
	var c1 := 1.70158
	var c3 := c1 + 1.0
	return 1.0 + c3 * pow(t - 1.0, 3.0) + c1 * pow(t - 1.0, 2.0)
