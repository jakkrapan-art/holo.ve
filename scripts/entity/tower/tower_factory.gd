extends Node
class_name TowerFactory

@onready var uiSynergy: UISynergy = $"../GameUI/UISynergy"

@export var towerTemplate: PackedScene

var onPlace: Callable
var onRemove: Callable
var towerTrait: TowerTrait = TowerTrait.new()
var towersByName: Dictionary = {}
var towers: Dictionary = {}
var _evolutionList: Dictionary = {}
var synergyController: SynergyController

enum TowerId {
	Test
}

func setup(onPlace: Callable, onRemove: Callable):
	self.onPlace = onPlace
	self.onRemove = onRemove

	synergyController = SynergyController.new()
	synergyController.setup(self)
	Utility.ConnectSignal(towerTrait, "synergy_updated", Callable(self, "_on_synergy_updated"));

func getTower(name: String, evoToken: int = 0) -> GetTowerResult:
	var resource = ResourceManager.getTower(name);

	if(resource == null && towerTemplate != null):
		resource = towerTemplate

	if (resource == null):
		return null

	var result: GetTowerResult = GetTowerResult.new()

	if (towersByName.has(name)):
		var t = towersByName.get(name, null);
		if (t != null):
			if(t.data.level >= t.data.maxLevel && !t.isEvolved() && t.data.evolutionCost >= evoToken):
				result.state = GetTowerResult.State.Evolve;
				result.tower = t;
				return result;

			t.upgrade();
			result.tower = t;
			result.state = GetTowerResult.State.Upgrade;

			if(t.canEvolve() && not t.isEvolved()):
				_evolutionList[name] = t.data;

			return result;

	var tower: Tower = resource.instantiate() as Tower
	if(tower.data == null):
		var tData = TowerCenter.getTowerDataByName("default");
		if(tData == null):
			return null
		tower.data = tData

	result.state = GetTowerResult.State.New
	result.tower = tower;
	tower.setup(name, onPlace, onRemove)
	Utility.ConnectSignal(tower, "onReceiveMission", Callable(self, "towerReceiveMission"));
	Utility.ConnectSignal(tower, "skill_cast_succeeded", Callable(synergyController, "on_tower_cast"));
	# Register traits in the keyed list BEFORE add_tower_traits so a synergy that
	# activates on this placement already counts the new tower.
	for towerSyn in [tower.data.towerClass, tower.data.generation]:
		addTowerToDict(name, tower, towerSyn)
	towerTrait.add_tower_traits([tower.data.towerClass, tower.data.generation])
	synergyController.on_tower_added(tower)
	return result

func returnTower(tower: Tower):
	if(tower == null):
		return

	var traits = []
	if tower.data.towerClass > 0:
		traits.append(tower.data.towerClass)
		removeTowerFromDict(tower, tower.data.towerClass)

	if tower.data.generation > 0:
		traits.append(tower.data.generation)
		removeTowerFromDict(tower, tower.data.generation)

	towerTrait.remove_tower_traits(traits)
	tower.queue_free()

func addTowerToDict(name: String, tower: Tower, key: int):
	if key <= 0:  # Skip invalid keys
		return

	if not towersByName.has(name):
		towersByName[name] = tower

	var list: Array = towers.get(key, [])
	if(list.find(tower) >= 0):
		return

	list.append(tower)
	towers[key] = list

func removeTowerFromDict(tower: Tower, key: int):
	if key <= 0:  # Skip invalid keys
		return

	var list = towers.get(key, [])
	var index = list.find(tower)
	if(index < 0):
		return

	list.remove_at(index)
	towers[key] = list

func evolutionTower(name: String):
	var towerData = TowerCenter.getTowerDataByName(name);
	if towerData == null:
		print("Error: Tower data not found for evolution:", name)
		return;

	var dataName = towerData.data_name;
	var tower = towersByName.get(dataName, null);
	if tower == null:
		return

	var success = tower.evolve();
	if success:
		_evolutionList.erase(dataName);
		TowerCenter._evolvedList.append(dataName);

func _on_synergy_updated(synergy_id: int, count: int, tier: int):
	synergyController.on_synergy_updated(synergy_id, count, tier)
	if uiSynergy == null:
		return
	# Only show synergies that are actually defined in YAML; an undefined trait
	# (no data) can never activate, so it is not a meaningful panel row.
	var data: SynergyData = ResourceManager.getSynergyData(synergy_id)
	if data == null:
		return
	uiSynergy.updateSynergy(data.display_name, count, tier, synergy_id)

func onWaveStart():
	pass   # reserved for future per-wave synergy hooks

func onWaveEnd():
	for tower: Tower in towersByName.values():
		if is_instance_valid(tower):
			tower.resetForWave()

func towerReceiveMission(mission: MissionDetail):
	onReceiveMission.emit(mission);

signal onReceiveMission(mission: MissionDetail);
