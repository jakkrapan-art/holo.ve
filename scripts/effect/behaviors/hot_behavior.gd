class_name HotBehavior
extends EffectBehavior

# Heal-over-time (first user: Giant Boar rest_recovery). Per-tick heal:
#     heal = params.max_hp_percent * host.maxHp
# Ticks every params.interval seconds; a duration of N*interval yields exactly
# N ticks (t = interval .. duration). Unlike DotBehavior's `last_tick = elapsed`
# the tick clock advances `last_tick += interval`, so timing never drifts and
# the final tick still lands: the container runs behavior.process BEFORE the
# expiry check in the same tick() pass, and elapsed/remaining accumulate the
# same deltas, so the last tick and expiry share a frame with the tick first.

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
	var hp_pct := float(inst.param("max_hp_percent", 0.0))
	enemy.heal(int(hp_pct * float(enemy.stats.maxHp)))
