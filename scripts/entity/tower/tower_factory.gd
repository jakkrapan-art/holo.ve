extends Node
class_name TowerFactory

@export var towerTemplate: PackedScene;

var onPlace: Callable
var onRemove: Callable

func setup(onPlace: Callable, onRemove: Callable):
	self.onPlace = onPlace;
	self.onRemove = onRemove;

func GetTower(texture: Texture):
	if(towerTemplate == null):
		push_error("Get Tower Failed. template mission");
	
	var tower: Tower = towerTemplate.instantiate() as Tower
	tower.setup(texture, onPlace, onRemove);
	
	return tower
