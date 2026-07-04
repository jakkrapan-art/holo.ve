class_name StunBehavior
extends EffectBehavior

# Stun: freeze enemy movement while any stun instance remains. Release checks
# the container instead of per-instance state, so overlapping stuns from two
# sources release only when the LAST one ends (the legacy per-frame re-disable
# had a last-writer-wins release).

func on_apply(host: Node, inst: EffectInstance) -> void:
	super.on_apply(host, inst)
	if host is Enemy and is_instance_valid(host):
		(host as Enemy).enableMove = false

func on_expire(host: Node, inst: EffectInstance) -> void:
	super.on_expire(host, inst)
	if not (host is Enemy) or not is_instance_valid(host):
		return
	var enemy := host as Enemy
	if enemy.effects != null and enemy.effects.has_kind(EffectTypes.Kind.STUN):
		return
	enemy.enableMove = true
