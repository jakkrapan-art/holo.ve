class_name DotBehavior
extends EffectBehavior

# Generic tick DOT (first user: Kiara phoenix_flame). Per-tick damage:
#     dmg = (value * snapshotAttack) + (params.max_hp_percent * target.maxHp)
# where the instance `value` is the attack-percent knob.
#
# Ticks every params.interval seconds; a duration of N*interval yields exactly
# N ticks (t = interval .. duration). The tick clock advances
# `last_tick += interval` (never `= elapsed` - frame overshoot would
# accumulate and drop the final tick); the container runs behavior.process
# BEFORE the expiry check in the same tick() pass, so the last tick and expiry
# share a frame with the tick first.
#
# Caster attack is snapshotted at apply (Dota Liquid Fire convention - locked
# design): the DOT does not react to caster buffs applied after the cast, and
# never holds a live caster reference.

func capture(applier: Node, inst: EffectInstance) -> void:
	if applier is Tower and is_instance_valid(applier):
		inst.snapshot["attack"] = float((applier as Tower).data.getTotalAttack())

func process(delta: float, host: Node, inst: EffectInstance) -> void:
	var interval := float(inst.param("interval", 1.0))
	var elapsed := float(inst.snapshot.get("elapsed", 0.0)) + delta
	inst.snapshot["elapsed"] = elapsed
	var last := float(inst.snapshot.get("last_tick", 0.0))
	if elapsed - last < interval:
		return
	inst.snapshot["last_tick"] = last + interval
	if not (host is Enemy) or not is_instance_valid(host):
		return
	var enemy := host as Enemy
	if enemy.stats == null:
		return
	var snapshot_attack := float(inst.snapshot.get("attack", 0.0))
	var hp_pct := float(inst.param("max_hp_percent", 0.0))
	var dmg := int(inst.effective_value() * snapshot_attack + hp_pct * float(enemy.stats.maxHp))
	enemy.recvDamage(Damage.new(null, dmg, Damage.DamageType.MAGIC))
