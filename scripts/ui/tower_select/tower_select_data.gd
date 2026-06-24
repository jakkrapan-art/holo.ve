extends RefCounted
class_name TowerSelectData

var name: String;
var icon: Texture2D;
var level: int;
var evolutionCost: int;

func _init(p_name: String, p_level: int, p_evolutionCost: int):
	self.name = p_name;
	self.level = p_level;
	self.evolutionCost = p_evolutionCost;
