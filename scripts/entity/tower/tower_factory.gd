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
var _wave_active := false            # gates time-based synergy ticks to active waves

enum TowerId {
	Test
}

func setup(p_onPlace: Callable, p_onRemove: Callable):
	self.onPlace = p_onPlace
	self.onRemove = p_onRemove

	synergyController = SynergyController.new()
	synergyController.setup(self)
	Utility.ConnectSignal(towerTrait, "synergy_updated", Callable(self, "_on_synergy_updated"));
	if uiSynergy != null:
		Utility.ConnectSignal(synergyController, "mission_progress_changed", Callable(uiSynergy, "setMissionProgress"));

func getTower(p_name: String, evoToken: int = 0) -> GetTowerResult:
	var resource = ResourceManager.getTower(p_name);

	if(resource == null && towerTemplate != null):
		resource = towerTemplate

	if (resource == null):
		return null

	var result: GetTowerResult = GetTowerResult.new()

	if (towersByName.has(p_name)):
		var t = towersByName.get(p_name, null);
		if (t != null):
			if(t.data.level >= t.data.maxLevel && !t.isEvolved() && t.data.evolutionCost >= evoToken):
				result.state = GetTowerResult.State.Evolve;
				result.tower = t;
				return result;

			t.upgrade();
			result.tower = t;
			result.state = GetTowerResult.State.Upgrade;

			if(t.canEvolve() && not t.isEvolved()):
				_evolutionList[p_name] = t.data;

			return result;

	var tower: Tower = resource.instantiate() as Tower
	if(tower.data == null):
		var tData = TowerCenter.getTowerDataByName("default");
		if(tData == null):
			return null
		tower.data = tData

	result.state = GetTowerResult.State.New
	result.tower = tower;
	tower.setup(p_name, onPlace, onRemove)
	Utility.ConnectSignal(tower, "skill_cast_succeeded", Callable(synergyController, "on_tower_cast"));
	# Register traits in the keyed list BEFORE add_tower_traits so a synergy that
	# activates on this placement already counts the new tower.
	for towerSyn in [tower.data.towerClass, tower.data.generation]:
		addTowerToDict(p_name, tower, towerSyn)
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

func addTowerToDict(p_name: String, tower: Tower, key: int):
	if key <= 0:  # Skip invalid keys
		return

	if not towersByName.has(p_name):
		towersByName[p_name] = tower

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

func evolutionTower(p_name: String):
	var towerData = TowerCenter.getTowerDataByName(p_name);
	if towerData == null:
		push_error("Tower data not found for evolution: ", p_name)
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
	# Draw/refresh the panel row BEFORE the controller updates the effect, so a
	# mission effect's activate() (which emits mission_progress_changed) lands on a
	# row that already exists. Only show synergies defined in YAML; an undefined
	# trait (no data) can never activate, so it is not a meaningful panel row.
	if uiSynergy != null:
		var data: SynergyData = ResourceManager.getSynergyData(synergy_id)
		if data != null:
			uiSynergy.updateSynergy(data.display_name, count, tier, synergy_id)
	synergyController.on_synergy_updated(synergy_id, count, tier)

func onWaveStart():
	_wave_active = true

func onWaveEnd():
	_wave_active = false
	for tower: Tower in towersByName.values():
		if is_instance_valid(tower):
			tower.resetForWave()

func _process(delta: float) -> void:
	# Time-based synergy effects (e.g. Tempus energy pulse) run only during an
	# active wave - not between waves / during the tower-select popup (which does
	# not pause the tree), so energy does not keep pulsing while the player picks.
	if _wave_active and synergyController != null:
		synergyController.tick(delta)

# Wired to WaveController.onEnemyDead (real kills only) -> mission synergies.
func onEnemyKilled(enemy, cause, reward) -> void:
	if synergyController != null:
		synergyController.on_enemy_killed(enemy, cause, reward)
