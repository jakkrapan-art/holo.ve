class_name SynergyEffectAssassin
extends SynergyEffect

# Assassin: holders' skills can crit (the `skill_crit_unlock` mark, read live by
# the skill attack/projectile actions) AND holders gain +crit_chance% critical
# chance and +crit_damage critical damage. The stat bonuses aggregate unit-wide,
# so basic attacks benefit too; the mark only unlocks the roll on skills.
#
# Three effects share one source_id: EffectInstance.key() is source_id + "/" + id,
# so the keys stay distinct. All are REFRESH, so the per-placement re-apply
# overwrites instead of stacking.

const _SOURCE := "synergy_assassin"

func activate() -> void:
	_apply_all()

# Fires for every placement. An Assassin placed after the trait activates must
# still receive all three effects, and re-applying to existing holders is
# idempotent.
func on_tower_added(_tower) -> void:
	_apply_all()

func _apply_all() -> void:
	var crit_chance = data.get_parameter("crit_chance", 0)
	var crit_damage = data.get_parameter("crit_damage", 0)
	if crit_chance == null or crit_damage == null:
		return
	for tower in controller.towers_with(data.synergy_id):
		if not is_instance_valid(tower):
			continue
		_apply(tower, "skill_crit_unlock", 1.0)
		_apply(tower, "crit_chance_up", float(crit_chance))
		_apply(tower, "crit_damage_up", float(crit_damage))

# Lifetime and duration are set explicitly: the crit_chance_up / crit_damage_up
# registry defs are WAVE with a non-zero duration by default, both wrong for a
# permanent synergy buff (same trap as synergy_effect_spellcaster.gd).
func _apply(tower, effect_id: String, value: float) -> void:
	var inst := EffectUtility.make_instance(effect_id, _SOURCE, value, 0.0)
	if inst == null:
		return
	inst.lifetime = EffectTypes.Lifetime.BOARD
	tower.apply_effect(inst)
