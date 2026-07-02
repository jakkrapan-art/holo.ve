class_name DotBehavior
extends EffectBehavior

# Generic tick DOT (first user: Kiara phoenix_flame). Per-tick damage:
#     dmg = (value * snapshotAttack) + (params.max_hp_percent * target.maxHp)
# where the instance `value` is the attack-percent knob.
#
# Caster attack is snapshotted at apply (Dota Liquid Fire convention - locked
# design): the DOT does not react to caster buffs applied after the cast, and
# never holds a live caster reference.

func capture(applier: Node, inst: EffectInstance) -> void:
	if applier is Tower and is_instance_valid(applier):
		inst.snapshot["attack"] = float((applier as Tower).data.getTotalAttack())

func process(delta: float, host: Node, inst: EffectInstance) -> void:
	var interval := float(inst.def.params.get("interval", 1.0))
	var elapsed := float(inst.snapshot.get("elapsed", 0.0)) + delta
	inst.snapshot["elapsed"] = elapsed
	var last := float(inst.snapshot.get("last_tick", 0.0))
	if elapsed - last < interval:
		return
	inst.snapshot["last_tick"] = elapsed
	if not (host is Enemy) or not is_instance_valid(host):
		return
	var enemy := host as Enemy
	if enemy.stats == null:
		return
	var snapshot_attack := float(inst.snapshot.get("attack", 0.0))
	var hp_pct := float(inst.def.params.get("max_hp_percent", 0.0))
	var dmg := int(inst.effective_value() * snapshot_attack + hp_pct * float(enemy.stats.maxHp))
	enemy.recvDamage(Damage.new(null, dmg, Damage.DamageType.MAGIC))
