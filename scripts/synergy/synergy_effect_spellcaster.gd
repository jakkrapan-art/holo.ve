class_name SynergyEffectSpellcaster
extends SynergyEffect

# SpellCaster - the first synergy that grants an ABILITY, not only a number:
# holders get +magic_bonus% Magic Attack AND their skills are allowed to roll
# critical hits. It deliberately grants NO critical chance (Director 2026-07-19),
# so a holder sitting at 0 chance still never crits; the gate only stops being
# the limiting factor. Do not "fix" this by adding crit_chance_up.
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
	if bonus == null:
		return
	for tower in controller.towers_with(data.synergy_id):
		if not is_instance_valid(tower):
			continue
		_apply(tower, "magic_mult_up", float(bonus))
		_apply(tower, "spellcaster_crit", 1.0)

# Lifetime and duration are set explicitly: a registry def is WAVE with a
# non-zero duration by default, both wrong for a permanent synergy buff (same
# trap as synergy_effect_attack_per_trait.gd / synergy_effect_mission_tempus.gd).
func _apply(tower, effect_id: String, value: float) -> void:
	var inst := EffectUtility.make_instance(effect_id, _SOURCE, value, 0.0)
	if inst == null:
		return
	inst.lifetime = EffectTypes.Lifetime.BOARD
	tower.apply_effect(inst)
