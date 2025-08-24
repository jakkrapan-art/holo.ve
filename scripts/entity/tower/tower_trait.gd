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
	TowerClass.Diva: [2, 3],
	TowerClass.Hero: [3],
	TowerGeneration.Myth: [2, 3],
	TowerGeneration.Gen1: [2, 4],
	TowerGeneration.Tempus: [2, 4, 6]
	# Add more as needed
}

# Buffs per tier (indexed by synergy_id and tier index)
var SYNERGY_BUFFS = {
	TowerClass.Assassin: [
		{
			"crit_chance_bonus_percent": 5,
			"on_critical": Callable(self, "onAssassinCritHit")
		},
		{
			"crit_chance_bonus_percent": 10
		},
	],
	TowerClass.Diva: [
		{
			"interval_action":
			{
				"interval": 5,
				"action": "regen_mana",
				"value": 5,
				"bonus":
					{
						"condition": Callable(self, "checkBonusDivaSynergy"),
						"value": 10
					}
			}
		},
		{
			"interval_action":
			{
				"interval": 5,
				"action": "regen_mana",
				"value": 10,
				"bonus":
					{
						"condition": Callable(self, "checkBonusDivaSynergy"),
						"value": 20
					}
			}
		}
	],
	TowerClass.Hero: [
		{
			# "aura": Callable(self, "heroSynergyEffect")
		},
	],
	TowerClass.Marksman: [
		{}
	],
	TowerGeneration.Gen0: [
		{ "syn_attack_percent": 4 },
		{ "syn_attack_percent": 6 },
		{ "syn_attack_percent": 10 }
	],
	TowerGeneration.Gen1: [
		{
			"on_attack": Callable(self, "starGen1SynergySkill").bind(20, 50)
		},
		{
			"on_attack": Callable(self, "starGen1SynergySkill").bind(60, 50)
		}
	],
	TowerGeneration.Indo1: [
		# No buffs or synergy data given for this group
	],
	TowerGeneration.Myth: [
		{ "on_skill_cast": Callable(self, "mythSynergyEffect").bind(5) },
		{ "on_skill_cast": Callable(self, "mythSynergyEffect").bind(7) },
		{ "on_skill_cast": Callable(self, "mythSynergyEffect").bind(10) }
	],
	TowerGeneration.Tempus: [
		{ "mission": MissionDetail.new(0, str(TowerGeneration.Tempus) + "kill_enemy", 0, 500, "Kill 500 monsters", Callable(self, "activeTempusSynergyTier1"))},
		{ "mission": MissionDetail.new(1, str(TowerGeneration.Tempus) + "kill_enemy", 0, 1000, "Kill 1000 monsters", Callable(self, "activeTempusSynergyTier2"))},
		{ "mission": MissionDetail.new(2, str(TowerGeneration.Tempus) + "kill_enemy", 0, 2000, "Kill 2000 monsters", Callable(self, "activeTempusSynergyTier3"))},
	],
}

var current_counts: Dictionary = {}
var active_synergy_tiers: Dictionary = {}  # Stores highest tier reached per synergy
var starGen1Damage: int = 0;

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
				buff["tier"] = tier;
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

func setStarGen1Damage(damage: int):
	starGen1Damage = damage;

func starGen1SynergySkill(tower: Tower, chance: float, dmgPercent: float):
	if(tower == null || tower.enemy == null):
		return;

	var rand = randi_range(0, 100);
	if(rand > chance):
		return;

	var metheor = Metheor.new(Damage.new(tower, starGen1Damage * (dmgPercent / 100), Damage.DamageType.MAGIC), tower.enemy.position, 0.5);
	tower.add_sibling(metheor);

func activeTempusSynergyTier1(missionId: int):
	print("active tempus synergy tier 1");
	var buff := {
		"attack_bonus_percent": 10,
		"synergy_id": TowerGeneration.Tempus,
		"tier": 0
	}

	mission_completed.emit(missionId, buff);

func activeTempusSynergyTier2(missionId: int):
	print("active tempus synergy tier 2");
	var buff := {
		"attack_bonus_percent": 10,
		"synergy_id": TowerGeneration.Tempus,
		"tier": 1
	}

	mission_completed.emit(missionId, buff);

func activeTempusSynergyTier3(missionId: int):
	print("active tempus synergy tier 3");
	var buff := {
		"attack_bonus_percent": 10,
		"synergy_id": [
			TowerGeneration.Myth,
			TowerGeneration.Tempus,
			TowerGeneration.Gen0,
			TowerGeneration.Gen1,
			TowerGeneration.Indo1
		],
		"tier": 2
	}

	mission_completed.emit(missionId, buff);

func checkBonusDivaSynergy(synergy_id):
	return synergy_id == TowerClass.Diva

func get_synergy_name(synergy_id: int) -> String:
	return TOWER_CLASS_NAMES.get(synergy_id, TOWER_GENERATION_NAMES.get(synergy_id, "Unknown"))

signal synergy_activated(synergy_id: int, tier: int, buff: Dictionary)
signal synergy_deactivated(synergy_id: int, tier: int)
signal mission_completed(mission_id: int, buff: Dictionary);
