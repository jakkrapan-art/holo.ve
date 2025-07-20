extends Node
class_name TowerFactory

const TowerClass = preload("res://scripts/entity/tower/tower_trait.gd").TowerClass
const TowerGeneration = preload("res://scripts/entity/tower/tower_trait.gd").TowerGeneration

@export var towerTemplate: PackedScene
var onPlace: Callable
var onRemove: Callable
var towerTrait: TowerTrait = TowerTrait.new()
var towers: Dictionary = {}
var activeSynergies: Dictionary = {}
var activeMissionBuff: Dictionary = {}

enum TowerId {
	Test
}

func setup(onPlace: Callable, onRemove: Callable):
	self.onPlace = onPlace
	self.onRemove = onRemove
	
	Utility.ConnectSignal(towerTrait, "synergy_activated", Callable(self, "onActivateSynergy"));
	Utility.ConnectSignal(towerTrait, "synergy_deactivated", Callable(self, "onDeactivateSynergy"));
	Utility.ConnectSignal(towerTrait, "mission_completed", Callable(self, "onMissionCompleted"));

func GetTower(name: String):
	if(towerTemplate == null):
		push_error("Get Tower Failed. template missing")
		return null
	
	var tower: Tower = towerTemplate.instantiate() as Tower
	tower.setup(id, onPlace, onRemove)
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

		addTowerToDict(tower, towerSyn)
	
	towerTrait.add_tower_traits([tower.data.towerClass, tower.data.generation])
	
	return tower

func ReturnTower(tower: Tower):
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

func addTowerToDict(tower: Tower, key: int):
	if key <= 0:  # Skip invalid keys
		return
		
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
				starGen1Damage += tower.data.getDamage(null);
				
		if isStarGen1:
			towerTrait.setStarGen1Damage(starGen1Damage);

func onDeactivateSynergy(synergy_id: int, tier: int):
	if not activeSynergies.has(synergy_id):
		return

	var buffList = activeSynergies[synergy_id]
	if tier >= 0 and tier < buffList.size():
		var buff = buffList[tier]
		# Remove this tier's buff
		buffList.remove_at(tier)

		# Optional: Clear and re-apply all current buffs for this synergy to all affected towers
		if towers.has(synergy_id):
			for tower in towers[synergy_id]:
				tower.clearSynergyBuffs(synergy_id)  # You will define this
				for remaining_buff in buffList:
					tower.processActiveBuff(remaining_buff)

	# If no more buffs, clean up
	if buffList.is_empty():
		activeSynergies.erase(synergy_id)

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
