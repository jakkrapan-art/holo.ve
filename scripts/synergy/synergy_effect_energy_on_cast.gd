class_name SynergyEffectEnergyOnCast
extends SynergyEffect

# Myth: when ANY unit holding this synergy casts a skill, ALL units holding it
# restore Energy (team battery). Reads the current tier live each cast, so a
# higher tier simply REPLACES the value (no stacking).

func on_tower_cast(tower) -> void:
	if tower == null or tower.data == null:
		return
	# React only to a caster that holds this synergy's trait.
	if tower.data.towerClass != data.synergy_id and tower.data.generation != data.synergy_id:
		return

	var tier: int = controller.active_tier(data.synergy_id)
	if tier < 0:
		return

	var amount = data.get_parameter("energy_return", tier)
	if amount == null:
		return

	for t in controller.towers_with(data.synergy_id):
		if is_instance_valid(t):
			t.regenMana(int(amount))   # regenMana already gates on enableRegenMana / isMoving
