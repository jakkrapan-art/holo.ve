extends Node
class_name TowerFactory

@export var towerTemplate: PackedScene;

var onPlace: Callable
var onRemove: Callable

enum TowerName 
{
	Test
}

func setup(onPlace: Callable, onRemove: Callable):
	self.onPlace = onPlace;
	self.onRemove = onRemove;

func GetTower(towerName: TowerName):
	if(towerTemplate == null):
		push_error("Get Tower Failed. template mission");
	
	var tower: Tower = towerTemplate.instantiate() as Tower
	tower.setup(towerName, onPlace, onRemove);
	
	return tower
