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
	TowerClass.SpellCaster: "Spell Caster",
	TowerClass.Warrior: "Warrior",
}

const TOWER_GENERATION_NAMES := {
	TowerGeneration.Myth: "Myth",
	TowerGeneration.Tempus: "Tempus",
	TowerGeneration.Gen0: "Gen0",
	TowerGeneration.Gen1: "Gen1",
	TowerGeneration.Indo1: "Indo1",
}

# Match key for a trait display name. Display names are player-facing and may
# carry spaces or underscores ("Spell Caster"); every identity comparison - YAML
# id resolution, icon filenames - runs through here so a copy rename never
# breaks a lookup. Renaming a display name must NOT change this key.
static func name_key(display_name: String) -> String:
	return display_name.to_lower().replace(" ", "").replace("_", "")

# Trait counts on the field, keyed by synergy id (TowerClass / TowerGeneration int).
var current_counts: Dictionary = {}

# Emitted on every count change with the current count + current tier (-1 = none).
# Single source feeding both the Synergy UI and SynergyController.
signal synergy_updated(synergy_id: int, count: int, tier: int)

func add_tower_traits(synergies: Array[int]) -> void:
	for synergy_id in synergies:
		_update_synergy(synergy_id, 1)

func remove_tower_traits(synergies: Array[int]) -> void:
	for synergy_id in synergies:
		_update_synergy(synergy_id, -1)

func _update_synergy(synergy_id: int, delta: int) -> void:
	if synergy_id <= 0:   # skip default/unset trait values
		return
	var count: int = max(0, current_counts.get(synergy_id, 0) + delta)
	current_counts[synergy_id] = count
	var tier := _tier_for(synergy_id, count)
	synergy_updated.emit(synergy_id, count, tier)

# Highest tier index whose threshold is met (-1 = none). Thresholds come from the
# synergy YAML (ResourceManager), not a hardcoded table.
func _tier_for(synergy_id: int, count: int) -> int:
	var data: SynergyData = ResourceManager.getSynergyData(synergy_id)
	if data == null:
		return -1
	var tier := -1
	for i in data.thresholds.size():
		if count >= int(data.thresholds[i]):
			tier = i
	return tier
