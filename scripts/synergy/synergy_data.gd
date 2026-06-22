class_name SynergyData

# One synergy definition loaded from resources/database/synergy/<id>.yaml.
# Values live in YAML (designer-tunable); behaviour lives in SynergyEffect.
# Numbers are read through get_parameter so the displayed text and the applied
# effect share one source (mirrors Skill.parameters / desc_template).

var id: String = ""                # file/data key, e.g. "myth"
var synergy_id: int = 0            # TowerTrait enum int (resolved at load)
var display_name: String = ""
var kind: String = ""             # "class" | "generation"
var type: String = "normal"       # UI category: normal | quest | special
var effect: String = ""           # SynergyEffect handler key ("" = placeholder)
var thresholds: Array = []        # proc count per tier (untyped: YamlParser yields untyped Array)
var parameters: Dictionary = {}   # name -> per-tier array (or scalar)
var desc_template: String = ""    # flavour line (hover header), may hold {param} tokens
var desc: String = ""             # plain fallback when desc_template is empty
# Per-tier effect lines for the hover table. size 1 -> the one template is used
# for every tier (pure scaling, e.g. Myth); size == tier_count -> one line per
# tier (qualitative tiers, e.g. a Tempus-style "unlock" at a higher tier).
var tier_effects: Array = []

func max_count() -> int:
	return int(thresholds[-1]) if not thresholds.is_empty() else 0

func min_requirement() -> int:
	return int(thresholds[0]) if not thresholds.is_empty() else 0

func tier_count() -> int:
	return thresholds.size()

func threshold_at(tier: int) -> int:
	if thresholds.is_empty():
		return 0
	return int(thresholds[clampi(tier, 0, thresholds.size() - 1)])

# Per-tier parameter value, clamped to the tier index. Clamp matches
# Skill._get_display_parameter exactly so display and effect never diverge
# (agent_lessons: a single-element array crashed when one path indexed raw).
func get_parameter(param_name: String, tier: int):
	if not parameters.has(param_name):
		push_warning("Synergy '" + id + "' missing parameter: " + param_name)
		return null
	var value = parameters.get(param_name)
	if value is Array:
		if value.is_empty():
			return null
		var index: int = clampi(tier, 0, value.size() - 1)
		return value[index]
	return value

# Flavour line resolved for a tier. highlight_color (BBCode hex) wraps values
# that come from a per-tier (array) parameter, so the player sees which number
# scales; "" returns plain text.
func flavor(tier: int, highlight_color: String = "") -> String:
	var template := desc_template if desc_template != "" else desc
	return _render(template, tier, highlight_color)

# One hover-table line for a tier (see tier_effects).
func tier_effect(tier: int, highlight_color: String = "") -> String:
	if tier_effects.is_empty():
		return ""
	var template: String
	if tier_effects.size() == 1:
		template = str(tier_effects[0])
	else:
		template = str(tier_effects[clampi(tier, 0, tier_effects.size() - 1)])
	return _render(template, tier, highlight_color)

func _render(template: String, tier: int, highlight_color: String) -> String:
	if template == "":
		return ""
	var result := template
	var regex := RegEx.new()
	regex.compile("\\{([^}:]+)(?::([^}]+))?\\}")
	var matches := regex.search_all(template)
	for i in range(matches.size() - 1, -1, -1):
		var m := matches[i]
		var pname := m.get_string(1)
		var fmt := m.get_string(2)
		var is_scaling: bool = parameters.has(pname) and parameters[pname] is Array
		var text := _format_value(get_parameter(pname, tier), fmt)
		if highlight_color != "" and is_scaling:
			text = "[color=" + highlight_color + "]" + text + "[/color]"
		result = result.substr(0, m.get_start()) + text + result.substr(m.get_end())
	return result

func _format_value(value, fmt: String) -> String:
	if value == null:
		return ""

	match fmt:
		"percent":
			return _format_number(float(value) * 100.0) + "%"
		"":
			return _format_number(value)
		_:
			push_warning("Unknown synergy desc placeholder format: " + fmt)
			return _format_number(value)

func _format_number(value) -> String:
	if value is int:
		return str(value)
	if value is float:
		if is_equal_approx(value, round(value)):
			return str(int(round(value)))
		var text := "%.4f" % value
		while text.ends_with("0"):
			text = text.substr(0, text.length() - 1)
		if text.ends_with("."):
			text = text.substr(0, text.length() - 1)
		return text
	return str(value)
