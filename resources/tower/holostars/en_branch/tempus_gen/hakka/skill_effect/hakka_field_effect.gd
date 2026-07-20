extends Node2D
# ================================================================
# Banzoin Hakka · "Exocirst Field" (normal) VFX controller — the first
# FIELD-family effect (persistent ground zone).
#
# Spawned ONCE at field plant by SkillActionField (bare Node2D at
# tower.global_position, parent = tower.get_parent()), NOT per tick:
# a persistent zone must not respawn on the damage cadence (Director:
# continuous territory, no interval flicker). Lifecycle:
#
#   plant    0->1 over PLANT_TIME (pop-in, back-eased scale_p)
#   sustain  loop_time accumulates until the ticker ends. Driven by
#            _process delta, NEVER shader TIME: _process freezes on
#            pause and scales with x2 (Engine.time_scale), so the zone
#            obeys game time for free (same rationale as ChannelTicker).
#   expire   0->1 fade when the ticker's `finished` fires — graceful
#            (0.6s) on natural expiry, fast (0.25s) on wave-end cancel.
#            The ticker emits `finished` exactly once on EVERY exit
#            path (channel's `done` once-guard), so no leak path.
#
# LAYER model (Director, digital-paint thinking): the zone is drawn
# TWICE with the same shader — `fx_layer` 0 = the whole zone (ground
# layer), 1 = front-assigned fireflies only (z_index 0, spawned after
# towers -> draws above). No positional half-split: a seam line across
# the tower reads wrong.
#
# GROUND layer placement (Director 2026-07-18, in-engine verdict): a
# persistent field zone must render UNDER enemies, not just under the
# tower. Enemies live under the Map's Path2D inside the z=-1 TileMap
# subtree, so the back rect is inserted into that subtree BEFORE the
# Path2D (a TileMap draws its own cells before its children): ground
# cells -> zone -> enemies -> towers -> front fireflies. Fallback when
# no Map sibling is found: child of self at z -1 (under towers only,
# the pre-verdict behavior).
#
# SHADER_PATH is read by ResourceManager.warmSkillEffectShaders to
# pre-compile the pipeline at deck load, so the first cast won't hitch.
# ================================================================

const SHADER_PATH := "res://resources/tower/holostars/en_branch/tempus_gen/hakka/skill_effect/hakka_field_effect.gdshader"
const PAD := 1.35            # visual pad beyond the footprint (free: damage is code-side)
const PLANT_TIME := 0.5
const FADE_NATURAL := 0.6
const FADE_CANCEL := 0.25

var _mats: Array[ShaderMaterial] = []
var _back_holder: Node2D = null   # ground-layer host inside the map subtree
var _t := 0.0
var _fade_time := FADE_NATURAL
var _exp_t := -1.0           # >= 0 once expiring

# Called by SkillActionField right after spawn. Footprint (cells) comes from
# the action so the same controller serves any field size. Named setup_field
# (not setup) so SkillActionPlayEffect's 2-arg setup(tower, context) hook can
# never match this 3-arg signature by accident.
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
		push_warning("hakka_field_effect: spawned without setup_field() - freeing (use the field action's effect_script, not play_effect).")
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
			add_child(rect)     # front fireflies, above towers/enemies
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
# fired) fades gracefully; a wave-end cancel / external free fades fast so no
# zone lingers into the tower-select popup.
func _on_field_finished(ticker: SkillActionChannel.ChannelTicker) -> void:
	if _exp_t >= 0.0:
		return
	var natural: bool = is_instance_valid(ticker) \
			and ticker.ticks_fired >= ticker.total_ticks
	_fade_time = FADE_NATURAL if natural else FADE_CANCEL
	_exp_t = 0.0

func _ease_out_back(t: float) -> float:
	var c1 := 1.70158
	var c3 := c1 + 1.0
	return 1.0 + c3 * pow(t - 1.0, 3.0) + c1 * pow(t - 1.0, 2.0)
