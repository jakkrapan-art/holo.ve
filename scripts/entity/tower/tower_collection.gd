class_name TowerCollection

const TowerClass = preload("res://scripts/entity/tower/tower_trait.gd").TowerClass
const TowerGeneration = preload("res://scripts/entity/tower/tower_trait.gd").TowerGeneration

var classCollect: Array[TowerClass];
var generationCollect: Array[TowerGeneration];

func _init():
	pass;
	
