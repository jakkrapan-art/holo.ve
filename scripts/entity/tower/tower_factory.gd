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

enum TowerId {
	Test
}

func setup(onPlace: Callable, onRemove: Callable):
	self.onPlace = onPlace
	self.onRemove = onRemove
	
	Utility.ConnectSignal(towerTrait, "synergy_activated", Callable(self, "onActivateSynergy"))
	Utility.ConnectSignal(towerTrait, "synergy_deactivated", Callable(self, "onDeactivateSynergy"))

func GetTower(id: TowerId):
	if(towerTemplate == null):
		push_error("Get Tower Failed. template missing")
		return null
	
	var tower: Tower = towerTemplate.instantiate() as Tower
	tower.setup(id, onPlace, onRemove)
	
	for syn in [tower.data.towerClass, tower.data.generation]:
		if syn == 0:  # Skip default/unset values
			continue
			
		# Apply active synergy buffs to new tower
		var activeSyn = activeSynergies.get(syn, [])
		for buff in activeSyn:
			tower.processActiveBuff(buff)

		addTowerToDict(tower, syn)
	
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
			tower.processActiveBuff(buff)
			
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
