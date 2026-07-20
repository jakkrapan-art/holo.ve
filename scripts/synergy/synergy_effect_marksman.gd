class_name SynergyEffectMarksman
extends SynergyEffect

# Marksman - the first synergy whose bonus depends on the TARGET, not on the
# board: holders deal amp_per_cell% extra damage per cell between them and what
# they are shooting.
#
# It cannot be a plain stat buff. EffectContainer.aggregate() is one flat number
# per tower with no target context, so what this effect grants is the RATE
# (percent per cell); TowerData.getDistanceAmp turns that rate into a real
# amplifier at each attack, and Enemy.recvDamage sums it into ΣAmp. That keeps
# the bonus in the amplifier position of the Master Formula, so TRUE damage
# still bypasses it.
#
# Distance is measured at fire time and rounded to the nearest whole cell
# (Director 2026-07-20).

const _SOURCE := "synergy_marksman"

func activate() -> void:
	_apply_all()

# Fires for every placement: a Marksman placed after the trait activates must
# still be tagged, and re-applying to existing holders is idempotent (REFRESH).
func on_tower_added(_tower) -> void:
	_apply_all()

func _apply_all() -> void:
	var per_cell = data.get_parameter("amp_per_cell", 0)
	if per_cell == null:
		return
	for tower in controller.towers_with(data.synergy_id):
		if not is_instance_valid(tower):
			continue
		_apply(tower, "marksman_range", float(per_cell))

# Lifetime and duration are set explicitly: a registry def is WAVE with a
# non-zero duration by default, both wrong for a permanent synergy buff (same
# trap as synergy_effect_spellcaster.gd / synergy_effect_attack_per_trait.gd).
func _apply(tower, effect_id: String, value: float) -> void:
	var inst := EffectUtility.make_instance(effect_id, _SOURCE, value, 0.0)
	if inst == null:
		return
	inst.lifetime = EffectTypes.Lifetime.BOARD
	tower.apply_effect(inst)
