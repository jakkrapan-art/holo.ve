class_name TowerAttackConfig
extends RefCounted

## Optional per-tower normal-attack config, parsed from the YAML `attack:` block.
## Absent block => the tower stays HITSCAN (back-compat); see TowerDataLoader.
##
## mode "projectile": the tower fires `burst` homing bullets at its target. Only
## ONE bullet carries damage (design A: the burst is visual; damage lands once),
## so balance is unchanged vs a single hitscan hit. Visual tunables (size, colours,
## glow_softness) drive the bullet's ShaderMaterial; speed is tiles/sec.

const MODE_HITSCAN := "hitscan"
const MODE_PROJECTILE := "projectile"

var mode: String = MODE_HITSCAN
var projectile_scene: PackedScene = null
var vfx_shader: String = ""          # shader path, for ResourceManager warm (avoids first-fire hitch)
var speed: float = 9.0               # tiles/sec (converted to px at spawn via GridHelper.CELL_SIZE)
var size: float = 84.0               # bullet diameter px (drives sprite scale AND collision radius)
var burst: int = 3                   # rounds fired per attack (visual; damage still lands once)
var glow_softness: float = 0.3       # Soft Glow halo width

# Warm-gold defaults mirror amelia_bullet.gdshader's uniform defaults.
var core_color: Color = Color(1.0, 0.98, 0.86)
var mid_color: Color = Color(1.0, 0.84, 0.45)
var edge_color: Color = Color(0.86, 0.52, 0.18)

func is_projectile() -> bool:
	return mode == MODE_PROJECTILE

static func from_dict(d: Dictionary) -> TowerAttackConfig:
	var cfg := TowerAttackConfig.new()
	cfg.mode = str(d.get("mode", MODE_HITSCAN))
	cfg.vfx_shader = str(d.get("vfx_shader", ""))
	cfg.speed = float(d.get("speed", cfg.speed))
	cfg.size = float(d.get("size", cfg.size))
	cfg.burst = max(1, int(d.get("burst", cfg.burst)))   # never 0 bullets
	cfg.glow_softness = float(d.get("glow_softness", cfg.glow_softness))
	cfg.core_color = _parse_color(d.get("core_color", null), cfg.core_color)
	cfg.mid_color = _parse_color(d.get("mid_color", null), cfg.mid_color)
	cfg.edge_color = _parse_color(d.get("edge_color", null), cfg.edge_color)

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

# Accepts a "#rrggbb"/"#rrggbbaa" hex string OR an [r,g,b(,a)] float array; else default.
static func _parse_color(value, default_color: Color) -> Color:
	if value is String and value != "":
		return Color(value)
	if value is Array and value.size() >= 3:
		var a: float = float(value[3]) if value.size() >= 4 else 1.0
		return Color(float(value[0]), float(value[1]), float(value[2]), a)
	return default_color
