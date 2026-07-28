class_name SynergyEffectWarrior
extends SynergyEffect

# Warrior: holders gain +atk_bonus% Weapon Attack (attack_mult bucket) AND their
# Basic Attacks deal +melee_amp% damage to targets within 1 cell. The melee
# bonus is a RATE (damage_amp_melee kind): TowerData.getMeleeAmp converts it
# into a per-attack amp at the normal-attack build site, so skills never get it.
#
# Two effects share one source_id: EffectInstance.key() is source_id + "/" + id,
# so the keys stay distinct. Both are REFRESH, so the per-placement re-apply
# overwrites instead of stacking.

const _SOURCE := "synergy_warrior"

func activate() -> void:
	_apply_all()

# Fires for every placement. A Warrior placed after the trait activates must
# still receive both effects, and re-applying to existing holders is idempotent.
func on_tower_added(_tower) -> void:
	_apply_all()

func _apply_all() -> void:
	var atk_bonus = data.get_parameter("atk_bonus", 0)
	var melee_amp = data.get_parameter("melee_amp", 0)
	if atk_bonus == null or melee_amp == null:
		return
	for tower in controller.towers_with(data.synergy_id):
		if not is_instance_valid(tower):
			continue
		_apply(tower, "attack_mult_up", float(atk_bonus))
		_apply(tower, "warrior_melee_amp", float(melee_amp))

# Lifetime and duration are set explicitly: registry defs default to WAVE
# lifetime, wrong for a permanent synergy buff (same trap as
# synergy_effect_assassin.gd).
func _apply(tower, effect_id: String, value: float) -> void:
	var inst := EffectUtility.make_instance(effect_id, _SOURCE, value, 0.0)
	if inst == null:
		return
	inst.lifetime = EffectTypes.Lifetime.BOARD
	tower.apply_effect(inst)
