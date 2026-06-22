class_name EnemyModifier

# Stage / Wave enemy stat modifiers.
#
# A modifier is a validated dict { stat, op, value } (NOT a Resource - boss stats
# are already plain dicts, same precedent). Modifiers are applied as spawn-time
# math on the enemy's BASE stats BEFORE the enemy is built (maxHp/currentHp are
# raw ints read directly + the healthbar is seeded in Enemy.setup, so this is not
# a removable keyed buff).
#
# Stacking (Director, 2026-06-21): ADDITIVE - sum the values per (stat, op), then
# apply to base once. stage hp x2 + wave hp x1.5 -> base x3.5 (not multiplicative).

const STATS := ["hp", "def", "mDef", "moveSpeed", "damageReduction"]
const OPS := ["mult", "flat", "percent", "add"]

# Parse + validate a raw YAML list into modifier dicts. Unknown stat/op names
# fail loud (push_error) instead of silently misbehaving (review R7).
static func parse(raw) -> Array:
	var out: Array = []
	if raw == null:
		return out
	if not (raw is Array):
		push_error("EnemyModifier: modifier list is not an array")
		return out
	for m in raw:
		if not (m is Dictionary):
			push_error("EnemyModifier: modifier entry is not a map")
			continue
		var stat := str(m.get("stat", ""))
		var op := str(m.get("op", ""))
		if not STATS.has(stat):
			push_error("EnemyModifier: unknown stat '" + stat + "' (expected one of " + str(STATS) + ")")
			continue
		if not OPS.has(op):
			push_error("EnemyModifier: unknown op '" + op + "' for stat '" + stat + "' (expected one of " + str(OPS) + ")")
			continue
		out.append({ "stat": stat, "op": op, "value": float(m.get("value", 0)) })
	return out

# Resolve final stats from a base stats dict { hp, def, mDef, moveSpeed } and any
# number of modifier lists (e.g. [stageModifiers, waveModifiers]). damageReduction
# base is 0 (enemies have none by default). Returns floats; caller casts as needed.
static func resolve(base: Dictionary, modifier_lists: Array) -> Dictionary:
	var sums: Dictionary = {}  # "stat|op" -> summed value
	for list in modifier_lists:
		if list == null:
			continue
		for m in list:
			var key = str(m.stat) + "|" + str(m.op)
			sums[key] = sums.get(key, 0.0) + float(m.value)

	var out: Dictionary = {
		"hp": float(base.get("hp", 0)),
		"def": float(base.get("def", 0)),
		"mDef": float(base.get("mDef", 0)),
		"moveSpeed": float(base.get("moveSpeed", 0)),
		"damageReduction": 0.0,
	}
	for stat in out.keys():
		out[stat] = _apply(out[stat], stat, sums)
	return out

# Application order per stat: mult -> percent -> flat -> add. A stat normally uses
# one op; the fixed order just keeps mixed-op cases deterministic.
static func _apply(base_val: float, stat: String, sums: Dictionary) -> float:
	var v := base_val
	if sums.has(stat + "|mult"):
		v = v * sums[stat + "|mult"]
	if sums.has(stat + "|percent"):
		v = v * (1.0 + sums[stat + "|percent"] / 100.0)
	if sums.has(stat + "|flat"):
		v = v + sums[stat + "|flat"]
	if sums.has(stat + "|add"):
		v = v + sums[stat + "|add"]
	return v
