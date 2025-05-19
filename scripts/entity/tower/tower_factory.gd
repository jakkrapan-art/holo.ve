extends Node
class_name TowerFactory

@export var towerTemplate: PackedScene;

var onPlace: Callable
var onRemove: Callable
var towerTrait: TowerTrait = TowerTrait.new();

var towers: Dictionary = {};
var activeSynergies: Dictionary = {};

enum TowerId
{
	Test
}

func setup(onPlace: Callable, onRemove: Callable):
	self.onPlace = onPlace;
	self.onRemove = onRemove;
	
	Utility.ConnectSignal(towerTrait, "synergy_activated", Callable(self, "onActivateSynergy"));
	Utility.ConnectSignal(towerTrait, "synergy_deactivated", Callable(self, "onDeactivateSynergy"));

func GetTower(id: TowerId):
	if(towerTemplate == null):
		push_error("Get Tower Failed. template missing");
	
	var tower: Tower = towerTemplate.instantiate() as Tower
	tower.setup(id, onPlace, onRemove);
	
	for syn in [tower.data.towerClass, tower.data.generation]:
		var activeSyn = activeSynergies.get(syn)
		if activeSyn:
			for buff in activeSyn:
				tower.processActiveBuff(buff)
				print("syn:", syn, ", active ", buff);
		
		addTowerToDict(tower, syn);

	towerTrait.add_tower_traits([tower.data.towerClass, tower.data.generation])
	
	return tower

func ReturnTower(tower: Tower):
	if(tower == null):
		return;

	towerTrait.remove_tower_traits([tower.data.towerClass, tower.data.generation])
	removeTowerFromDict(tower, tower.data.towerClass);
	removeTowerFromDict(tower, tower.data.generation);
	tower.queue_free();

func addTowerToDict(tower: Tower, key: int):
	var list: Array = towers.get(key, []);
	if(list.find(tower) >= 0):
		return;

	list.append(tower);
	towers[key] = list;

func removeTowerFromDict(tower: Tower, key: int):
	var list = towers.get(key, []);
	var index = list.find(tower);
	if(index < 0):
		return;

	list.remove_at(index);
	towers[key] = list;

func onActivateSynergy(id, tier, buff):
	var towerList = towers.get(id);
	if(!towerList):
		return;
		
	for t in towerList:
		var tower = t as Tower
		tower.processActiveBuff(buff);
		print("activate synergy:", tower.id, "tier:", tier, "buff:", buff)
	
	var actives = activeSynergies.get(id, [])
	actives.append(buff)
	activeSynergies[id] = actives;

func onDeactivateSynergy(id, tier, buff):
	print("deactivate synergy:", id, "tier:", tier, "buff:", buff)
	var actives = activeSynergies.get(id, [])
	var index = actives.find(buff)
	if(index > -1):
		actives.remove_at(index);
	
	activeSynergies[id] = actives;	
