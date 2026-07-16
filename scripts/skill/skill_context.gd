class_name SkillContext
extends RefCounted

var skillName: String = "";
var user: Node = null;
var target: Array[Node] = [];
var cancel: bool = false;
var extra: Dictionary = {}

func getParameter(name: String, parameter):
	var params: Dictionary = extra.get("parameter", {})
	if not params.has(name):
		# Loud miss: a typo'd *_param used to silently resolve to 1 (e.g. a
		# damage-reduction value_param would cap at 90% unnoticed). Behavior
		# (return 1) unchanged - existing YAML relying on the default keeps
		# working; the warning surfaces the breakage.
		push_warning("SkillContext: missing skill parameter '", name, "' (", skillName, ") - defaulting to 1")
		return 1
	var param = params.get(name)
	if param is Array:
		if param.is_empty():
			return 1
		var index: int = clampi(int(parameter), 0, param.size() - 1)
		return param[index]
	return param
