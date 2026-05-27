class_name SkillContext
extends RefCounted

var skillName: String = "";
var user: Node = null;
var target: Array[Node] = [];
var cancel: bool = false;
var extra: Dictionary = {}

func getParameter(name: String, parameter):
	var param = extra.get("parameter", {}).get(name, 1);
	if param is Array:
		if param.is_empty():
			return 1
		var index: int = clampi(int(parameter), 0, param.size() - 1)
		return param[index]
	return param
