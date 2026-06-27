extends Resource
class_name Skill

enum TARGET_TYPE {ENEMY, FRIENDLY}

@export var name:String = "Skill"
@export var desc:String = "Just a skill"
@export var names: Array[String] = []
@export var desc_template: String = ""
@export var oneTimeUse: bool = false
@export var castTime: float = 0.0
@export var actions: Array[SkillAction] = []
@export var parameters: Dictionary = {}
@export var tags: Array[String] = []
@export var target_summary: Dictionary = {}
@export var icon: String = ""
@export var effects: Array = []

var using = false;
var disable = false;

func _init(p_name:String="Skill", p_desc:String="Just a skill", p_actions:Array[SkillAction]=[], p_parameters:Dictionary={}, p_oneTimeUse: bool = false, p_castTime: float = 0.0):
	self.name = p_name;
	self.desc = p_desc;
	self.actions = p_actions;
	self.parameters = p_parameters;
	self.oneTimeUse = p_oneTimeUse;
	self.castTime = p_castTime;

func get_display_name(level: int) -> String:
	if names.size() > 0:
		var index: int = clampi(level - 1, 0, names.size() - 1)
		return names[index]
	return name

func get_display_desc(level: int) -> String:
	if desc_template == "":
		return desc

	var result := desc_template
	var regex := RegEx.new()
	regex.compile("\\{([^}:]+)(?::([^}]+))?\\}")
	var matches := regex.search_all(desc_template)
	for i in range(matches.size() - 1, -1, -1):
		var match_result := matches[i]
		var param_name := match_result.get_string(1)
		var format := match_result.get_string(2)
		var value = _get_display_parameter(param_name, level)
		result = result.substr(0, match_result.get_start()) + _format_display_parameter(value, format) + result.substr(match_result.get_end())
	return result

func _get_display_parameter(param_name: String, level: int):
	if not parameters.has(param_name):
		push_warning("Missing skill display parameter: " + param_name)
		return null

	var value = parameters.get(param_name, "")
	if value is Array:
		if value.is_empty():
			return ""
		var index: int = clampi(level - 1, 0, value.size() - 1)
		return value[index]
	return value

func _format_display_parameter(value, format: String) -> String:
	if value == null:
		return ""

	match format:
		"percent":
			return _format_display_number(float(value) * 100.0) + "%"
		"":
			return _format_display_number(value)
		_:
			push_warning("Unknown skill display placeholder format: " + format)
			return _format_display_number(value)

func _format_display_number(value) -> String:
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

func use():
	if oneTimeUse:
		disable = true;

func isReady():
	return !using && !disable;
