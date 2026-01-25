extends Node
class_name TowerFactory

const TowerClass = preload("res://scripts/entity/tower/tower_trait.gd").TowerClass
const TowerGeneration = preload("res://scripts/entity/tower/tower_trait.gd").TowerGeneration

@onready var uiSynergy: UISynergy = $"../GameUI/UISynergy"

@export var towerTemplate: PackedScene

var onPlace: Callable
var onRemove: Callable
var towerTrait: TowerTrait = TowerTrait.new()
var towersByName: Dictionary = {}
var towers: Dictionary = {}
var _evolutionList: Dictionary = {}
var _evolvedList: Array[String] = []
var activeSynergies: Dictionary = {}
var activeMissionBuff: Dictionary = {}

# getter
func getEvolutionList(evoToken: int):
	if (_evolutionList.size() == 0):
		return {"canEvolve": [], "exclude": []}

	var cannotEvolveList: Array = []
	var canEvolveList: Array = []

	for key in _evolutionList:
		var data: TowerData = _evolutionList[key]
		if data == null:
			continue
		# Only include towers that are not yet evolved and whose cost is affordable
		if not data.isEvolved:
			if data.evolutionCost > evoToken:
				cannotEvolveList.append(key)
				continue

			var tName: String = key
			var level: int = data.level
			var evolutionCost: int = data.evolutionCost
			canEvolveList.append(TowerSelectData.new(tName, level, evolutionCost))
	return {"canEvolve": canEvolveList, "exclude": cannotEvolveList}

enum TowerId {
	Test
}

func setup(onPlace: Callable, onRemove: Callable):
	self.onPlace = onPlace
	self.onRemove = onRemove

	Utility.ConnectSignal(towerTrait, "synergy_activated", Callable(self, "onActivateSynergy"));
	Utility.ConnectSignal(towerTrait, "synergy_deactivated", Callable(self, "onDeactivateSynergy"));
	Utility.ConnectSignal(towerTrait, "mission_completed", Callable(self, "onMissionCompleted"));

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
	result.state = GetTowerResult.State.New
	result.tower = tower;
	tower.setup(name, onPlace, onRemove)
	Utility.ConnectSignal(tower, "onReceiveMission", Callable(self, "towerReceiveMission"));
	for towerSyn in [tower.data.towerClass, tower.data.generation]:
		if towerSyn == 0:  # Skip default/unset values
			continue

		# Apply active towerSynergy buffs to new tower
		var activeSyn = activeSynergies.get(towerSyn, [])
		for buff: Dictionary in activeSyn:
			var mission: MissionDetail = buff.get("mission", null);
			if(mission == null):
				var tier = buff.get("tier", "")
				tower.processActiveBuff(buff, str(tier))

			var checkAndProcessActiveMissionSyn = func(synergyId, tier, missionBuff):
				if synergyId == tower.data.generation || synergyId == tower.data.towerClass:
					tower.processActiveBuff(missionBuff, str(tier));

			for missionBuff in activeMissionBuff.values():
				var tier = missionBuff.get("tier", "")
				var synergyId = missionBuff.get("synergy_id", -1);
				if not synergyId is Array:
					checkAndProcessActiveMissionSyn.call(synergyId, tier, missionBuff);
				else:
					var synergyArray: Array = synergyId as Array;
					for syn in synergyArray:
						checkAndProcessActiveMissionSyn.call(syn, tier, missionBuff);

		addTowerToDict(name, tower, towerSyn)

		if uiSynergy != null:
			var synName = towerTrait.getSynergyName(towerSyn);
			if (synName == "Unknown"):
				printerr("found unknown synergy:", towerSyn);
				return;
			# print("setup syn:", synName);
			if not uiSynergy.hasContent(synName):
				var maxSyn = towerTrait.getSynergyMaxCount(towerSyn);
				var minReq = towerTrait.getMinRequirement(towerSyn);
				uiSynergy.addNewSynergy(synName, minReq, maxSyn);

			uiSynergy.addSynergy(synName);

	towerTrait.add_tower_traits([tower.data.towerClass, tower.data.generation])
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
	var tower = towersByName.get(name, null);
	if tower == null:
		return

	var success = tower.evolve();
	if success:
		_evolutionList.erase(name);
		_evolvedList.append(name);

func onActivateSynergy(synergy_id: int, tier: int, buff: Dictionary):
	if not activeSynergies.has(synergy_id):
		activeSynergies[synergy_id] = []

	activeSynergies[synergy_id].append(buff)

	# Apply buff to all towers with this synergy
	if towers.has(synergy_id):
		var starGen1Damage = 0;
		var isStarGen1 = false;

		for tower: Tower in towers[synergy_id]:
			tower.processActiveBuff(buff, str(tier));

			if synergy_id == TowerGeneration.Gen1:
				isStarGen1 = true;
				starGen1Damage += tower.data.getDamage(null, tower).damage;

		if isStarGen1:
			towerTrait.setStarGen1Damage(starGen1Damage);

# Dont have to deactive synergy
# func onDeactivateSynergy(synergy_id: int, tier: int):
# 	if not activeSynergies.has(synergy_id):
# 		return

# 	var buffList = activeSynergies[synergy_id]
# 	if tier >= 0 and tier < buffList.size():
# 		var buff = buffList[tier]
# 		# Remove this tier's buff
# 		buffList.remove_at(tier)

# 		# Optional: Clear and re-apply all current buffs for this synergy to all affected towers
# 		if towers.has(synergy_id):
# 			for tower in towers[synergy_id]:
# 				tower.clearSynergyBuffs(synergy_id)  # You will define this
# 				for remaining_buff in buffList:
# 					tower.processActiveBuff(remaining_buff)

# 	# If no more buffs, clean up
# 	if buffList.is_empty():
# 		activeSynergies.erase(synergy_id)

func onMissionCompleted(id: int, buff: Dictionary):
	var synergyId = buff.get("synergy_id", -1);
	if not synergyId is Array && synergyId == -1:
		return;
	var tier = buff.get("tier", 0);
	var process = func(syn) -> Array:
		var towersArr: Array = towers.get(syn, []);
		for tower: Tower in towersArr:
			tower.processActiveBuff(buff, str(synergyId) + str(tier));
		return towersArr;

	if synergyId is Array:
		var synergyArray = synergyId as Array;
		print("processing buff to:", synergyArray);
		for syn in synergyArray:
			process.call(syn);
	else:
		process.call(synergyId);

	activeMissionBuff[id] = buff;
	#print("on mission complete id:", id, "synergy: ", synergyId, " buff:", buff);

func onWaveStart():
	processGen0Buff()

func processGen0Buff():
	if (!activeSynergies.has(TowerGeneration.Gen0)):
		return;

	var buffs:Dictionary = activeSynergies.get(TowerGeneration.Gen0);
	var buffDmgPercent:int = buffs.get("syn_atk_percent", 0);

	var towerList: Array = towers.get(TowerGeneration.Gen0);
	for t: Tower in towerList:
		var buff: Dictionary = {"synergy_id": TowerGeneration.Gen0, "attack_bonus": (buffDmgPercent * towerList.size())};
		t.processActiveBuff(buff)

func towerReceiveMission(mission: MissionDetail):
	onReceiveMission.emit(mission);

signal onReceiveMission(mission: MissionDetail);
