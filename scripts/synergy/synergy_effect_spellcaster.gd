class_name SynergyEffectSpellcaster
extends SynergyEffect

# SpellCaster (redesigned 2026-07-22): holders get +magic_bonus% Magic Attack
# AND +energy_amp% Energy from every intake (the ENERGY_AMP multiplier at
# SkillController.updateMana). The old skill-crit gate moved off this synergy -
# its mark lives on as the dormant `skill_crit_unlock`, reserved for a future
# synergy (e.g. Assassin).
#
# Two effects share one source_id: EffectInstance.key() is source_id + "/" + id,
# so the keys stay distinct. Both are REFRESH, so the per-placement re-apply
# overwrites instead of stacking.

const _SOURCE := "synergy_spellcaster"

func activate() -> void:
	_apply_all()

# Fires for every placement. A SpellCaster placed after the trait activates must
# still receive both effects, and re-applying to existing holders is idempotent.
func on_tower_added(_tower) -> void:
	_apply_all()

func _apply_all() -> void:
	var bonus = data.get_parameter("magic_bonus", 0)
	var energy_amp = data.get_parameter("energy_amp", 0)
	if bonus == null or energy_amp == null:
		return
	for tower in controller.towers_with(data.synergy_id):
		if not is_instance_valid(tower):
			continue
		_apply(tower, "magic_mult_up", float(bonus))
		_apply(tower, "energy_amp_up", float(energy_amp))

# Lifetime and duration are set explicitly: a registry def is WAVE with a
# non-zero duration by default, both wrong for a permanent synergy buff (same
# trap as synergy_effect_attack_per_trait.gd / synergy_effect_mission_tempus.gd).
func _apply(tower, effect_id: String, value: float) -> void:
	var inst := EffectUtility.make_instance(effect_id, _SOURCE, value, 0.0)
	if inst == null:
		return
	inst.lifetime = EffectTypes.Lifetime.BOARD
	tower.apply_effect(inst)
