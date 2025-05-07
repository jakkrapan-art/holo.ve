extends Node
class_name TowerFactory

@export var towerTemplate: PackedScene;

var onPlace: Callable
var onRemove: Callable
var towerTrait: TowerTrait = TowerTrait.new();

enum TowerName 
{
	Test
}

func setup(onPlace: Callable, onRemove: Callable):
	self.onPlace = onPlace;
	self.onRemove = onRemove;

func GetTower(towerName: TowerName):
	if(towerTemplate == null):
		push_error("Get Tower Failed. template missing");
	
	var tower: Tower = towerTemplate.instantiate() as Tower
	tower.setup(towerName, onPlace, onRemove);
	towerTrait.add_tower_traits([tower.data.towerClass, tower.data.generation])
	return tower

func ReturnTower(tower: Tower):
	if(tower == null):
		return;

	towerTrait.remove_tower_traits([tower.data.towerClass, tower.data.generation])
	tower.queue_free();
