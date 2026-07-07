class_name InvincibleBehavior
extends EffectBehavior

# Invincible: while any invincible instance remains, the enemy takes no damage
# (Enemy.recvDamage early-return via isInvincible()) and towers cannot target
# it (EnemyDetector skips it). Tower targeting is event-driven only (area
# enter/exit + target death), so BOTH edges push a re-scan on every tower:
# on_apply drops existing locks, on_expire lets towers re-acquire the freed
# enemy - without it the enemy stays untargeted until it crosses a range edge.

func on_apply(host: Node, inst: EffectInstance) -> void:
	super.on_apply(host, inst)
	if host is Enemy and is_instance_valid(host):
		_refresh_tower_targets(host)

func on_expire(host: Node, inst: EffectInstance) -> void:
	super.on_expire(host, inst)
	if not (host is Enemy) or not is_instance_valid(host):
		return
	var enemy := host as Enemy
	# Another invincible instance may still be active (overlapping sources).
	if enemy.effects != null and enemy.effects.has_kind(EffectTypes.Kind.INVINCIBLE):
		return
	_refresh_tower_targets(host)

func _refresh_tower_targets(host: Node) -> void:
	if not host.is_inside_tree():
		return
	for node in host.get_tree().get_nodes_in_group("tower"):
		var tower := node as Tower
		if tower == null or not is_instance_valid(tower):
			continue
		if tower.enemyDetector != null:
			tower.enemyDetector.updateTarget(null, null, null)
