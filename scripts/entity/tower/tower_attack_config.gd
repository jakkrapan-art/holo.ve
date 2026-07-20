class_name TowerAttackConfig
extends RefCounted

## Optional per-tower normal-attack config, parsed from the YAML `attack:` block.
## Absent block => the tower stays HITSCAN (back-compat); see TowerDataLoader.
##
## mode "projectile": the tower fires `burst` homing bullets at its target. Only
## ONE bullet carries damage (design A: the burst is visual; damage lands once),
## so balance is unchanged vs a single hitscan hit. `speed` is tiles/sec; `size` is
## the bullet height/diameter px (drives sprite scale AND collision radius).
##
## Visual model: the bullet's SHADER owns the default look. The `attack:` block may
## OVERRIDE shader uniforms (core_color/mid_color/edge_color/glow_softness); only keys
## present in YAML go into visual_overrides and get pushed (see _applyBulletVisual), so
## an omitted uniform keeps the shader's OWN default - never another tower's value.

const MODE_HITSCAN := "hitscan"
const MODE_PROJECTILE := "projectile"

# Colour uniforms the `attack:` block may override (parsed from "#rrggbb" or [r,g,b(,a)]).
const COLOR_KEYS = ["core_color", "mid_color", "edge_color"]

# Unauthored impact diameter = bullet size * this.
const IMPACT_SIZE_FACTOR := 1.8

var mode: String = MODE_HITSCAN
var projectile_scene: PackedScene = null
var vfx_shader: String = ""          # shader path, for ResourceManager warm (avoids first-fire hitch)
var speed: float = 9.0               # tiles/sec (converted to px at spawn via GridHelper.CELL_SIZE)
var size: float = 84.0               # bullet height/diameter px (drives sprite scale AND collision radius)
var burst: int = 3                   # rounds fired per attack (visual; damage still lands once)

# On-hit impact beat (opt-in). The bullet SHADER draws it from a `phase` uniform, so a
# tower opting in needs a shader with a phase-1 branch; towers that omit `impact` behave
# exactly as before. Defaults reproduce the approved Ina values without authoring them.
var has_impact: bool = false
var impact_size: float = -1.0        # px; < 0 => size * IMPACT_SIZE_FACTOR
var impact_time: float = 0.35        # seconds the impact beat runs

# Shader-uniform overrides explicitly set in YAML (uniform name -> value). ONLY these are
# pushed onto the bullet material; any uniform not here keeps the shader's own default.
var visual_overrides: Dictionary = {}

func is_projectile() -> bool:
	return mode == MODE_PROJECTILE

# Resolved impact diameter in px (falls back off the bullet size when unauthored).
func get_impact_size() -> float:
	if impact_size > 0.0:
		return impact_size
	return size * IMPACT_SIZE_FACTOR

static func from_dict(d: Dictionary) -> TowerAttackConfig:
	var cfg := TowerAttackConfig.new()
	cfg.mode = str(d.get("mode", MODE_HITSCAN))
	cfg.vfx_shader = str(d.get("vfx_shader", ""))
	cfg.speed = float(d.get("speed", cfg.speed))
	cfg.size = float(d.get("size", cfg.size))
	cfg.burst = max(1, int(d.get("burst", cfg.burst)))   # never 0 bullets

	# Impact beat: opt-in, and its two knobs stay unauthored unless a tower needs them.
	cfg.has_impact = bool(d.get("impact", false))
	cfg.impact_size = float(d.get("impact_size", cfg.impact_size))
	cfg.impact_time = max(0.01, float(d.get("impact_time", cfg.impact_time)))

	# Store ONLY the visual uniforms the YAML actually sets (presence = `d.has(key)`), so
	# the shader's own defaults stand for anything omitted - a bullet never inherits
	# another tower's colours. A present-but-malformed colour warns and is skipped.
	for key in COLOR_KEYS:
		if d.has(key):
			var parsed = _try_parse_color(d[key])
			if parsed is Color:
				cfg.visual_overrides[key] = parsed
			else:
				push_warning("TowerAttackConfig: malformed colour for '" + key + "' (" + str(d[key]) + "); keeping the shader default.")
	if d.has("glow_softness"):
		cfg.visual_overrides["glow_softness"] = float(d["glow_softness"])

	var scene_path := str(d.get("projectile", ""))
	if scene_path != "":
		var res = load(scene_path)
		if res is PackedScene:
			cfg.projectile_scene = res
		else:
			push_warning("TowerAttackConfig: projectile scene not found or invalid: " + scene_path)

	if cfg.is_projectile() and cfg.projectile_scene == null:
		push_warning("TowerAttackConfig: mode=projectile but no valid projectile scene; falling back to hitscan.")
		cfg.mode = MODE_HITSCAN

	return cfg

# Returns a Color from a "#rrggbb"/"#rrggbbaa" string or an [r,g,b(,a)] float array,
# or null when the value is not a usable colour (caller keeps the shader default).
static func _try_parse_color(value) -> Variant:
	if value is String and value != "":
		return Color(value)
	if value is Array and value.size() >= 3:
		var a: float = float(value[3]) if value.size() >= 4 else 1.0
		return Color(float(value[0]), float(value[1]), float(value[2]), a)
	return null
