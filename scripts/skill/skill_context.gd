class_name SkillContext
extends RefCounted

var skillName: String = "";
var user: Node = null;
var target: Array[Node] = [];
var cancel: bool = false;
var extra: Dictionary = {}

func getParameter(name: String, parameter):
	var param = extra.get("parameter", {}).get(name, 0);
	var result: float = param[parameter] if param is Array else param;
	return result
