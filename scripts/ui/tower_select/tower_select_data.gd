extends RefCounted
class_name TowerSelectData

var name: String;
var icon: Texture2D;
var level: int;
var evolutionCost: int;

func _init(name: String, level: int, evolutionCost: int):
	self.name = name;
	self.level = level;
	self.evolutionCost = evolutionCost;
