class_name SkillContext
extends RefCounted

var user: Node = null;
var target: Array[Node] = [];
var cancel: bool = false;
var extra: Dictionary = {}

func getParameter(name: String, parameter):
	var param = extra.get("parameter", {}).get(name, []);
	var result: float = param[parameter] if param is Array else param;
	return result
