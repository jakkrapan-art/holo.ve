class_name TowerTrait

# Enums with offset to avoid collision
enum TowerClass { Assassin = 100, Diva, Hero, King, Marksman, Robotic, SpellCaster, Warrior }
enum TowerGeneration { Myth = 200, Tempus, Gen0, Gen1, Indo1 }

# Display Names
const TOWER_CLASS_NAMES := {
	TowerClass.Assassin: "Assassin",
	TowerClass.Diva: "Diva",
	TowerClass.Hero: "Hero",
	TowerClass.King: "King",
	TowerClass.Marksman: "Marksman",
	TowerClass.Robotic: "Robotic",
	TowerClass.SpellCaster: "SpellCaster",
	TowerClass.Warrior: "Warrior",
}

const TOWER_GENERATION_NAMES := {
	TowerGeneration.Myth: "Myth",
	TowerGeneration.Tempus: "Tempus",
	TowerGeneration.Gen0: "Gen0",
	TowerGeneration.Gen1: "Gen1",
	TowerGeneration.Indo1: "Indo1",
}

# Multi-tier synergy requirements
const SYNERGY_REQUIREMENTS := {
	TowerClass.Assassin: [3, 4, 6],
	TowerClass.Diva: [2, 4],
	TowerClass.Hero: [3],
	TowerGeneration.Myth: [2, 3]
	# Add more as needed
}

# Buffs per tier (indexed by synergy_id and tier index)
var SYNERGY_BUFFS = {
	TowerClass.Assassin: [
		{ "atk_bonus": 5 },
		{ "atk_bonus": 10 },
		{ 
			"atk_bonus": 50,
			"atk_speed": 20
		}
	],
	TowerClass.Diva: [
		{ "aoe_radius": 1.2 },
		{ "aoe_radius": 1.5 }
	],
	TowerClass.Hero: [
		{ "regen": 5 }
	],
	TowerGeneration.Gen0: [
		{ "phys_atk_bonus_percent": 4, "magic_atk_bonus_percent": 4 },
		{ "phys_atk_bonus_percent": 6, "magic_atk_bonus_percent": 6 },
		{ "phys_atk_bonus_percent": 10, "magic_atk_bonus_percent": 10 }
	],
	TowerGeneration.Gen1: [
		{ "on_attack": Callable(self, "gen1SynergySkill").bind(20, 50) },
		{ "on_attack": Callable(self, "gen1SynergySkill").bind(60, 50) }
	],
	TowerGeneration.Indo1: [
		# No buffs or synergy data given for this group
	],
	TowerGeneration.Myth: [
		{ "on_skill_cast": Callable(self, "").bind(5) },
		{ "on_skill_cast": 7 },
		{ "on_skill_cast": 10 }
	],
	TowerGeneration.Tempus: [
		{ "mission": "Kill 500 monsters", "reward": "Tempus units +10% phys & magic attack" },
		{ "mission": "Kill 1000 monsters", "reward": "Tempus units +60% crit chance" },
		{ "mission": "Kill 2000 monsters", "reward": "All units +10% energy regen every 5s" }
	]
}

var current_counts: Dictionary = {}
var active_synergy_tiers: Dictionary = {}  # Stores highest tier reached per synergy

func _init():
	for synergy_id in SYNERGY_REQUIREMENTS.keys():
		current_counts[synergy_id] = 0
		active_synergy_tiers[synergy_id] = -1  # no tier active

func add_tower_traits(synergies: Array[int]) -> void:
	for synergy_id in synergies:
		_update_synergy(synergy_id, 1)

func remove_tower_traits(synergies: Array[int]) -> void:
	for synergy_id in synergies:
		_update_synergy(synergy_id, -1)

func _update_synergy(synergy_id: int, delta: int) -> void:
	current_counts[synergy_id] = max(0, current_counts.get(synergy_id, 0) + delta)
	_check_synergy_tiers(synergy_id)

func _check_synergy_tiers(synergy_id: int) -> void:
	var thresholds: Array = SYNERGY_REQUIREMENTS.get(synergy_id, [])
	var current: int = current_counts.get(synergy_id, 0)
	var prev_tier: int = active_synergy_tiers.get(synergy_id, -1)

	var new_tier := -1

	for i in thresholds.size():
		if current >= thresholds[i]:
			new_tier = i

	if new_tier != prev_tier:
		if new_tier > prev_tier:
			for tier in range(prev_tier + 1, new_tier + 1):
				var buff = SYNERGY_BUFFS[synergy_id][tier]
				buff["synergy_id"] = synergy_id  # Mark the buff
				synergy_activated.emit(synergy_id, tier, buff)
				print("Synergy activated:", get_synergy_name(synergy_id), "Tier", tier + 1)
		elif new_tier < prev_tier:
			for tier in range(prev_tier, new_tier, -1):
				synergy_deactivated.emit(synergy_id, tier)
				print("Synergy deactivated:", get_synergy_name(synergy_id), "Tier", tier + 1)

		active_synergy_tiers[synergy_id] = new_tier

func mythSynergyEffect(tower: Tower, regenAmount: int):
	if(tower == null):
		return;
		
	tower.regenMana(regenAmount);
	print(tower, " call regen from synergy ", regenAmount);

func gen1SynergySkill(tower: Tower, chance: float, dmgPercent: float):
	print(tower, " call metheor")

func get_synergy_name(synergy_id: int) -> String:
	return TOWER_CLASS_NAMES.get(synergy_id, TOWER_GENERATION_NAMES.get(synergy_id, "Unknown"))

signal synergy_activated(synergy_id: int, tier: int, buff: Dictionary)
signal synergy_deactivated(synergy_id: int, tier: int)
