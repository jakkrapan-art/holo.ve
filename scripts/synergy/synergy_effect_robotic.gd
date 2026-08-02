class_name SynergyEffectRobotic
extends SynergyEffect

# Robotic: whenever a holder casts a skill, the CASTER gains +atk_per_cast%
# Attack - both halves (attack_mult + magic_mult) under one source_id, so the
# bonus lands for any attackType. Each cast re-applies the same key pair and
# the registry stack rule increments stacks (effective value = value * stacks).
#
# Lifetime stays the registry WAVE default on purpose: the buff is earned per
# wave and must clear at wave end - the opposite of the permanent BOARD
# synergy buffs (Warrior/Assassin).

const _SOURCE := "synergy_robotic"

func on_tower_cast(tower) -> void:
	if tower == null or tower.data == null:
		return
	# Robotic is a class trait; only a caster holding it earns the stack.
	if tower.data.towerClass != data.synergy_id:
		return
	if controller.active_tier(data.synergy_id) < 0:
		return

	var atk_per_cast = data.get_parameter("atk_per_cast", 0)
	if atk_per_cast == null:
		return

	_apply(tower, "robotic_overdrive", float(atk_per_cast), true)
	_apply(tower, "robotic_overdrive_magic", float(atk_per_cast), false)

func _apply(tower, effect_id: String, value: float, visible: bool) -> void:
	var inst := EffectUtility.make_instance(effect_id, _SOURCE, value, 0.0)
	if inst == null:
		return
	# make_instance hides "synergy_" sources (static board buffs live in the
	# synergy panel). This buff is EARNED per cast, so the player must see it
	# on the unit: the weapon-half icon shows; the magic twin stays hidden.
	if visible:
		inst.show_icon = true
	tower.apply_effect(inst)
